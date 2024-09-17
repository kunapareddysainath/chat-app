import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class MediaService {
  final ImagePicker _imagePicker = ImagePicker();

  MediaService();

  Future<dynamic> getImageFromGallery() async {
    if (kIsWeb) {
      // Web-specific code
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null) {
        return result.files.single.bytes; // Return bytes for web
      }
      return null;
    } else {
      // Mobile-specific code
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (file != null) {
        return io.File(file.path); // Return io.File for mobile
      }
      return null;
    }
  }
}
