import 'package:betamigo/FootballApiService.dart';
import 'package:flutter/material.dart';
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
  String? _errorMessage;

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
        _matches = matches ?? [];
        _errorMessage = null;
      });
    } catch (e) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.red.withOpacity(0.98),
            title: Text(
              '¡Error!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Demasiadas solicitudes en un corto período.\nPor favor, inténtalo de nuevo más tarde.',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Cerrar',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partidos en Vivo'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlueAccent,
              Colors.greenAccent,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: _showPlayedMatches ? Colors.grey : Colors.blueAccent, // Color del texto cuando el botón está activo
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showPlayedMatches = false;
                      });
                      _fetchNextWeekLiveScores();
                    },
                    child: Text('Próximos Partidos'),
                  ),
                  SizedBox(width: 16.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: _showPlayedMatches ? Colors.blueAccent : Colors.grey, // Color del texto cuando el botón está activo
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
      ),
    );
  }

  Widget _buildFinishedMatchesList() {
  return FutureBuilder<List<dynamic>?>(
    future: _apiService.fetchTodayFinishedMatches(widget.league),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        final error = snapshot.error;
        if (error is TooManyRequestsException) {
          return Center(child: Text(error.message));
        }
        return Center(child: Text('Cargando resultados...'));
      } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
        return _buildNoResultsMessage();
      } else {
        final List<dynamic> matches = snapshot.data!;
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            final matchDate = DateTime.parse(match['utcDate']).add(Duration(hours: 2));
            final homeTeamName = match['homeTeam']['name'];
            final awayTeamName = match['awayTeam']['name'];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ListTile(
                title: Text('$homeTeamName vs $awayTeamName'),
                subtitle: Text(DateFormat('EEEE, MMM d, y - HH:mm').format(matchDate)),
                trailing: Text('${match['score']['fullTime']['homeTeam']} - ${match['score']['fullTime']['awayTeam']}'),
                onTap: () {
                  _showMatchDetails(context, match);
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
    if (_matches.isEmpty && _errorMessage == null) {
      return _buildNoMatchesMessage();
    } else if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          final matchDate = DateTime.parse(match['utcDate']).add(Duration(hours: 2)); // Agregar dos horas al tiempo UTC
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
                _showMatchDetails(context, match);
              },
            ),
          );
        },
      );
    }
  }


  Widget _buildNoMatchesMessage() {
    return Center(
      child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No hay partidos en esta temporada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '¡Espera a la siguiente!',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No hay resultados en la última semana',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Revisa más tarde.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showMatchDetails(BuildContext context, dynamic match) {
    final matchDate = DateTime.parse(match['utcDate']).add(Duration(hours: 2)); // Agregar dos horas al tiempo UTC
    print('Fecha y hora ajustadas: $matchDate');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${match['homeTeam']['name']} vs ${match['awayTeam']['name']}'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fecha: ${DateFormat('EEEE, MMM d, y - HH:mm').format(matchDate)}'),
              SizedBox(height: 8),
              Text('Estado: ${match['status']}'),
              SizedBox(height: 8),
              Text('Resultado: ${match['score']['fullTime']['homeTeam']} - ${match['score']['fullTime']['awayTeam']}'),
              // Add more match details as needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
    home: LiveScoresWidget(league: 'ligue1'),
  ));
}

