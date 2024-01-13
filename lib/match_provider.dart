import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'data_model.dart';

class MatchProvider with ChangeNotifier {
  Match? _match;

  Match? get match => _match;

  void setMatch(Match match) {
    _match = match;
    notifyListeners();
  }

  getPlayerData(Meetup meetup, Match match) async {
    bool isDuplicate = false;
    Player player = await Player.fromLocalStorage();
    List<Match> matchList = player.matches;
    List<Meetup>? meetupList;

    for (var element in matchList) {
      meetupList ??= []; // Initialize the list if it's null
      meetupList.addAll(element.meetups);
      notifyListeners();
      notifyListeners();
    }
    for (var element in meetupList!) {
      if (element.personId == meetup.personId) {
        isDuplicate = true;

        // Add the meetup to the list of meetups in the match where personId matches
        int matchIndex = player.matches.indexWhere(
          (match) => match.meetups
              .any((meetup) => meetup.personId == element.personId),
        );

        if (matchIndex != -1) {
          player.matches[matchIndex].meetups.add(meetup);
          player.matches[matchIndex].meetups.sort((a, b) =>
              b.dateAdded.compareTo(a.dateAdded)); // Sort meetups by dateAdded
          notifyListeners();
        }

        break;
      }
    }

    if (!isDuplicate) {
      Match newMatch = Match(
        personID: match.personID,
        relationshipPhase: match.relationshipPhase,
        active: match.active,
        messages: match.messages,
        meetups: [meetup],
        // Add the meetup to the new match
        responseSuggestions: match.responseSuggestions,
        summary: match.summary,
      );

      player.matches.add(newMatch);
      player.matches.sort((a, b) => b.meetups.isNotEmpty && a.meetups.isNotEmpty
          ? b.meetups.first.dateAdded.compareTo(a.meetups.first.dateAdded)
          : 0); // Sort matches by the date of their first meetup
      notifyListeners();
    }
    _savePlayer(player, matchList);
  }

  Future<void> addMeetupToMatch(
      Player player, Meetup meetup, Match match) async {
    getPlayerData(meetup, match);
    if (_match != null) {
      bool isDuplicate = _match!.meetups
          .any((existingMeetup) => existingMeetup.personId == meetup.personId);
      if (!isDuplicate) {
        _match!.meetups.add(meetup);
        _match!.meetups.sort((a, b) =>
            b.dateAdded.compareTo(a.dateAdded)); // Sort meetups by dateAdded
        notifyListeners();
      }
    } else {
      _match = Match(
        personID: match.personID,
        relationshipPhase: match.relationshipPhase,
        active: match.active,
        messages: match.messages,
        meetups: [meetup],
        responseSuggestions: match.responseSuggestions,
        summary: match.summary,
      );

      match.meetups.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
      notifyListeners();
    }
    print("Match.MeetUps.length::${_match!.meetups.length}");
  }

  void _savePlayer(Player players, List<Match> matched) {
    Player player = Player(
      playerID: players.playerID,
      name: players.name,
      gender: players.gender,
      interestedIn: players.interestedIn,
      age: players.age,
      bio: players.bio.trimLeft().trimRight(),
      photos: players.photos.isEmpty
          ? []
          : [
              Photo(description: players.gender, photo: players.photos[0].photo)
            ],
      matches: matched,
      maleIndex: 0,
      femaleIndex: 0,
      lastSynced: DateTime.now(),
    );

    savePlayer(player).then((_) {
      if (kDebugMode) {
        print("SaveDataSuccessfully provider");
      }
    }).catchError((error) {
      print("provider save data error: $error");
    });
  }
}
