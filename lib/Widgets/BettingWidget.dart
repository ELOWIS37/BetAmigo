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
  String? selectedMatch; 
  List<String> matches = [];
  List<String> grupos = []; // Lista para almacenar los grupos del usuario
  String? selectedGroup; // Variable para almacenar el grupo seleccionado
  final TextEditingController _nombreApuestaController = TextEditingController();
  final TextEditingController _equipo1Controller = TextEditingController();
  final TextEditingController _equipo2Controller = TextEditingController();
  List<String> grupos = [];
  String? selectedGroup;
  TextEditingController _nombreApuestaController = TextEditingController();
  DateTime? _fechaSeleccionada;
  Map<String, List<String>> leagueMatchesMap = {};
  int apuestaMinima = 10;
  int apuestaMaxima = 200;
  List<String> apuestas = [];

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
    _fetchMatchesForAllLeagues(); 
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
      leagueMatchesMap[leagueCode] = leagueMatches;
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
        // Si el usuario está dentro de algún grupo, carga las apuestas del primer grupo
        selectedGroup = grupos.first;
        _fetchGroupBets(selectedGroup!);
      });
    }
  }
}
Future<void> _fetchGroupBets(String groupName) async {
  final groupBetsSnapshot = await FirebaseFirestore.instance.collection('apuestas').where('grupo', isEqualTo: groupName).get();
  setState(() {
    apuestas = groupBetsSnapshot.docs.map((doc) => doc.data()['nombre'] as String).toList();
  });
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apuestas Virtuales'),
        backgroundColor: Colors.indigo, 
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¡Crea tu Apuesta!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo), 
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return _mostrarSeleccionApuesta(context);
                  },
                );
              },
              child: Text('Crear Apuesta', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo, 
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Apuestas Recientes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo), 
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: apuestas.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return _mostrarApostarDialog(context);
                        },
                      );
                    },
                    child: AnimatedApuesta(
                      nombreApuesta: apuestas[index],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mostrarSeleccionApuesta(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AlertDialog(
          title: Text('Nueva Apuesta'),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedGroup,
                    decoration: InputDecoration(
                      labelText: 'Grupo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedLeague,
                    decoration: InputDecoration(
                      labelText: 'Liga',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                        matches = leagueMatchesMap[leagueCodes[selectedLeagueValue ?? '']] ?? [];
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
                            labelText: 'Partido',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
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
                  Text(
                    'Apuesta Mínima: $apuestaMinima',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Apuesta Máxima: $apuestaMaxima',
                    style: TextStyle(fontSize: 16),
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.indigo,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _crearNuevaApuesta();
                Navigator.of(context).pop();
              },
              child: Text('Aceptar', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _mostrarApostarDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Introduce tu apuesta'),
      content: Container(
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, introduce una cantidad';
                }
                int cantidad = int.tryParse(value)!;
                if (cantidad < apuestaMinima || cantidad > apuestaMaxima) {
                  return 'La cantidad debe estar entre $apuestaMinima y $apuestaMaxima';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancelar'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.indigo,
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Apostar', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  void _crearNuevaApuesta() {
    if (_nombreApuestaController.text.isNotEmpty && selectedGroup != null && selectedLeague != null && selectedMatch != null) {
      FirebaseFirestore.instance.collection('apuestas').add({
        'bote': 0,
        'equipo_local': selectedMatch!.split(' vs ')[0],
        'equipo_visitante': selectedMatch!.split(' vs ')[1],
        'nombre': _nombreApuestaController.text,
        'grupo': selectedGroup,
      }).then((value) {
        setState(() {
          final nuevaApuesta =
              '${_nombreApuestaController.text} - Grupo: $selectedGroup - Liga: $selectedLeague - Partido: $selectedMatch';
          apuestas.add(nuevaApuesta);
        });
        // Mostrar mensaje de éxito o realizar otras acciones si es necesario
        print('Apuesta creada exitosamente');
      }).catchError((error) {
        // Manejar errores si la creación de la apuesta falla
        print('Error al crear la apuesta: $error');
      });
    }
  }
}

class AnimatedApuesta extends StatefulWidget {
  final String nombreApuesta;

  const AnimatedApuesta({Key? key, required this.nombreApuesta}) : super(key: key);

  @override
  _AnimatedApuestaState createState() => _AnimatedApuestaState();
}

class _AnimatedApuestaState extends State<AnimatedApuesta> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animationOffsetIn;
  late Animation<Offset> _animationOffsetOut;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationOffsetIn = Tween<Offset>(
      begin: Offset(2, 0),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationOffsetOut = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(-2, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animationOffsetIn,
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            widget.nombreApuesta,
            style: TextStyle(fontSize: 16, color: Colors.indigo),
          ),
        ),
      ),
    );
  }
}
