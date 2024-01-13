import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

// import 'package:flutter_tindercard/flutter_tindercard.dart';
import 'package:provider/provider.dart';
import 'data_model.dart';
import 'person_repository.dart';
import 'messaging_page.dart';
import 'dart:math';
// import 'package:flutter_tindercard_plus.dart'

class MatchTab extends StatefulWidget {
  final Player player;
  int? index;

  MatchTab({required this.player, required this.index});

  @override
  _MatchTabState createState() => _MatchTabState();
}

class _MatchTabState extends State<MatchTab>
    with AutomaticKeepAliveClientMixin {
  // final CardController _cardController = CardController();
  final CardSwiperController _cardController = CardSwiperController();

  final List<Future<Person>> _personFutures = [];
  int _currentIndex = 0;
  final int _maxCards = 700;
  final int _stackNum = 3;
  bool _isLoading = true;
  int? index;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _preloadPersons(_stackNum);
  }

  @override
  void didUpdateWidget(MatchTab oldWidget) {
    if (oldWidget.index != index) {
      _preloadPersons(_stackNum);
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _preloadPersons(int count) async {
    index = 1;
    for (int i = 0; i < count; i++) {
      _loadNextPerson();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _loadNextPerson() {
    if (_personFutures.length >= _maxCards) {
      return;
    }
    final player = widget.player;
    final userRepository = PersonRepository();
    final nextPersonFuture = userRepository.getPerson(player.getNextMatchID());
    _personFutures.add(nextPersonFuture);
    setState(() {});
  }

  void _showMatchDialog(Person person) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  const Icon(Icons.favorite, size: 100, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "It's a match!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Push your messaging page here.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MessagingPage(
                                  player: widget.player,
                                  person: person,
                                  match: widget.player.matches.last,
                                  isDateFix: false,
                                )),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text(
                      "Send Message",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Keep Swiping",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
            child: Column(
          children: [
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.9,
                child: CardSwiper(
                  controller: _cardController,
                  cardsCount: _personFutures.length,
                  onSwipe: _onSwipe,
                  onUndo: _onUndo,
                  initialIndex: 0,
                  numberOfCardsDisplayed: 3,
                  backCardOffset: const Offset(40, 40),
                  padding: const EdgeInsets.all(24.0),
                  cardBuilder: (context, index, horizontalThresholdPercentage,
                      verticalThresholdPercentage) {
                    // Adapt the cardBuilder logic from TinderSwapCard to CardSwiper
                    return UserCard(
                      key: ValueKey(index),
                      personFuture: _personFutures[index],
                      cardController: _cardController,
                      // Add any other properties or parameters that were used in TinderSwapCard
                    );
                  },
                )),
          ],
        )),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (direction == CardSwiperDirection.left ||
        direction == CardSwiperDirection.right) {
      _currentIndex++;
      if (_currentIndex + _stackNum > _personFutures.length) {
        _loadNextPerson();
      }
    }

    if (direction == CardSwiperDirection.right) {
      final random = Random();
      if (random.nextDouble() < 0.5) {
        _personFutures[previousIndex].then((Person matchedPerson) {
          widget.player.matches.add(Match(
              personID: matchedPerson.personID,
              relationshipPhase: "attraction",
              active: true,
              messages: [],
              meetups: [],
              responseSuggestions: [],
              summary: ""));
          _showMatchDialog(matchedPerson);
          _loadNextPerson();

          bool isPersonIDAlreadyAdded( personID) {
            return widget.player.matches
                .any((match) => match.personID == personID);
          }
          print(
              "!isPersonIDAlreadyAdded(matchedPerson.personID):::${isPersonIDAlreadyAdded(matchedPerson.personID)==false}");

          if (isPersonIDAlreadyAdded(matchedPerson.personID)!=false) {


            _savePlayer(
              widget.player,
              context,
              Match(
                  personID: matchedPerson.personID,
                  relationshipPhase: "attraction",
                  active: true,
                  messages: [],
                  meetups: [],
                  responseSuggestions: [],
                  summary: ""),
            );
          }
        });
      }
    }

    return true;
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    // _maxCards-1;
    return true;
  }
}

class UserCard extends StatefulWidget {
  final Future<Person> personFuture;

  // final CardController cardController;
  final CardSwiperController cardController;

  const UserCard(
      {Key? key, required this.personFuture, required this.cardController})
      : super(key: key);

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  int currentImageIndex = 0;
  final Map<int, Image> images = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32.0),
      ),
      child: FutureBuilder<Person>(
        future: widget.personFuture,
        builder: (BuildContext context, AsyncSnapshot<Person> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            Person person = snapshot.data!;

            Widget buildImage() {
              if (!images.containsKey(currentImageIndex)) {
                final imageData =
                    base64Decode(person.photos[currentImageIndex].photo);
                final image = Image.memory(
                  imageData,
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
                images[currentImageIndex] = image;
              }

              final image = images[currentImageIndex]!;

              return GestureDetector(
                onTapUp: (TapUpDetails details) {
                  // Get the relative x-coordinate of the tap.
                  double tapX = details.localPosition.dx;
                  double imageWidth = MediaQuery.of(context).size.width;

                  // Check if the tap is on the left or right half of the image.
                  if (tapX < imageWidth / 2) {
                    // Left half tapped: show previous image.
                    setState(() {
                      currentImageIndex =
                          (currentImageIndex - 1 + person.photos.length) %
                              person.photos.length;
                    });
                  } else {
                    // Right half tapped: show next image.
                    setState(() {
                      currentImageIndex =
                          (currentImageIndex + 1) % person.photos.length;
                    });
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32.0),
                  child: image,
                ),
              );
            }

            return Column(
              children: [
                Expanded(child: buildImage()),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${person.name}, ${person.age}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        person.bio,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 40, color: Colors.red),
                            onPressed: () {
                              widget.cardController.swipeLeft();
                            },
                          ),
                          const SizedBox(width: 64),
                          IconButton(
                            icon: const Icon(Icons.favorite,
                                size: 40, color: Colors.green),
                            onPressed: () {
                              widget.cardController.swipeRight();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

void _savePlayer(Player players, context, Match matched) {
  Player player = Player(
    playerID: players.playerID,
    name: players.name,
    gender: players.gender,
    interestedIn: players.interestedIn,
    age: players.age,
    bio: players.bio.trimLeft().trimRight(),
    photos: players.photos.isEmpty
        ? []
        : [Photo(description: players.gender, photo: players.photos[0].photo)],
    matches: [...players.matches, matched],
    maleIndex: 0,
    femaleIndex: 0,
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
