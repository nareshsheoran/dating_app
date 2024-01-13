import 'dart:convert';
import 'dart:math';
import 'package:flame_finder/data_model.dart';
import 'package:flame_finder/match_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class DatePage extends StatefulWidget {
  final Player player;
  final Person person;
  final Match match;
  bool isDateFix;
  final bool shouldRefreshImage;
  final int index;
  final List conversation;

  DatePage({
    Key? key,
    required this.player,
    required this.person,
    required this.match,
    required this.isDateFix,
    required this.index,
    required this.conversation,
    this.shouldRefreshImage = false,
  }) : super(key: key);

  @override
  State<DatePage> createState() => _DatePageState();
}

class _DatePageState extends State<DatePage> {
  TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isKeyboardOpen = false;
  Future<Uint8List?>? _loadImage;
  Uint8List? imageData;

  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadImage = _loadImageData();
    _loadImage?.then((value) {
      setState(() {
        imageData = value;
      });
    });
  }

  Future<Uint8List?> _loadImageData() async {
    if (widget.shouldRefreshImage == false) {
      return base64Decode(widget.match.meetups[widget.index].photo.photo);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
                backgroundImage: MemoryImage(
                  imageData ??
                      base64Decode(
                          widget.match.meetups[widget.index].photo.photo),
                ),
                radius: 14),
            const SizedBox(width: 8),
            Text(widget.match.meetups[widget.index].personName)
          ],
        ),
      ),
      body: imageData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: MemoryImage(imageData!),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _buildMessagesList(),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(30.0)),
                            child: TextField(
                              controller: messageController,
                              readOnly: widget.isDateFix,
                              decoration: const InputDecoration(
                                  hintText: 'Type a message',
                                  border: InputBorder.none),
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
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildMessagesList() {
    List messages = widget.conversation;
    // var startIndex = messages.length - 2;
    // if (startIndex < 0) startIndex = 0;
    // List lastTwoMsg = messages.sublist(startIndex);
    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length >= 2 ? 2 : messages.length,
      // itemCount: lastTwoMsg.length,
      itemBuilder: (BuildContext context, int index) {
        final reversedIndex = messages.length - 2 + index;
        Message message = messages[reversedIndex];
        // Message message = lastTwoMsg[index];
        bool isMine = message.isMine;
        return Container(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
          child: Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              isMine
                  ? const SizedBox(width: 8)
                  : CircleAvatar(
                      backgroundImage: MemoryImage(imageData!), radius: 14),
              _buildMessageBubble(message, isMine),
            ],
          ),
        );
      },
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 4),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMine) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
      decoration: BoxDecoration(
          color: isMine ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16.0)),
      child: Text(
        message.message,
        style: TextStyle(color: isMine ? Colors.white : Colors.black),
      ),
    );
  }

  void sendMessage(BuildContext context) async {
    final messages = widget.match.messages;
    if (messageController.text.isNotEmpty) {
      setState(() {
        messages.add(
          Message(messageController.text, true, DateTime.now()),
        );
        scrollToBottom();
      });

      messageController.clear();

      // Send user's message to ChatGPT and receive AI response
      String aiResponse = await getChatGptResponse();

      //bool finished = await isConvoFinished();

      // Add AI's response to the list
      setState(() {
        messages.add(Message(aiResponse, false, DateTime.now()));
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
          conversation: messages,
        ));
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
                matchProvider.addMeetupToMatch(widget.player,meetUp, match);
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

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

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
      {
        "role": "system",
        "content": prompt,
      }
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
      {
        "role": "user",
        "content": chat,
      }
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
      {
        "role": "user",
        "content": chat,
      }
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
}
