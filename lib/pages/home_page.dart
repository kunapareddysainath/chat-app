import 'package:chat_app/models/user_profile.dart';
import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/service/database_service.dart';
import 'package:chat_app/service/navigation_service.dart';
import 'package:chat_app/service/auth_service.dart';
import 'package:chat_app/widgets/chat_tile.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../service/alert_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GetIt _getIt = GetIt.instance;

  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late DatabaseService _databaseService;

// Moved outside the method

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Chat-app Messages",
            style: TextStyle(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) async {
              switch (value) {
                case 'logout':
                  bool result = await _authService.logout();
                  if (result) {
                    _alertService.showToast(
                      text: "Successfully logged out!",
                      icon: Icons.check,
                    );
                    _navigationService.pushReplacementNamed("/login");
                  }
                  break;
                case 'profile':
                  _navigationService.pushNamed("/profile");
                  break;
                default:
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
             const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
          child: Column(
            children: [
              TextField(
                onChanged: (text) {
                  setState(() {
                  });
                },
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Search"),
              ),
             Expanded(child: _chatsList()), // Use Expanded to ensure the ListView takes available space
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatsList() {
    return StreamBuilder(
        stream: _databaseService.getUserProfiles(),
        builder: (context, snapshots) {
          if (snapshots.hasError) {
            return const Center(
              child: Text("Unable to load data"),
            );
          }

   if (snapshots.hasData && snapshots.data != null) {
            final users = snapshots.data!.docs;

            return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  UserProfile user = users[index].data();
                  return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: ChatTile(
                          userProfile: user,
                          onTap: () async {
                            final chatExists =
                                await _databaseService.checkChatExists(
                                    _authService.user!.uid, user.uid!);
                            if (!chatExists) {
                              await _databaseService.createNewChat(
                                  _authService.user!.uid, user.uid!);
                            }
                            _navigationService
                                .push(MaterialPageRoute(builder: (context) {
                              return ChatPage(chatUser: user);
                            }));
                          }),
                      );
                });
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}
