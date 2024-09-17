  import 'package:chat_app/models/chat.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user_profile.dart';
import 'package:chat_app/service/storage_service.dart';
import 'package:chat_app/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'auth_service.dart';

class DatabaseService {
  late final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late StorageService _storageService;

  DatabaseService() {
    _authService = _getIt.get<AuthService>();
    _storageService = _getIt.get<StorageService>();
    _setupCollectionsReferences();
  }

  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  CollectionReference? _userCollection;
  CollectionReference? _chatsCollection;

  void _setupCollectionsReferences() {
    _userCollection = _firebaseFirestore
        .collection('users')
        .withConverter<UserProfile>(
            fromFirestore: (snapShots, _) =>
                UserProfile.fromJson(snapShots.data()!),
            toFirestore: (userProfile, _) => userProfile.toJson());

    _chatsCollection = _firebaseFirestore
        .collection('chats')
        .withConverter<Chat>(
            fromFirestore: (snapShots, _) => Chat.fromJson(snapShots.data()!),
            toFirestore: (chat, _) => chat.toJson());
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async {
    try {
      if (_userCollection == null) {
        throw Exception('User collection is not initialized.');
      }
      await _userCollection!.doc(userProfile.uid).set(
          userProfile); // Assuming userProfile.toMap() converts the object to a map
      if (kDebugMode) {
        print('User profile created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user profile: $e');
      }
    }
  }

  Stream<QuerySnapshot<UserProfile>> getUserProfiles() {
    return _userCollection
        ?.where("uid", isNotEqualTo: _authService.user!.uid)
        .snapshots() as Stream<QuerySnapshot<UserProfile>>;
  }

  Future<bool> checkChatExists(String uid1, String uid2) async {
    try {
      String chatID = generateChatID(uid1: uid1, uid2: uid2);
      final result = await _chatsCollection?.doc(chatID).get();
      if (result != null) {
        return result.exists;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return false;
  }

  Future<void> createNewChat(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatsCollection?.doc(chatID);
    final chat = Chat(id: chatID, participants: [uid1, uid2], messages: []);
    await docRef?.set(chat);
  }

  Future<void> sendChatMessage(
      String uid1, String uid2, Message message) async {
    try {
      String chatID = generateChatID(uid1: uid1, uid2: uid2);
      final docRef = _chatsCollection!.doc(chatID);
      await docRef.update({
        "messages": FieldValue.arrayUnion([
          message.toJson(),
        ])
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Stream<DocumentSnapshot<Chat>> getChatData(String uid1, String uid2) {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    return _chatsCollection?.doc(chatID).snapshots()
        as Stream<DocumentSnapshot<Chat>>;
  }

  Future<bool> deleteConversation(String uid1, String uid2) async {
    try {
      String chatID = generateChatID(uid1: uid1, uid2: uid2);
      final docRef = _chatsCollection?.doc(chatID);
      await docRef?.delete();
      await _storageService.deleteChatImages(chatID);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Failed to clear the conversation");
      }
    }
    return false;
  }
}
