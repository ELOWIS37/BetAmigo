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
  List<String> matches = [];

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
            SizedBox(height: 20), // Espacio entre el texto y el botón
            ElevatedButton(
              onPressed: () {
                // Mostrar la ventana emergente
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
    List<String> amigosSeleccionados = [];
    TextEditingController _nombreApuestaController = TextEditingController();
    TextEditingController _equipo1Controller = TextEditingController();
    TextEditingController _equipo2Controller = TextEditingController();
    DateTime? _fechaSeleccionada; // Variable para almacenar la fecha seleccionada
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AlertDialog(
          title: Text('Creación de Apuesta'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Ancho del AlertDialog
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
                  SizedBox(height: 20), // Espacio entre el campo de nombre de apuesta y el desplegable de ligas
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
_fetchNextWeekLiveScores(leagueCodes[selectedLeagueValue ?? ''] ?? ''); 
                      });
                    },
                  ),
                  if (selectedLeague != null && selectedLeague!.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(height: 20), // Espacio entre el desplegable de ligas y el desplegable de partidos
                        DropdownButtonFormField<String>(
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
                          onChanged: (String? selectedMatch) {
                            // Aquí puedes agregar la lógica para manejar la selección del partido
                          },
                        ),
                      ],
                    ),
                  SizedBox(height: 20), // Espacio entre los campos de entrada y el resto de campos
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
            // Aquí se puede agregar un botón adicional si se necesita
          ],
        );
      },
    );
  }

  Future<void> _fetchNextWeekLiveScores(String leagueCode) async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/$leagueCode/next-week-live-scores'));
    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      setState(() {
        matches.clear();
        for (var match in data['matches']) {
          final homeTeamName = match['homeTeam']['name'];
          final awayTeamName = match['awayTeam']['name'];
          matches.add('$homeTeamName vs $awayTeamName');
        }
      });
    } else {
      print('Error al cargar los próximos partidos para la liga $leagueCode: ${response.statusCode}');
    }
  }
}
