import 'dart:convert';
import 'dart:io';
import 'package:flame_finder/data_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'image_picker_mobile.dart' as imagePicker;

class ProfileTab extends StatefulWidget {
  final Player player;

  const ProfileTab({Key? key, required this.player}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;
  bool isNameReadOnly = true;
  bool isAgeReadOnly = true;
  bool isBioReadOnly = true;
  late String _gender;
  late List _interestedIn;
  String? _imageBase64 = null;
  bool _isGenderValid = false;
  String _imageErrorMessage = '';
  final _formKey = GlobalKey<FormState>();
  List<int> bytes = [];

  getPlayerData() {
    for (Photo photo in widget.player.photos) {
      _imageBase64 = photo.photo;
      bytes = base64Decode(photo.photo);
    }
  }

  @override
  void initState() {
    super.initState();
    getPlayerData();
    _nameController = TextEditingController(text: widget.player.name);
    _ageController = TextEditingController(text: widget.player.age.toString());
    _bioController = TextEditingController(text: widget.player.bio);
    _gender = widget.player.gender;
    _interestedIn = widget.player.interestedIn;
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
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: MediaQuery.of(context).size.height / 8,
                        backgroundImage: bytes.isEmpty
                            ? const NetworkImage(
                                    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_G0N9CN_iM6-kvF6qpZFibDRcR-t25KVQQA&usqp=CAU")
                                as ImageProvider<Object>
                            : MemoryImage(Uint8List.fromList(bytes)),
                        child: Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
                              child: InkWell(
                                onTap: () {
                                  imageData();
                                },
                                child: const CircleAvatar(
                                    child: Center(
                                        child: Icon(
                                  Icons.edit,
                                ))),
                              ),
                            )),
                      ),
                    ],
                  ),
                  _imageErrorMessage.isEmpty
                      ? const SizedBox()
                      : Text(_imageErrorMessage,
                          style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  buildDataField(_nameController, isNameReadOnly, 0, "Name"),
                  buildDataField(_ageController, isAgeReadOnly, 1, "Age"),
                  const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text('Your Gender')),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Male'),
                          contentPadding: EdgeInsets.zero,
                          leading: Radio(
                            value: 'Male',
                            groupValue: _gender,
                            onChanged: (String? value) {
                              setState(() {
                                _gender = value ?? _gender;
                                _isGenderValid = value != null;
                                _savePlayer();
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Female'),
                          contentPadding: EdgeInsets.zero,
                          leading: Radio(
                            value: 'Female',
                            groupValue: _gender,
                            onChanged: (String? value) {
                              setState(() {
                                _gender = value ?? _gender;
                                _isGenderValid = value != null;
                                _savePlayer();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text('Interested In')),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 5,
                            child: CheckboxListTile(
                              title: const Text('Male'),
                              contentPadding: EdgeInsets.zero,
                              value: _interestedIn.contains('Male'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value ?? false) {
                                    _interestedIn.add('Male');
                                  } else {
                                    _interestedIn.remove('Male');
                                  }
                                  if (_interestedIn.isEmpty) {
                                    _interestedIn.add('Male');
                                  } else {
                                    _savePlayer();
                                  }
                                });
                              },
                            )),
                        const Expanded(flex: 4, child: SizedBox()),
                        Expanded(
                            flex: 5,
                            child: CheckboxListTile(
                              title: const Text('Female'),
                              contentPadding: EdgeInsets.zero,
                              value: _interestedIn.contains('Female'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value ?? false) {
                                    _interestedIn.add('Female');
                                  } else {
                                    _interestedIn.remove('Female');
                                  }
                                  if (_interestedIn.isEmpty) {
                                    _interestedIn.add('Female');
                                  } else {
                                    _savePlayer();
                                  }
                                });
                              },
                            )),
                      ],
                    ),
                  ),
                  buildDataField(_bioController, isBioReadOnly, 2, "Bio"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDataField(controller, readOnly, index, label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType:
                      index == 1 ? TextInputType.number : TextInputType.name,
                  onChanged: (value) {
                    _savePlayer();
                  },
                  onFieldSubmitted: (value) {
                    setState(() {
                      index == 0
                          ? isNameReadOnly = true
                          : index == 1
                              ? isAgeReadOnly = true
                              : isBioReadOnly = true;
                      _savePlayer();
                    });
                  },
                  decoration: InputDecoration(
                      labelText: label,
                      border: InputBorder.none,
                      suffixIcon: InkWell(
                          onTap: () {
                            setState(() {
                              index == 0
                                  ? isNameReadOnly = false
                                  : index == 1
                                      ? isAgeReadOnly = false
                                      : isBioReadOnly = false;
                            });
                          },
                          child: const Icon(Icons.edit))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _savePlayer() {
    // Create the player object
    Player player = Player(
      playerID: widget.player.playerID,
      name: _nameController.text.trimLeft().trimRight(),
      gender: _gender,
      interestedIn: _interestedIn,
      age: int.parse(_ageController.text.trim()),
      bio: _bioController.text.trimLeft().trimRight(),
      photos: _imageBase64 == null
          ? []
          : [Photo(description: _gender, photo: _imageBase64!)],
      matches: [],
      maleIndex: 0,
      femaleIndex: 0,
      lastSynced: DateTime.now(),
    );
    setState(() {});

    savePlayer(player).then((_) {
      if (kDebugMode) {
        print("SaveDataSuccessfully");
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving player: $error')),
      );
    });
  }

  imageData() async {
    var base64Image;
    if (kIsWeb) {
      base64Image = await imagePicker.pickImage();
    } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      base64Image = await imagePicker.pickImage();
    } else {
      base64Image = await imagePicker.pickImage();
    }

    // var base64Image = await imagePicker.pickImage();
    if (base64Image != null) {
      setState(() {
        _imageBase64 = null;
      });

      bytes = base64Decode(base64Image!);
      // base64Image = await _processImage(base64Image);
      _imageBase64 = base64Image;
      _savePlayer();
      setState(() {
        _imageErrorMessage = base64Image == null
            ? 'There was an error processing your image, try again or upload a different one'
            : '';
        _imageBase64 = base64Image;
      });
    }
  }
}
