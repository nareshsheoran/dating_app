import 'package:flame_finder/match_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_model.dart';
import 'messaging_page.dart';
import 'person_repository.dart';
import 'dart:convert';
import 'dart:io';

class MessagesTab extends StatefulWidget {
  final Player player;

  const MessagesTab({required this.player});

  @override
  _MessagesTabState createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final PersonRepository _userRepository = PersonRepository();
  MatchProvider? matchProvider;
  Match? _match;

  @override
  void initState() {
    matchProvider = Provider.of<MatchProvider>(context, listen: false);
    _match = Provider.of<MatchProvider>(context, listen: false).match;
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _match == null ? _match = matchProvider?.match : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding:
              EdgeInsets.only(top: 64.0, left: 32.0, right: 32.0, bottom: 32.0),
          child: Text(
            'New Matches',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 160,
          child: _buildMatchesSection(context),
        ),
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Messages',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: _buildMessagesSection(context)),
      ],
    );
  }

  Widget _buildMatchesSection(BuildContext context) {
    final player = widget.player;
    final scrollController = ScrollController();

    // Build list of all player matches that have no message history
    final newMatches =
        player.matches.where((match) => match.messages.isEmpty).toList();

    return Scrollbar(
        // isAlwaysShown: Platform.isWindows ? false : true,
        // controller: Platform.isWindows ? scrollController : null,
        // interactive: Platform.isWindows ? false : true,
        child: SizedBox(
            height: 160,
            child: ListView.builder(
              itemCount: newMatches.length,
              padding: const EdgeInsets.only(left: 32, right: 32),
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                bool isDateFix = _match == null
                    ? false
                    : _match!.meetups.any((existingMeetup) =>
                        existingMeetup.personId.toString() ==
                        newMatches[index].personID.toString());

                return FutureBuilder<Person>(
                    future:
                        _userRepository.getPerson(newMatches[index].personID),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        final person = snapshot.data!;
                        return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MessagingPage(
                                    player: player,
                                    person: person,
                                    match: newMatches[index],
                                    isDateFix: isDateFix,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: MemoryImage(
                                      base64Decode(person.photos[0].photo),
                                    ),
                                    radius: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(person.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ));
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    });
              },
            )));
  }

  Widget _buildMessagesSection(BuildContext context) {
    final player = widget.player;

    // Build a list of all player matches that have message history
    final messageHistory =
        player.matches.where((match) => match.messages.isNotEmpty).toList();
    final scrollController = ScrollController();

    return Scrollbar(
      // isAlwaysShown: Platform.isWindows ? false : true,
      // controller: Platform.isWindows ? scrollController : null,
      // interactive: Platform.isWindows ? false : true,
      child: ListView.builder(
        itemCount: messageHistory.length,
        padding: const EdgeInsets.only(left: 32, right: 32),
        itemBuilder: (BuildContext context, int index) {
          bool isDateFix = _match == null
              ? false
              : _match!.meetups.any((existingMeetup) =>
                  existingMeetup.personId.toString() ==
                  messageHistory[index].personID.toString());

          return FutureBuilder<Person>(
            future: _userRepository.getPerson(messageHistory[index].personID),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                final person = snapshot.data!;
                final lastMessage = messageHistory[index].messages.last.message;
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagingPage(
                          player: player,
                          person: person,
                          match: messageHistory[index],
                          isDateFix: isDateFix,
                        ),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundImage:
                        MemoryImage(base64Decode(person.photos[0].photo)),
                    radius: 28,
                  ),
                  title: Text(person.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Text(lastMessage),
                  minVerticalPadding: 8,
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          );
        },
      ),
    );
  }
}
