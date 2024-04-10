import 'package:betamigo/Widgets/BettingWidget.dart';
import 'package:betamigo/Widgets/LeagueSelectionWidget.dart';
import 'package:betamigo/Widgets/SocialWidget.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    LeagueSelectionWidget(),
    SocialWidget(),
    BettingWidget(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _onItemTapped(0),
              child: Row(
                children: [
                  Icon(Icons.sports_soccer, color: _selectedIndex == 0 ? Colors.blue : Colors.black),
                  if (!isSmallScreen) ...[
                    SizedBox(width: 4),
                    Text('Ligas y Partidos', style: TextStyle(color: _selectedIndex == 0 ? Colors.blue : Colors.black)),
                  ]
                ],
              ),
            ),
            SizedBox(width: 16),
            GestureDetector(
              onTap: () => _onItemTapped(1),
              child: Row(
                children: [
                  Icon(Icons.group, color: _selectedIndex == 1 ? Colors.blue : Colors.black),
                  if (!isSmallScreen) ...[
                    SizedBox(width: 4),
                    Text('Social y Amigos', style: TextStyle(color: _selectedIndex == 1 ? Colors.blue : Colors.black)),
                  ]
                ],
              ),
            ),
            SizedBox(width: 16),
            GestureDetector(
              onTap: () => _onItemTapped(2),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: _selectedIndex == 2 ? Colors.blue : Colors.black),
                  if (!isSmallScreen) ...[
                    SizedBox(width: 4),
                    Text('Apuestas Virtuales', style: TextStyle(color: _selectedIndex == 2 ? Colors.blue : Colors.black)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Bet Amigo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: MainScreen(),
  ));
}
