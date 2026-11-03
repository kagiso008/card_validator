import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

bool get isSupported => Platform.isAndroid || Platform.isIOS;

// Reads the text from the image, then deletes the photo.
Future<String> recognizeText(String path) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    return result.text;
  } finally {
    await recognizer.close();
    await _deleteIfAppPrivate(path);
  }
}

// Only delete the app's own copy, never the user's gallery photo.
Future<void> _deleteIfAppPrivate(String path) async {
  final private = Platform.isIOS
      ? path.contains('/Containers/Data/Application/')
      : path.startsWith('/data/user/') || path.startsWith('/data/data/');
  if (!private) return;
  try {
    await File(path).delete();
  } on FileSystemException {
    // already deleted
  }
}
