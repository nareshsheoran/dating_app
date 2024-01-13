// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flame_finder/date_page.dart';
import 'package:flame_finder/match_provider.dart';
import 'package:flame_finder/person_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'data_model.dart';

class CalendarTab extends StatefulWidget {
  final Player player;
  int? index;

  CalendarTab({Key? key, required this.player, required this.index})
      : super(key: key);

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  PersonRepository personRepository = PersonRepository();
  MatchProvider? matchProvider;
  Match? match;
  int? index;

  getData() async {
    matchProvider = Provider.of<MatchProvider>(context, listen: false);
    match = matchProvider?.match;
    index = 0;
    setState(() {});
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  void didUpdateWidget(CalendarTab oldWidget) {
    if (oldWidget.index != index) {
      getData();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    getData();
    return SafeArea(
      child: Scaffold(
        body: match == null
            ? const Center(child: Text("Not find any fixed date."))
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: match!.meetups.length,
                  itemBuilder: (BuildContext context, index) {
                    var item = match!.meetups[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: MemoryImage(
                            Uint8List.fromList(
                              base64Decode(item.photo.photo.toString()),
                            ),
                          ),
                        ),
                        title: Text(item.personName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        subtitle: Text(item.location),
                        minVerticalPadding: 8,
                        onTap: () async {
                          Person person = await personRepository.getPerson(match!.personID);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DatePage(
                                      player: widget.player,
                                      match: match!,
                                      isDateFix: true,
                                      index: index,
                                      conversation:
                                          match!.meetups[index].conversation,
                                      person: person,
                                      )));
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
