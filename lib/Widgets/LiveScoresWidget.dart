import 'package:betamigo/FootballApiService.dart';
import 'package:betamigo/Widgets/LeagueSelectionWidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class LiveScoresWidget extends StatefulWidget {
  final String league;

  LiveScoresWidget({required this.league});

  @override
  _LiveScoresWidgetState createState() => _LiveScoresWidgetState();
}

class _LiveScoresWidgetState extends State<LiveScoresWidget> {
  List<dynamic> _matches = [];
  bool _showPlayedMatches = false;
  late FootballAPIService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = FootballAPIService();
    _fetchNextWeekLiveScores();
  }

  Future<void> _fetchNextWeekLiveScores() async {
    try {
      final matches = await _apiService.fetchNextWeekLiveScores(widget.league);
      setState(() {
        _matches = matches;
      });
    } catch (e) {
      print('Error fetching next week live scores: $e');
      // Manejar el error aquí
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partidos en Vivo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showPlayedMatches = false;
                    });
                  },
                  child: Text('Próximos Partidos'),
                ),
                SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showPlayedMatches = true;
                    });
                  },
                  child: Text('Resultados'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showPlayedMatches ? _buildFinishedMatchesList() : _buildNextWeekMatchesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedMatchesList() {
    return FutureBuilder(
      future: _apiService.fetchTodayFinishedMatches(widget.league),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final List<dynamic> matches = snapshot.data as List<dynamic>;
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final matchDate = DateTime.parse(match['utcDate']);
              final homeTeamName = match['homeTeam']['name'];
              final awayTeamName = match['awayTeam']['name'];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  title: Text('$homeTeamName vs $awayTeamName'),
                  subtitle: Text(DateFormat('EEEE, MMM d, y - HH:mm').format(matchDate)),
                  trailing: Text('${match['score']['fullTime']['homeTeam']} - ${match['score']['fullTime']['awayTeam']}'),
                  onTap: () {
                    _showMatchDetails(context, match); // Mostrar detalles del partido al hacer clic
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildNextWeekMatchesList() {
    return ListView.builder(
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        final matchDate = DateTime.parse(match['utcDate']);
        final isPlayed = match['status'] == 'FINISHED';
        final homeTeamName = match['homeTeam']['name'];
        final awayTeamName = match['awayTeam']['name'];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text('$homeTeamName vs $awayTeamName'),
            subtitle: Text(DateFormat('EEEE, MMM d, y - HH:mm').format(matchDate)),
            trailing: Text(isPlayed ? '${match['score']['fullTime']['homeTeam']} - ${match['score']['fullTime']['awayTeam']}' : 'Próximo'),
            onTap: () {
              _showMatchDetails(context, match); // Mostrar detalles del partido al hacer clic
            },
          ),
        );
      },
    );
  }

  void _showMatchDetails(BuildContext context, dynamic match) {
    // Mostrar una ventana emergente con más detalles del partido
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${match['homeTeam']['name']} vs ${match['awayTeam']['name']}'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fecha: ${DateFormat('EEEE, MMM d, y - HH:mm').format(DateTime.parse(match['utcDate']))}'),
              SizedBox(height: 8),
              Text('Estado: ${match['status']}'),
              SizedBox(height: 8),
              Text('Resultado: ${match['score']['fullTime']['homeTeam']} - ${match['score']['fullTime']['awayTeam']}'),
              // Agrega más detalles del partido según sea necesario
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar la ventana emergente
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Bet Amigo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: LiveScoresWidget(league: 'ligue1'), // Aquí puedes pasar el nombre de la liga como parámetro
  ));
}
