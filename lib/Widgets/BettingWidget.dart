import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class BettingWidget extends StatefulWidget {
  @override
  _BettingWidgetState createState() => _BettingWidgetState();
}

class _BettingWidgetState extends State<BettingWidget> {
  List<String> ligas = ['Bundesliga', 'Premier League', 'Ligue 1', 'Serie A', 'Champions League', 'Liga BBVA'];
  Map<String, String> leagueCodes = {
    'Bundesliga': 'BL1',
    'Premier League': 'PL',
    'Ligue 1': 'FL1',
    'Serie A': 'SA',
    'Champions League': 'CL',
    'Liga BBVA': 'PD',
  };
  String? selectedLeague;
  String? selectedMatch; // Variable para almacenar el partido seleccionado
  List<String> matches = [];
  List<String> grupos = []; // Lista para almacenar los grupos del usuario
  String? selectedGroup; // Variable para almacenar el grupo seleccionado
  TextEditingController _nombreApuestaController = TextEditingController();
  TextEditingController _equipo1Controller = TextEditingController();
  TextEditingController _equipo2Controller = TextEditingController();
  DateTime? _fechaSeleccionada;
  Map<String, List<String>> leagueMatchesMap = {}; // Mapa para almacenar los partidos por liga

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
    _fetchMatchesForAllLeagues(); // Llama a la función para obtener los partidos de todas las ligas al iniciar el widget
  }

  Future<void> _fetchMatchesForAllLeagues() async {
    for (String liga in ligas) {
      await _fetchNextWeekLiveScores(leagueCodes[liga]!);
    }
  }

  Future<void> _fetchNextWeekLiveScores(String leagueCode) async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/$leagueCode/next-week-live-scores'));
    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      setState(() {
        List<String> leagueMatches = [];
        for (var match in data['matches']) {
          final homeTeamName = match['homeTeam']['name'];
          final awayTeamName = match['awayTeam']['name'];
          leagueMatches.add('$homeTeamName vs $awayTeamName');
        }
        leagueMatchesMap[leagueCode] = leagueMatches; // Guarda los partidos en el mapa utilizando el código de la liga como clave
        // Seleccionar el primer partido si no hay ninguno seleccionado
        if (selectedMatch == null && leagueMatches.isNotEmpty) {
          selectedMatch = leagueMatches.first;
        }
      });
    } else {
      print('Error al cargar los próximos partidos para la liga $leagueCode: ${response.statusCode}');
    }
  }

  Future<void> _fetchUserGroups() async {
    String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
    final response = await FirebaseFirestore.instance.collection('users').doc(usuarioActualId).get();

    if (response.exists) {
      String usuarioActualName = response.data()?['user'];
    
      final groupsResponse = await FirebaseFirestore.instance.collection('grupos').where('miembros', arrayContains: usuarioActualName).get();
    
      if (groupsResponse.docs.isNotEmpty) {
        setState(() {
          grupos = groupsResponse.docs.map((doc) => doc.data()['nombre']).toList().cast<String>();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apuestas Virtuales'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Pantalla de Bombardeen segovia'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return _mostrarSeleccionAmigos(context);
                  },
                );
              },
              child: Text('Crear Apuesta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mostrarSeleccionAmigos(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AlertDialog(
          title: Text('Creación de Apuesta'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nombreApuestaController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Apuesta',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedGroup,
                    decoration: InputDecoration(
                      labelText: 'Grupo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    items: grupos.map((grupo) {
                      return DropdownMenuItem<String>(
                        value: grupo,
                        child: Text(grupo),
                      );
                    }).toList(),
                    onChanged: (String? selectedGroupValue) {
                      setState(() {
                        selectedGroup = selectedGroupValue;
                        // Vaciar el campo de partido al cambiar de grupo
                        selectedMatch = null;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedLeague,
                    decoration: InputDecoration(
                      labelText: 'Ligas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    items: ligas.map((liga) {
                      return DropdownMenuItem<String>(
                        value: liga,
                        child: Text(liga),
                      );
                    }).toList(),
                    onChanged: (String? selectedLeagueValue) {
                      setState(() {
                        selectedLeague = selectedLeagueValue;
                        // Actualiza los partidos disponibles al cambiar de liga
                        matches = leagueMatchesMap[leagueCodes[selectedLeagueValue ?? '']] ?? [];
                        // Seleccionar el primer partido si hay partidos disponibles
                        if (matches.isNotEmpty) {
                          selectedMatch = matches.first;
                        }
                      });
                    },
                  ),
                  if (selectedLeague != null && selectedLeague!.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedMatch,
                          decoration: InputDecoration(
                            labelText: 'Partidos',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          items: matches.map((match) {
                            return DropdownMenuItem<String>(
                              value: match,
                              child: Text(match),
                            );
                          }).toList(),
                          onChanged: (String? selectedMatchValue) {
                            setState(() {
                              selectedMatch = selectedMatchValue;
                            });
                          },
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _equipo1Controller,
                    decoration: InputDecoration(
                      labelText: 'Equipo 1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _equipo2Controller,
                    decoration: InputDecoration(
                      labelText: 'Equipo 2',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      final fechaSeleccionada = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      setState(() {
                        _fechaSeleccionada = fechaSeleccionada;
                      });
                    },
                    child: Text(
                      _fechaSeleccionada != null
                          ? 'Fecha Seleccionada: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}'
                          : 'Seleccionar Fecha',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Aquí puedes agregar la lógica para guardar la apuesta en la base de datos
                // y asociarla con el grupo seleccionado
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
