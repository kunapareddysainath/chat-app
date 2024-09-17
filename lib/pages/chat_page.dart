import 'package:chat_app/models/user_profile.dart';
import 'package:chat_app/service/media_service.dart';
import 'package:chat_app/service/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../service/alert_service.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../utils.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

final key = encrypt.Key.fromBase64('MDEyMzQ1Njc4OWFiY2RlZg==');
final iv = encrypt.IV.fromBase64('Instance_of_IV_1');

final encrypter = encrypt.Encrypter(encrypt.AES(key));

class ChatPage extends StatefulWidget {
  final UserProfile chatUser;

  const ChatPage({super.key, required this.chatUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GetIt _getIt = GetIt.instance;

  late AuthService _authService;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  late StorageService _storageService;
  late AlertService _alertService;

  ChatUser? currentUser, otherUser;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _alertService = _getIt.get<AlertService>();
    currentUser = ChatUser(
        id: _authService.user!.uid, firstName: _authService.user!.displayName);
    otherUser = ChatUser(
        id: widget.chatUser.uid!,
        firstName: widget.chatUser.name,
        profileImage: widget.chatUser.profileUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title:
            Text(widget.chatUser.name!, style: const TextStyle(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) async {
              switch (value) {
                case 'Clear Chat History':
                  setState(() {
                    isLoading = true;
                  });
                  bool result = await _databaseService.deleteConversation(
                      currentUser!.id, otherUser!.id);
                  if (result) {
                    setState(() {
                      isLoading = false;
                    });
                    _alertService.showToast(
                      text: "Successfully cleared chat",
                      icon: Icons.check,
                    );
                  }
                  break;
                default:
                  // Handle unknown selections or do nothing
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'Clear Chat History',
                child: ListTile(
                  leading: Icon(Icons.clear_all_rounded),
                  title: Text('Clear Chat History',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildUI(),
    );
  }

  Widget _buildUI() {
    return StreamBuilder<DocumentSnapshot<Chat>>(
        stream: _databaseService.getChatData(currentUser!.id, otherUser!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          Chat? chat = snapshot.data?.data();
          List<ChatMessage> messages = [];
          if (chat != null && chat.messages != null) {
            messages = _generateChatMessagesList(chat.messages!);
          }

          return DashChat(
              typingUsers: const [],
              messageOptions: const MessageOptions(
                currentUserContainerColor: Colors.blue,
                showOtherUsersAvatar: true,
                showTime: true,
              ),
              inputOptions: InputOptions(
                alwaysShowSend: false,
                trailing: [_mediaMessageButton()],
                cursorStyle: const CursorStyle(color: Colors.blue),
              ),
              currentUser: currentUser!,
              onSend: _sendMessage,
              messages: messages);
        });
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    if (chatMessage.medias?.isNotEmpty ?? false) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        String encryptedUrl = encryptContent(chatMessage.medias!.first.url);
        Message message = Message(
          senderID: chatMessage.user.id,
          content: encryptedUrl,
          messageType: MessageType.Image,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
        );

        await _databaseService.sendChatMessage(
            currentUser!.id, otherUser!.id, message);
      }
    } else {
      String encryptedText = encryptContent(chatMessage.text);
      Message message = Message(
          senderID: currentUser!.id,
          content: encryptedText,
          messageType: MessageType.Text,
          sentAt: Timestamp.fromDate(chatMessage.createdAt));

      await _databaseService.sendChatMessage(
          currentUser!.id, otherUser!.id, message);
    }
  }

  List<ChatMessage> _generateChatMessagesList(List<Message> messages) {
    List<ChatMessage> chatMessages = messages.map((m) {
      String decryptedContent = decryptContent(m.content!);

      if (m.messageType == MessageType.Image) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: m.sentAt!.toDate(),
          medias: [
            ChatMedia(
                url: decryptedContent, fileName: "", type: MediaType.image)
          ],
        );
      } else {
        return ChatMessage(
            user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
            text: decryptedContent,
            createdAt: m.sentAt!.toDate());
      }
    }).toList();

    chatMessages.sort((a, b) {
      return b.createdAt.compareTo(a.createdAt);
    });

    return chatMessages;
  }

  Widget _mediaMessageButton() {
    return IconButton(
        onPressed: () async {
          var file = await _mediaService.getImageFromGallery();
          if (file != null) {
            String chatID =
                generateChatID(uid1: currentUser!.id, uid2: otherUser!.id);
            String? downloadURL = await _storageService.uploadImageToChat(
                file: file, chatID: chatID);
            if (downloadURL != null) {
              ChatMessage chatMessage = ChatMessage(
                user: currentUser!,
                createdAt: DateTime.now(),
                medias: [
                  ChatMedia(
                      url: downloadURL, fileName: "", type: MediaType.image)
                ],
              );
              _sendMessage(chatMessage);
            }
          }
        },
        icon: Icon(
          Icons.image,
          color: Theme.of(context).colorScheme.primary,
        ));
  }

  String encryptContent(String content) {
    try {
      final encrypted = encrypter.encrypt(content, iv: iv);
      if (kDebugMode) {
        print("Encrypted content: ${encrypted.base64}");
      } // Log encrypted content
      return encrypted.base64; // Convert to base64 string for Firebase storage
    } catch (e) {
      if (kDebugMode) {
        print("Encryption error: $e");
      }
      return "";
    }
  }

  String decryptContent(String encryptedContent) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedContent);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      if (kDebugMode) {
        print("Decryption error: $e");
      }
      return "";
    }
  }
}
