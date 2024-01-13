import 'package:flame_finder/profile_tab.dart';
import 'package:flutter/material.dart';
import 'calendar_tab.dart';
import 'messages_tab.dart';
import 'match_tab.dart';
import 'data_model.dart';

class MainPage extends StatefulWidget {
  Player player;

  MainPage({required this.player});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  Widget _buildIndexedStack(BuildContext context) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        MatchTab(player: widget.player,index: _selectedIndex),
        MessagesTab(player: widget.player),
        ProfileTab(player:widget.player),
        CalendarTab(player:widget.player,index: _selectedIndex),
        Container(color: Colors.purple), // Placeholder for Settings tab
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text('Flame Finder')),
      body: _buildIndexedStack(context),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
