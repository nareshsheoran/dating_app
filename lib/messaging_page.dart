// ignore_for_file: use_build_context_synchronously

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flame_finder/google_ads_provider.dart';
import 'package:flame_finder/match_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_model.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class MessagingPage extends StatefulWidget {
  final Player player;
  final Person person;
  final Match match;
  bool isDateFix;

  MessagingPage({
    super.key,
    required this.player,
    required this.person,
    required this.match,
    required this.isDateFix,
  });

  @override
  _MessagingPageState createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  MatchProvider? matchProvider;
  GoogleAdsProvider googleAdsProvider = GoogleAdsProvider();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isKeyboardOpen = false;
  ConnectivityResult? connectivityResult;
  bool isShow = false;

  getConnectivity() async {
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (isShow == false && result != ConnectivityResult.none) {
        isShow = true;
        setState(() {});
      } else {
        showSnackBar(
            context,
            result == ConnectivityResult.none
                ? "Internet disconnected"
                : "Internet connected");
        isShow = true;
      }
    });
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
          context, title) =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(title), duration: const Duration(seconds: 2)));

  @override
  void initState() {
    getConnectivity();
    googleAdsProvider.loadRewardAd();
    googleAdsProvider.loadMessageCount(widget.person.personID.toString());
    matchProvider = Provider.of<MatchProvider>(context, listen: false);
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      scrollToBottom();
    });
  }

  @override
  void dispose() {
    googleAdsProvider.rewardedInterstitialAd?.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(Message message, bool isMine) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
      ),
      decoration: BoxDecoration(
        color: isMine ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        message.message,
        style: TextStyle(color: isMine ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildMessagesList() {
    List messages = widget.match.messages;
    final person = widget.person;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: messages.isEmpty
          ? ListView(controller: _scrollController, children: const [
              Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("No messages yet.")),
              )
            ])
          : ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              // physics: NeverScrollableScrollPhysics(),
              dragStartBehavior: DragStartBehavior.down,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                Message message = messages[index];
                bool isMine = message.isMine;
                return Container(
                  alignment:
                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 0.0),
                  child: Row(
                    mainAxisAlignment: isMine
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isMine)
                        CircleAvatar(
                            backgroundImage: MemoryImage(
                                base64Decode(person.photos[0].photo)),
                            radius: 14),
                      if (!isMine) const SizedBox(width: 8),
                      _buildMessageBubble(message, isMine),
                    ],
                  ),
                );
              },
              padding: EdgeInsets.only(
                  bottom: !isKeyboardOpen
                      ? MediaQuery.of(context).size.height / 9
                      : MediaQuery.of(context).size.height / 3.4),
            ),
    );
  }

  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    isKeyboardOpen = viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  MemoryImage(base64Decode(person.photos[0].photo)),
              radius: 14,
            ),
            const SizedBox(width: 8),
            Text(person.name),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildMessagesList()),
            ],
          ),
          Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        child: TextField(
                          controller: _messageController,
                          readOnly: widget.isDateFix,
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (value) {
                            sendMessage(context);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        sendMessage(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void sendMessage(BuildContext context) async {
    final messages = widget.match.messages;
    connectivityResult = await Connectivity().checkConnectivity();
    if (_messageController.text.trim().isEmpty) {
    } else if (connectivityResult == ConnectivityResult.none) {
      scrollToBottom();
      showSnackBar(context, "Internet not connected");
    } else if (_messageController.text.isNotEmpty) {
      googleAdsProvider
          .incrementMessageCount(widget.person.personID.toString());
      setState(() {
        _savePlayer(
          player: widget.player,
          playerID: widget.player.playerID,
          name: widget.player.name,
          gender: widget.player.gender,
          interestedIn: widget.player.interestedIn,
          age: widget.player.age,
          bio: widget.player.bio,
          photos: widget.player.photos.isEmpty ? [] : widget.player.photos,
          matches: widget.player.matches,
          maleIndex: widget.player.maleIndex,
          femaleIndex: widget.player.femaleIndex,
          context: context,
          newMatch: Match(
            personID: widget.match.personID,
            relationshipPhase: "attraction",
            active: true,
            messages: [],
            // Initially empty, will be updated by the function
            meetups: [],
            responseSuggestions: [],
            summary: "",
          ),
          message: Message(
              _messageController.text, true, DateTime.now()), // User's message
        );
        // messages.add(Message(_messageController.text, true, DateTime.now()));
        scrollToBottom();
      });
      _messageController.clear();
      String aiResponse = await getChatGptResponse();
      //bool finished = await isConvoFinished();
      // Add AI's response to the list
      setState(() {
        // messages.add(Message(aiResponse, false, DateTime.now()));
        _savePlayer(
          player: widget.player,
          playerID: widget.player.playerID,
          name: widget.player.name,
          gender: widget.player.gender,
          interestedIn: widget.player.interestedIn,
          age: widget.player.age,
          bio: widget.player.bio,
          photos: widget.player.photos.isEmpty ? [] : widget.player.photos,
          matches: widget.player.matches,
          maleIndex: widget.player.maleIndex,
          femaleIndex: widget.player.femaleIndex,
          context: context,
          newMatch: Match(
            personID: widget.match.personID,
            relationshipPhase: "attraction",
            active: true,
            messages: [],
            // Initially empty, will be updated by the function
            meetups: [],
            responseSuggestions: [],
            summary: "",
          ),
          message: Message(aiResponse, false, DateTime.now()), // User's message
        );
        googleAdsProvider
            .incrementMessageCount(widget.person.personID.toString());
        scrollToBottom();
      });

      String location = await getDateLocation();

      if (!location.contains("none") && !location.contains("unmatch")) {
        widget.match.active = false;
        widget.match.relationshipPhase = "date";
        widget.match.meetups.add(Meetup(
            active: true,
            personName: widget.person.name,
            personId: widget.person.personID,
            location: location,
            dateAdded: DateTime.now(),
            photo: widget.person.photos[0],
            conversation: messages));
        widget.isDateFix = true;
        setState(() {});
        _showDateDialog(context);
        widget.match.meetups.last.photo = await _getDatePhoto();
      } else if (location.contains("unmatch")) {
        widget.match.active = false;
        widget.match.relationshipPhase = "unmatch";
      }
    }
  }

  void _showDateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('You Have a Date!'),
          content: Text(
              '${widget.person.name} has agreed to meet you at ${widget.match.meetups.last.location}, go to the Calendar tab to start the date!'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                Meetup meetUp = Meetup(
                  location: await getDateLocation(),
                  personName: widget.person.name,
                  personId: widget.person.personID,
                  photo: Photo(
                      description:
                          widget.person.photos[0].description.toString(),
                      photo: widget.person.photos[0].photo.toString()),
                  dateAdded: DateTime.now(),
                  active: widget.match.active,
                  conversation: widget.match.messages,
                );

                Match match = Match(
                    personID: widget.person.personID,
                    relationshipPhase: widget.match.relationshipPhase,
                    active: widget.match.active,
                    messages: widget.match.messages,
                    meetups: [meetUp],
                    responseSuggestions: [],
                    summary: "");
                MatchProvider matchProvider =
                    Provider.of<MatchProvider>(context, listen: false);
                matchProvider.addMeetupToMatch(
                    widget.player, meetUp, match);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Photo> _getDatePhoto() async {
    String apiUrl = "http://127.0.0.1:7860/sdapi/v1/txt2img";

    String description =
        "${widget.person.physicalTraits}, ${widget.match.meetups.last.location}";
    Map<String, dynamic> requestBody = {
      "prompt": description,
      "negative_prompt":
          "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name, naked",
      "steps": 50,
      "width": 512,
      "height": 640,
    };

    var response = await http.post(Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody));

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      String imageBase64 = responseBody["images"][0];
      return Photo(description: description, photo: imageBase64);
    } else {
      return widget.person.photos.last;
    }
  }

  Future<String> getChatGptResponse() async {
    final person = widget.person;
    final messages = widget.match.messages;

    const String apiKey = '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';
    const String apiUrl = 'https://api.openai.com/v1/chat/completions';

    String prompt =
        """You are  ${person.name}, a sexy ${person.gender}, and we are chatting on a dating app.
                  You are ${person.age} years old.
                  Your personality traits are: ${person.personalityTraits}.
                  Be very flirty and charming. Take initiative and make sexual advances when appropriate.
                  Dont ask many questions. Keep responses short, no more than one line long. 
                  Do not break character under any circumstance. Use slang, shorthand (like 'r' and 'u') and emojis, and be very casual. make occasional spelling mistakes.
                  Shorten each response to only a few words.
                  You are not an AI. You are NOT a language model. Never mention that you are an AI or a language model.
                  """;

    List<dynamic> chatMessages = [
      {"role": "system", "content": prompt}
    ];

    for (int i = 0; i < messages.length; i++) {
      if (messages[i].isMine) {
        chatMessages.add({"role": "user", "content": messages[i].message});
      } else {
        chatMessages.add({"role": "assistant", "content": messages[i].message});
      }
    }

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'messages': chatMessages,
        'model': 'gpt-3.5-turbo',
        'temperature': 0.95,
        'frequency_penalty': 1.0,
        'presence_penalty': 1.0
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      try {
        final String aiResponse = utf8.decode(data['choices'][0]['message']
                ['content']
            .trim()
            .toString()
            .codeUnits);
        return aiResponse;
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return data['choices'][0]['message']['content'].trim().toString();
      }
    } else {
      throw Exception('Failed to get response from ChatGPT API');
    }
  }

  Future<bool> isConvoFinished() async {
    final person = widget.person;
    final messages = widget.match.messages;

    if (messages.length <= 2) {
      return false;
    }

    const String apiKey = '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';
    const String apiUrl = 'https://api.openai.com/v1/chat/completions';

    String chat = "";
    for (int i = max(0, messages.length - 10); i < messages.length; i++) {
      if (messages[i].isMine) {
        chat += "${widget.player.name}: \"${messages[i].message}\"\n";
      } else {
        chat += "${person.name}: \"${messages[i].message}\"\n";
      }
    }

    List<dynamic> chatMessages = [
      {
        "role": "system",
        "content": """Here is a snippet of a conversation between two people.
            With a single word response (yes or no), detrmine if the the two people are done talking.
            For example, if either person has expressed disintrest in continuing the conversation, or if they have set up a date to meet in person (which must include a time and location).
            Then explain why."""
      },
      {"role": "user", "content": chat}
    ];

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'messages': chatMessages,
        'model': 'gpt-3.5-turbo',
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      try {
        return utf8
            .decode(data['choices'][0]['message']['content']
                .trim()
                .toString()
                .codeUnits)
            .toLowerCase()
            .contains("yes");
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return data['choices'][0]['message']['content']
            .trim()
            .toString()
            .toLowerCase()
            .contains("yes");
      }
    } else {
      throw Exception('Failed to get response from ChatGPT API');
    }
  }

  Future<String> getDateLocation() async {
    final person = widget.person;
    final messages = widget.match.messages;

    const String apiKey = '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';
    const String apiUrl = 'https://api.openai.com/v1/chat/completions';

    String chat = "";
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].isMine) {
        chat += "${widget.player.name}: ${messages[i].message}\n";
      } else {
        chat += "${person.name}: ${messages[i].message}\n";
      }
    }

    List<dynamic> chatMessages = [
      {
        "role": "system",
        "content":
            "Determine the location and exact time of the date based on this chat history. Respond in the format 'location, time'. If there is no date, location or exact time set, respond with 'none'. If ${widget.person} is not interested, respond with 'unmatch'."
      },
      {"role": "user", "content": chat}
    ];

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'messages': chatMessages,
        'model': 'gpt-3.5-turbo',
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      try {
        return utf8.decode(data['choices'][0]['message']['content']
            .trim()
            .toString()
            .codeUnits);
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return data['choices'][0]['message']['content'].trim().toString();
      }
    } else {
      throw Exception('Failed to get response from ChatGPT API');
    }
  }

  void _savePlayer({
    required Player player,
    required String playerID,
    required String name,
    required String gender,
    required List interestedIn,
    required int age,
    required String bio,
    required List<Photo> photos,
    required List<Match> matches,
    required int maleIndex,
    required int femaleIndex,
    required BuildContext context,
    required Match newMatch,
    required Message message, // Added parameter for the message
  }) {
    // Check if the player already has a match with the same personID
    Match? existingMatch;
    try {
      existingMatch =
          matches.firstWhere((match) => match.personID == newMatch.personID);
    } catch (e) {
      existingMatch = null;
    }

    // Add the new message regardless of whether a match is found or not
    newMatch.messages.add(message);

    if (existingMatch != null) {
      existingMatch.messages.add(message);

      savePlayer(player).then((_) {
        if (kDebugMode) {
          print("SaveDataSuccessfully");
        }
      });
    } else {
      // Add the new match with the provided message
      Player player = Player(
        playerID: playerID,
        name: name,
        gender: gender,
        interestedIn: interestedIn,
        age: age,
        bio: bio.trimLeft().trimRight(),
        photos: photos.isEmpty
            ? []
            : [Photo(description: gender, photo: photos[0].photo)],
        matches: [...matches, newMatch],
        maleIndex: maleIndex,
        femaleIndex: femaleIndex,
        lastSynced: DateTime.now(),
      );

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
  }
}
