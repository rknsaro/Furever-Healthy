// lib/identify_breed_picker_web.dart
// This file is only used when building for the web (dart.library.html available).
// It uses dart:html to pick a file and read bytes.

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

/// Data returned by the picker: bytes + filename.
class PickedFileData {
  final Uint8List bytes;
  final String name;
  PickedFileData(this.bytes, this.name);
}

/// Show a hidden file input to pick a single image and return the bytes.
Future<PickedFileData?> pickImageBytes() {
  final completer = Completer<PickedFileData?>();
  final input = html.FileUploadInputElement()..accept = '.png,.jpg,.jpeg'..multiple = false;

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();

    reader.onError.listen((event) {
      completer.completeError('Failed to read file');
    });

    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is! ByteBuffer) {
        // Sometimes result might be a String or other type; try to convert.
        final asBytes = (result as List<int>?)?.toUint8List();
        if (asBytes != null) {
          completer.complete(PickedFileData(asBytes, file.name));
          input.remove();
          return;
        }
        completer.completeError('Unsupported file read result type');
        input.remove();
        return;
      }
      final bytes = (result as ByteBuffer).asUint8List();
      completer.complete(PickedFileData(bytes, file.name));
      input.remove();
    });

    reader.readAsArrayBuffer(file);
  });

  // Trigger click
  input.click();

  return completer.future;
}

// Small helper to convert List<int> to Uint8List (if needed)
extension _ListIntToUint8 on List<int> {
  Uint8List toUint8List() => Uint8List.fromList(this);
}
