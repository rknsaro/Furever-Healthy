// lib/identify_breed_picker_io.dart
// This file is used for non-web platforms (android/ios/desktop).
// It uses package:file_picker to get file bytes.

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Data returned by the picker: bytes + filename.
class PickedFileData {
  final Uint8List bytes;
  final String name;
  PickedFileData(this.bytes, this.name);
}

/// Pick an image and return bytes + filename. Returns null when cancelled.
Future<PickedFileData?> pickImageBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png'],
    withData: true, // request bytes so we can use Image.memory
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null) return null;
  return PickedFileData(bytes, file.name);
}
