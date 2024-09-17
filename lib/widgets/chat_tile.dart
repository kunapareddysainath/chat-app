import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ChatTile extends StatelessWidget {
  final UserProfile userProfile;
  final Function onTap;

  // Constructor without `const` keyword
  const ChatTile({super.key, required this.userProfile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onTap();
      },
      dense: false,
      leading: CircleAvatar(
        backgroundImage: userProfile.profileUrl != null
            ? NetworkImage(userProfile.profileUrl!)
            : null, // Fallback if profileUrl is null
        child: userProfile.profileUrl != null
            ? null
            : const Icon(Icons.account_circle), // Placeholder icon if no image
      ),
      title: Text(userProfile.name!),
    );
  }
}
