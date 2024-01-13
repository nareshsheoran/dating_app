import 'dart:io';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';

Future<String?> pickImage() async {
  final typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png']);
  final file = await openFile(acceptedTypeGroups: [typeGroup]);
  if (file != null) {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }
  return null;
}
