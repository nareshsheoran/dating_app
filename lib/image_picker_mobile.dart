import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

Future<String?> pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.getImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    final file = File(pickedFile.path);
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }
  return null;
}
