import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:file_selector/file_selector.dart';
import 'package:flame_finder/image_picker_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'image_picker_mobile.dart' as imagePicker;
// import 'image_picker_mobile.dart'
// if (dart.library.html) 'image_picker_web.dart'
// if (dart.library.io) 'image_picker_desktop.dart' as imagePicker;
import 'data_model.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'main_page.dart';

class PlayerSetupPage extends StatefulWidget {
  @override
  _PlayerSetupPageState createState() => _PlayerSetupPageState();
}

class _PlayerSetupPageState extends State<PlayerSetupPage> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;
  late String _gender;
  late List<String> _interestedIn;
  String? _imageBase64 = null;
  late bool _imageProcessing;
  late bool _formSubmitted;
  bool _isGenderValid = false;
  bool _isInterestedInValid = false;
  String _genderErrorMessage = '';
  String _interestedInErrorMessage = '';
  String _imageErrorMessage = '';
  final _formKey = GlobalKey<FormState>();
  var uuid = Uuid();


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _bioController = TextEditingController();
    _gender = '';
    _interestedIn = [];
    _imageProcessing = false;
    _formSubmitted = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _formSubmitted ? _buildSecondPage() : _buildFirstPage();
  }

  Widget _buildFirstPage() {
    return Scaffold(
      appBar: AppBar(title: Text('Create Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(32.0),
          children: [
            SizedBox(height: 32.0),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'First Name',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your first name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your age';
                } else if (int.tryParse(value ?? "") == null ||
                    int.parse(value ?? "") < 18) {
                  return 'You must be at least 18 years old';
                }
                return null;
              },
            ),
            SizedBox(height: 32.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Your Gender'),
                      Text(
                        _genderErrorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                      ListTile(
                        title: const Text('Male'),
                        leading: Radio(
                          value: 'Male',
                          groupValue: _gender,
                          onChanged: (String? value) {
                            setState(() {
                              _gender = value ?? _gender;
                              _isGenderValid = value != null;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('Female'),
                        leading: Radio(
                          value: 'Female',
                          groupValue: _gender,
                          onChanged: (String? value) {
                            setState(() {
                              _gender = value ?? _gender;
                              _isGenderValid = value != null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Interested In'),
                      Text(
                        _interestedInErrorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                      CheckboxListTile(
                        title: const Text('Male'),
                        value: _interestedIn.contains('Male'),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value ?? false) {
                              _interestedIn.add('Male');
                            } else {
                              _interestedIn.remove('Male');
                            }
                            _updateInterestedInValidation();
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Female'),
                        value: _interestedIn.contains('Female'),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value ?? false) {
                              _interestedIn.add('Female');
                            } else {
                              _interestedIn.remove('Female');
                            }
                            _updateInterestedInValidation();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _genderErrorMessage =
                      !_isGenderValid ? 'Please select your gender' : '';
                  _interestedInErrorMessage =
                      !_isInterestedInValid ? 'Please select at least one' : '';
                });
                if (_formKey.currentState?.validate() ?? false) {
                  setState(() {
                    _formSubmitted = true;
                  });
                }
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Profile')),
      body: ListView(
        padding: EdgeInsets.all(32.0),
        children: [
          _imageBase64 == null
              ? _imageProcessing
                  ? Center(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.width * 0.5,
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : Icon(Icons.photo,
                      size: MediaQuery.of(context).size.width * 0.5)
              : Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Image.memory(
                    base64Decode(_imageBase64 ?? ''),
                    fit: BoxFit.fitWidth,
                  ),
                ),
          SizedBox(height: 32.0),
          Text(
            _imageErrorMessage,
            style: TextStyle(color: Colors.red),
          ),
          ElevatedButton(
            onPressed: () async {
              var base64Image;
              if (kIsWeb) {
                base64Image = await pickImages();
              } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {

                base64Image = await pickImageDesktop();
              } else {
                base64Image = await imagePicker.pickImage();
              }


              // var base64Image = await imagePicker.pickImage();
              if (base64Image != null) {
                setState(() {
                  _imageBase64 = null;
                  _imageProcessing = true;
                });
                base64Image = await _processImage(base64Image);
                setState(() {
                  _imageErrorMessage = base64Image == null
                      ? 'There was an error processing your image, try again or upload a different one'
                      : '';
                  _imageBase64 = base64Image ?? null;
                  _imageProcessing = false;
                });
              }
            },
            child: Text('Upload a photo'),
          ),
          TextFormField(
            controller: _bioController,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Your bio - write a little about yourself!',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _showOptionalFieldsDialog(context);
            },
            child: Text('Start Matching!'),
          ),
        ],
      ),
    );
  }

  void _updateInterestedInValidation() {
    setState(() {
      _isInterestedInValid = _interestedIn.isNotEmpty;
    });
  }

  Future<String?> _processImage(String base64Image) async {
    return base64Image;
    /*
    String apiUrl = "http://127.0.0.1:7860/sdapi/v1/img2img";

    Map<String, dynamic> requestBody = {
      "prompt": "${_gender}",
      "negative_prompt":
          "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name, naked",
      "steps": 50,
      "width": 512,
      "height": 640,
      "denoising_strength": 0.6,
      "init_images": [base64Image],
    };

    var response = await http.post(Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody));

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      String imageBase64 = responseBody["images"][0];
      return imageBase64;
    } else {
      return null;
    }*/
  }

  void _showOptionalFieldsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Optional Items'),
          content: Text(
              'Including a photo and bio will allow you to have better conversations with your matches. The image will be stylized, and the original image will not be used.'),
          actions: [
            TextButton(
              child: Text('Skip for now'),
              onPressed: () {
                _savePlayer();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Fill in'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _savePlayer() {
    // Create the player object
    Player player = Player(
      playerID: uuid.v4(),
      name: _nameController.text,
      gender: _gender,
      interestedIn: _interestedIn,
      age: int.parse(_ageController.text),
      bio: _bioController.text,
      photos: _imageBase64 == null
          ? []
          : [Photo(description: _gender, photo: _imageBase64!)],
      matches: [],
      maleIndex: 0,
      femaleIndex: 0,
      lastSynced: DateTime.now(),
    );

    // Save the player to local storage
    savePlayer(player).then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(player: player),
        ),
      );
    }).catchError((error) {
      print("errrr:$error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving player: $error')),
      );
    });
  }

  Future<String?> pickImageDesktop() async {
    final typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }
    return null;
  }
}
