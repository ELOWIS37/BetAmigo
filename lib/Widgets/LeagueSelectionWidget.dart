import 'package:betamigo/Widgets/LiveScoresWidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeagueSelectionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ligas y Partidos'),
      ),
      body: Center(
        child: GridView.count(
          crossAxisCount: 2, // Dos columnas en dispositivos móviles, más en tabletas y escritorio
          mainAxisSpacing: 20.0, // Espacio vertical entre las imágenes
          crossAxisSpacing: 20.0, // Espacio horizontal entre las imágenes
          padding: EdgeInsets.all(20.0), // Espacio alrededor del GridView
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveScoresWidget(league: 'BL1'),
                  ),
                );
              },
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Ajusta el radio según tu preferencia
                  child: Image.asset(
                    'assets/bundesliga.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveScoresWidget(league: 'PD'),
                  ),
                );
              },
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Ajusta el radio según tu preferencia
                  child: Image.asset(
                    'assets/laliga.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveScoresWidget(league: 'PL'),
                  ),
                );
              },
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Ajusta el radio según tu preferencia
                  child: Image.asset(
                    'assets/pl.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveScoresWidget(league: 'FL1'),
                  ),
                );
              },
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Ajusta el radio según tu preferencia
                  child: Image.asset(
                    'assets/ligue1.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveScoresWidget(league: 'SA'),
                  ),
                );
              },
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Ajusta el radio según tu preferencia
                  child: Image.asset(
                    'assets/seria.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveScoresWidget(league: 'PPL'),
                  ),
                );
              },
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Ajusta el radio según tu preferencia
                  child: Image.asset(
                    'assets/nos.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}