import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:betamigo/FootballApiService.dart';

class ResultadosApuesta extends StatefulWidget {
  final String nombreApuesta;

  const ResultadosApuesta({Key? key, required this.nombreApuesta}) : super(key: key);

  @override
  _ResultadosApuestaState createState() => _ResultadosApuestaState();
}

class _ResultadosApuestaState extends State<ResultadosApuesta> {
  List<String> escudosEquipos = [];
  List<dynamic> resultadosMesAnterior = [];

  @override
  void initState() {
    super.initState();
    obtenerEscudosEquipos();
    obtenerResultadosMesAnterior();
  }

  Future<void> obtenerEscudosEquipos() async {
    try {
      final response = await http.get(Uri.parse('https://api.football-data.org/v2/competitions/2021/teams'), headers: {
        'X-Auth-Token': '9431a7b3652a47bfb3bda5bc870f4b56',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final equipos = data['teams'] as List<dynamic>;

        setState(() {
          escudosEquipos = equipos.map<String>((equipo) {
            return equipo['crestUrl'] as String? ?? '';
          }).toList();
        });
      } else {
        throw Exception('Error al cargar los escudos de los equipos');
      }
    } catch (error) {
      print('Error al obtener los escudos de los equipos: $error');
    }
  }

  Future<void> obtenerResultadosMesAnterior() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('apuestas')
          .where('nombre', isEqualTo: widget.nombreApuesta)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No se encontraron datos de la apuesta.');
        return;
      }

      final apuestaDoc = snapshot.docs.first;
      final apuesta = apuestaDoc.data() as Map<String, dynamic>;
      final leagueCode = apuesta['league_code'];
      final equipoLocal = apuesta['equipo_local'];
      final equipoVisitante = apuesta['equipo_visitante'];

      final List<dynamic> resultados = await FootballAPIService().fetchLastMonthFinishedMatches(leagueCode);

      final filteredResults = resultados.where((match) {
        final homeTeamName = match['homeTeam']['name'];
        final awayTeamName = match['awayTeam']['name'];
        return homeTeamName == equipoLocal && awayTeamName == equipoVisitante;
      }).toList();

      setState(() {
        resultadosMesAnterior = filteredResults;
      });

      print('Resultados del mes anterior:');
      print(resultadosMesAnterior);
      print('Número de partidos encontrados: ${resultadosMesAnterior.length}');
    } catch (error) {
      print('Error al obtener los resultados del mes anterior: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de la Apuesta'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('apuestas').where('nombre', isEqualTo: widget.nombreApuesta).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return Text('No se encontraron datos de la apuesta.');
              }
              final apuestaDoc = snapshot.data!.docs.first;
              final apuesta = apuestaDoc.data() as Map<String, dynamic>?;
              if (apuesta == null) {
                return Text('No se encontraron datos de la apuesta.');
              }

              final bote = apuesta['bote'];
              final equipoLocal = apuesta['equipo_local'];
              final equipoVisitante = apuesta['equipo_visitante'];
              final nombrePartido = apuesta['nombre_partido'];
              final usuarios = apuesta['usuarios'] as List<dynamic>?;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Resultados para: ${widget.nombreApuesta}',
                    style: const TextStyle(fontSize: 24, color: Colors.indigo),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Bote: $bote',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Nombre del Partido: $nombrePartido',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'EQUIPO LOCAL',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Image.network(
                              escudosEquipos.isNotEmpty ? escudosEquipos[0] : '',
                              width: 50,
                              height: 50,
                            ),
                            Text(
                              equipoLocal,
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'vs',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'EQUIPO VISITANTE',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Image.network(
                              escudosEquipos.isNotEmpty ? escudosEquipos[1] : '',
                              width: 50,
                              height: 50,
                            ),
                            Text(
                              equipoVisitante,
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (resultadosMesAnterior.length == 1) ...[
                    SizedBox(height: 10),
                    Text(
                      'Resultado: ${resultadosMesAnterior[0]['score']['fullTime']['homeTeam']} - ${resultadosMesAnterior[0]['score']['fullTime']['awayTeam']}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                  SizedBox(height: 20),
                  Text(
                    'Jugadores:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  if (usuarios != null)
                    Column(
                      children: usuarios.map<Widget>((user) {
                        final cantidadApostada = user['cantidad_apostada'];
                        final golesLocal = user['goles-local'];
                        final golesVisitante = user['goles-visitante'];
                        final nombreUsuario = user['nombre'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usuario: $nombreUsuario',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Resultado: $golesLocal - $golesVisitante',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Apuesta: $cantidadApostada',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
