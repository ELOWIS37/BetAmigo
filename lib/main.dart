import 'package:betamigo/Screens/MainScreen.dart';
import 'package:betamigo/Widgets/LeagueSelectionWidget.dart';
import 'package:betamigo/Widgets/LiveScoresWidget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bet Amigo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(), // Establece el widget de pantalla de live scores como la pantalla principal
    );
  }
}
