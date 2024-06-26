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
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  List<String> escudosEquipos = [];
  List<dynamic> resultadosMesAnterior = [];
  bool isLoading = true; // Variable para controlar el estado de carga

  @override
  void initState() {
    super.initState();
    obtenerDatos();
  }

  Future<void> obtenerDatos() async {
    try {
      await obtenerResultadosMesAnterior();
    } catch (error) {
      print('Error al obtener los datos: $error');
    } finally {
      setState(() {
        isLoading = false; // Detener la carga cuando se obtienen los datos
      });
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

  void reclamarRecompensa() async {
    try {
      final partido = resultadosMesAnterior.isNotEmpty ? resultadosMesAnterior[0] : null;
      if (partido == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay partidos disponibles para reclamar recompensa.'),
          ),
        );
        return;
      }

      final golesLocalPartido = partido['score']['fullTime']['homeTeam'];
      final golesVisitantePartido = partido['score']['fullTime']['awayTeam'];
      final nombreGrupo = widget.nombreApuesta;

      final apuestaCobrada = await verificarApuestaCobrada(nombreGrupo);
      if (apuestaCobrada) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Esta apuesta ya ha sido cobrada.'),
          ),
        );
        return;
      }

      List<String> ganadores = [];
      final snapshot = await FirebaseFirestore.instance
          .collection('apuestas')
          .where('nombre', isEqualTo: nombreGrupo)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No se encontraron apuestas para este grupo.');
        return;
      }

      snapshot.docs.forEach((apuestaDoc) {
        final apuesta = apuestaDoc.data() as Map<String, dynamic>;
        final usuarios = apuesta['usuarios'] as List<dynamic>;

        usuarios.forEach((usuario) {
          final golesLocalUsuario = usuario['goles-local'];
          final golesVisitanteUsuario = usuario['goles-visitante'];
          if (golesLocalUsuario == golesLocalPartido && golesVisitanteUsuario == golesVisitantePartido) {
            ganadores.add(usuario['nombre']);
          }
        });
      });

      if (ganadores.isEmpty) {
        print('No hay ganadores para reclamar la recompensa.');
        return;
      }

      final bote = await obtenerBote();
      final cantidadPorUsuario = bote / ganadores.length;

      for (String ganador in ganadores) {
        await FirebaseFirestore.instance
            .collection('users')
            .where('user', isEqualTo: ganador)
            .get()
            .then((QuerySnapshot querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            final userRef = FirebaseFirestore.instance.collection('users').doc(doc.id);
            userRef.update({'betCoins': FieldValue.increment(cantidadPorUsuario)});
          });
        });
      }

      await marcarApuestaComoCobrada(nombreGrupo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Apuesta cobrada con éxito!'),
        ),
      );

      print('Recompensa reclamada con éxito.');
    } catch (error) {
      print('Error al reclamar la recompensa: $error');
    }
  }

  Future<bool> verificarApuestaCobrada(String nombreApuesta) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('apuestas')
          .where('nombre', isEqualTo: nombreApuesta)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No se encontraron datos de la apuesta.');
        return false;
      }

      final apuestaDoc = snapshot.docs.first;
      final apuesta = apuestaDoc.data() as Map<String, dynamic>;
      final cobrado = apuesta['cobrado'] as String?;

      return cobrado == 'si';
    } catch (error) {
      print('Error al verificar si la apuesta está cobrada: $error');
      return false;
    }
  }

  Future<double> obtenerBote() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('apuestas')
          .where('nombre', isEqualTo: widget.nombreApuesta)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No se encontraron datos de la apuesta.');
        return 0.0;
      }

      final apuestaDoc = snapshot.docs.first;
      final apuesta = apuestaDoc.data() as Map<String, dynamic>;
      final bote = apuesta['bote'] as double;

      return bote;
    } catch (error) {
      print('Error al obtener el bote de la apuesta: $error');
      return 0.0;
    }
  }

  Future<void> marcarApuestaComoCobrada(String nombreApuesta) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('apuestas')
          .where('nombre', isEqualTo: nombreApuesta)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No se encontraron datos de la apuesta.');
        return;
      }

      final apuestaDoc = snapshot.docs.first;
      await apuestaDoc.reference.update({'cobrado': 'si'});
      _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text('Apuesta cobrada con éxito.')));

    } catch (error) {
      print('Error al marcar la apuesta como cobrada: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Resultados para: ${widget.nombreApuesta}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('apuestas').where('nombre', isEqualTo: widget.nombreApuesta).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No se encontraron datos de la apuesta.'));
                        }
                        final apuestaDoc = snapshot.data!.docs.first;
                        final apuesta = apuestaDoc.data() as Map<String, dynamic>?;
                        if (apuesta == null) {
                          return Center(child: Text('No se encontraron datos de la apuesta.'));
                        }

                        final bote = apuesta['bote'];
                        final equipoLocal = apuesta['equipo_local'];
                        final equipoVisitante = apuesta['equipo_visitante'];
                        final usuarios = apuesta['usuarios'] as List<dynamic>?;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.amber.withOpacity(0.3),
                                boxShadow: [
                                  BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 3, blurRadius: 7, offset: Offset(0, 3)),
                                ],
                              ),
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Text(
                                    'Bote: $bote',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Card(
                                    elevation: 3,
                                    color: Colors.blue.withOpacity(0.3),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            'EQUIPO LOCAL',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            equipoLocal,
                                            style: TextStyle(fontSize: 18, color: Colors.white),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  'vs',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Card(
                                    elevation: 3,
                                    color: Colors.red.withOpacity(0.3),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            'EQUIPO VISITANTE',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            equipoVisitante,
                                            style: TextStyle(fontSize: 18, color: Colors.white),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            // Mostrar resultados del partido
                            if (resultadosMesAnterior.isNotEmpty)
                              Column(
                                children: resultadosMesAnterior.map((partido) {
                                  final golesLocal = partido['score']['fullTime']['homeTeam'];
                                  final golesVisitante = partido['score']['fullTime']['awayTeam'];
                                  return Card(
                                    elevation: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'Resultado Final:',
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            '$equipoLocal $golesLocal - $golesVisitante $equipoVisitante',
                                            style: TextStyle(fontSize: 18, color: Colors.black),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            SizedBox(height: 20),
                            Text(
                              'Participantes:',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            if (usuarios != null)
                              Column(
                                children: usuarios.map<Widget>((user) {
                                  final cantidadApostada = user['cantidad-apostada'];
                                  final golesLocal = user['goles-local'];
                                  final golesVisitante = user['goles-visitante'];
                                  final nombreUsuario = user['nombre'];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Card(
                                      elevation: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              'Usuario: $nombreUsuario',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Resultado: $golesLocal - $golesVisitante',
                                              style: TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Apuesta: $cantidadApostada',
                                              style: TextStyle(fontSize: 16, color: Colors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: resultadosMesAnterior.length == 1
          ? FloatingActionButton(
              onPressed: reclamarRecompensa,
              child: Icon(Icons.emoji_events),
            )
          : null,
    );
  }
}
