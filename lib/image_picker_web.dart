import 'dart:convert';
import 'package:universal_html/html.dart';
import 'dart:async';

Future<String?> pickImages() async {
  final input = FileUploadInputElement()
    ..accept = 'image/*'
    ..style.display = 'none';

  document.body!.append(input);

  final completer = Completer<List<int>>();
  input.onChange.listen((e) {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      final reader = FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        completer.complete(reader.result as List<int>);
      });
    } else {
      completer.completeError('No files selected');
    }
  });

  input.click();

  try {
    final result = await completer.future;
    return base64Encode(result);
  } catch (e) {
    print('Error: $e');
    return null;
  } finally {
    input.remove();
  }
}
