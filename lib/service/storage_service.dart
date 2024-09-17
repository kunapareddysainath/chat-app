import 'dart:io' as io;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  StorageService();

  Future<String?> uploadUserPfps({
    required dynamic file, // Can be io.File or Uint8List
    required String uid,
  }) async {
    try {
      // Determine the file extension based on the file type
      String fileExtension;
      if (kIsWeb) {
        // For web, file is in Uint8List format; filename and extension should be passed explicitly if possible
        fileExtension = '.png'; // Default extension; adapt as necessary
      } else {
        // For mobile, file is io.File
        fileExtension = path.extension((file as io.File).path);
      }

      // Create a reference to the file location in Firebase Storage
      Reference fileRef =
          _firebaseStorage.ref('users/pfps').child('$uid$fileExtension');

      // Upload the file to Firebase Storage
      UploadTask task;
      if (kIsWeb) {
        // For web, use the Uint8List data to upload
        task = fileRef.putData(file as Uint8List);
      } else {
        // For mobile, use the File object to upload
        task = fileRef.putFile(file as io.File);
      }

      // Await the upload task and return the download URL
      final snapshot = await task;
      if (snapshot.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading user profile picture: $e');
      }
      return null;
    }
  }

  Future<String?> uploadImageToChat(
      {required dynamic file, required String chatID}) async {
    try {
      final fileExtension = kIsWeb
          ? '.png' // Default extension; adapt as necessary
          : path.extension((file as io.File).path);

      // Create a reference to the file location in Firebase Storage
      Reference fileRef = _firebaseStorage
          .ref('chats/$chatID')
          .child('${DateTime.now().toIso8601String()}$fileExtension');

      // Upload the file to Firebase Storage
      UploadTask task;
      if (kIsWeb) {
        // For web, use the Uint8List data to upload
        task = fileRef.putData(file as Uint8List);
      } else {
        // For mobile, use the File object to upload
        task = fileRef.putFile(file as io.File);
      }

      // Await the upload task and return the download URL
      final snapshot = await task;
      if (snapshot.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image to chat: $e');
      }
      return null;
    }
  }

  Future<void> deleteChatImages(String chatID) async {
    try {
      // Create a reference to the folder in Firebase Storage
      final folderRef = _firebaseStorage.ref('chats/$chatID');

      // List all items in the folder
      final listResult = await folderRef.listAll();

      // Delete each file in the folder
      for (var item in listResult.items) {
        await item.delete();
      }
      if (kDebugMode) {
        print('All files in the chat folder have been deleted.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting files in chat folder: $e');
      }
    }
  }
}
