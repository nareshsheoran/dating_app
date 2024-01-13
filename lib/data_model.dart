import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class Photo {
  final String description;
  final String photo; // base64 encoded image

  Photo({required this.description, required this.photo});

  Map<String, dynamic> toJson() => {'Description': description, 'Photo': photo};

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(description: json['Description'], photo: json['Photo']);
  }
}

class Person {
  final String personID;
  final String name;
  final String gender;
  final int age;
  final String bio;
  final String personalityTraits;
  final String physicalTraits;
  final List<Photo> photos;

  Person(
      {required this.personID,
      required this.name,
      required this.gender,
      required this.age,
      required this.bio,
      required this.personalityTraits,
      required this.physicalTraits,
      required this.photos});

  Map<String, dynamic> toJson() => {
        'PersonID': personID,
        'Name': name,
        'Gender': gender,
        'Age': age,
        'Bio': bio,
        'PersonalityTraits': personalityTraits,
        'PhysicalTraits': physicalTraits,
        'Photos': photos.map((photo) => photo.toJson()).toList(),
      };

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
        personID: json['PersonID'],
        name: json['Name'],
        gender: json['Gender'],
        age: json['Age'],
        bio: json['Bio'],
        personalityTraits: json['PersonalityTraits'],
        physicalTraits: json['PhysicalTraits'],
        photos: json['Photos']
            .map<Photo>((photo) => Photo.fromJson(photo))
            .toList());
  }
}

class Message {
  String message;
  bool isMine;
  DateTime time;

  Message(this.message, this.isMine, this.time);

  Map<String, dynamic> toJson() =>
      {'Message': message, 'IsMine': isMine, 'Time': time.toIso8601String()};

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
        json['Message'], json['IsMine'], DateTime.parse(json['Time']));
  }
}

class Meetup {
  String location;
  String personId;
  String personName;
  Photo photo;
  bool active;
  DateTime dateAdded;
  List<Message> conversation;

  Meetup(
      {required this.location,
      required this.personName,
      required this.personId,
      required this.photo,
      required this.active,
        required this.dateAdded,
      required this.conversation,});


  factory Meetup.fromJson(Map<String, dynamic> json) {
    return Meetup(
        location: json['Location'],
        personName: json['PersonName'],
        personId: json['PersonId'],
        photo: Photo.fromJson(json['Photo']),
        active: json['Active'],
        dateAdded: DateTime.parse(json['DateAdded']),
        conversation: json['Conversation']
            .map<Message>((message) => Message.fromJson(message))
            .toList());
  }


}

class Match {
  String personID;
  String relationshipPhase;
  bool active;
  List<Message> messages;
  List<Meetup> meetups;
  // List<String> responseSuggestions;
  List responseSuggestions;
  String summary;

  Match(
      {required this.personID,
      required this.relationshipPhase,
      required this.active,
      required this.messages,
      required this.meetups,
      required this.responseSuggestions,
      required this.summary});

  Map<String, dynamic> toJson() => {
        'PersonID': personID,
        'RelationshipPhase': relationshipPhase,
        'Active': active,
        'Messages': messages,
        'Meetups': meetups,
        'ResponseSuggestions': responseSuggestions,
        'Summary': summary
      };

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
        personID: json['PersonID'],
        relationshipPhase: json['RelationshipPhase'],
        active: json['Active'],
        messages: json['Messages']
            .map<Message>((message) => Message.fromJson(message))
            .toList(),
        meetups: json['Meetups']
            .map<Meetup>((meetup) => Meetup.fromJson(meetup))
            .toList(),
        responseSuggestions: json['ResponseSuggestions'],
        summary: json['Summary']);
  }

  void addMeetup(Meetup meetup) {
    meetups.add(meetup);
  }
}

class Player {
  String playerID;
  String name;
  String gender; // "male", "female"
  // List<String> interestedIn; // "male", "female"
  List interestedIn; // "male", "female"
  int age;
  String bio;
  List<Photo> photos;
  List<Match> matches;
  int maleIndex = 0;
  int femaleIndex = 0;
  DateTime lastSynced;

  Player(
      {required this.playerID,
      required this.name,
      required this.gender,
      required this.interestedIn,
      required this.age,
      required this.bio,
      required this.photos,
      required this.matches,
      required this.maleIndex,
      required this.femaleIndex,
      required this.lastSynced});

  String getNextMatchID() {
    String nextMatchID = "";
    if (interestedIn.length > 1) {
      if (maleIndex < femaleIndex) {
        nextMatchID = "man$maleIndex";
        maleIndex++;
      } else {
        nextMatchID = "woman$femaleIndex";
        femaleIndex++;
      }
    } else if (interestedIn[0] == "Male") {
      nextMatchID = "man$maleIndex";
      maleIndex++;
    } else {
      nextMatchID = "woman$femaleIndex";
      femaleIndex++;
    }
    return nextMatchID;
  }

  static Future<Player> fromLocalStorage() async {
    return await loadPlayer();
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
        playerID: json['PlayerID'],
        name: json['Name'],
        gender: json['Gender'],
        interestedIn: List<String>.from(
            json['InterestedIn'].map((interest) => interest as String)),
        age: json['Age'],
        bio: json['Bio'],
        photos: List<Photo>.from(
            json['Photos'].map((photo) => Photo.fromJson(photo))),
        matches: List<Match>.from(
            json['Matches'].map((match) => Match.fromJson(match))),
        maleIndex: json['MaleIndex'],
        femaleIndex: json['FemaleIndex'],
        lastSynced: DateTime.parse(json['LastSynced']));
  }

  Map<String, dynamic> toJson() => {
        'PlayerID': playerID,
        'Name': name,
        'Gender': gender,
        'InterestedIn': interestedIn,
        'Age': age,
        'Bio': bio,
        'Photos': photos.map((photo) => photo.toJson()).toList(),
        'Matches': matches.map((match) => match.toJson()).toList(),
        'MaleIndex': maleIndex,
        'FemaleIndex': femaleIndex,
        'LastSynced': DateFormat('yyyy-MM-ddTHH:mm:ss').format(lastSynced),
      };
}

Future<File?> _getPlayerFile() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final flameFinderDirectory = Directory('${directory.path}/flame_finder');

    // Create the flame_finder directory if it doesn't exist
    if (!await flameFinderDirectory.exists()) {
      flameFinderDirectory.createSync(recursive: true);
    }

    return File('${flameFinderDirectory.path}/player.json');
  } catch (e) {
    // Handle any errors here, such as permission issues
    if (kDebugMode) {
      print('Error: $e');
    }
    return null; // Or return an appropriate response based on your app's needs
  }
}

Future<void> savePlayer(Player player) async {
  final file = await _getPlayerFile();
  final jsonString = jsonEncode(player.toJson());
  await file?.writeAsString(jsonString);
}

Future<Player> loadPlayer() async {
  try {
    final file = await _getPlayerFile();
    final jsonString = await file?.readAsString();
    final jsonMap = jsonDecode(jsonString!);
    print(Player.fromJson(jsonMap));
    return Player.fromJson(jsonMap);
  } catch (e) {
    throw Exception('Error loading player: $e');
  }
}
