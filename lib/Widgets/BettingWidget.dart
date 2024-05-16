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
  List<String> grupos = [];
  String? selectedGroup;
  TextEditingController _nombreApuestaController = TextEditingController();
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
                          return _mostrarApostarDialog(context, index);
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

Widget _mostrarApostarDialog(BuildContext context, int index) {
  TextEditingController _cantidadController = TextEditingController();
  TextEditingController _golesLocalController = TextEditingController();
  TextEditingController _golesVisitanteController = TextEditingController();

  return AlertDialog(
    title: Text('Introduce tu apuesta'),
    content: Container(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _golesLocalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Goles Locales',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, introduce una cantidad';
              }
              if (int.tryParse(value) == null) {
                return 'Por favor, introduce un número válido';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _golesVisitanteController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Goles Visitantes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, introduce una cantidad';
              }
              if (int.tryParse(value) == null) {
                return 'Por favor, introduce un número válido';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _cantidadController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cantidad Apostada',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, introduce una cantidad';
              }
              if (int.tryParse(value) == null) {
                return 'Por favor, introduce un número válido';
              }
              int cantidad = int.tryParse(value)!;
              if (cantidad <= 0) {
                return 'La cantidad apostada debe ser mayor que cero';
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
          // Obtener el nombre de usuario actual
          String? usuarioActualEmail = FirebaseAuth.instance.currentUser?.email;
          if (usuarioActualEmail != null) {
            FirebaseFirestore.instance.collection('users').where('email', isEqualTo: usuarioActualEmail).get().then((usersSnapshot) {
              if (usersSnapshot.docs.isNotEmpty) {
                String usuarioActualNombre = usersSnapshot.docs.first.get('user');
                // Obtener la apuesta correspondiente al usuario actual
                String nombreApuesta = apuestas[index];
                FirebaseFirestore.instance.collection('apuestas').where('nombre', isEqualTo: nombreApuesta).get().then((apuestasSnapshot) {
                  if (apuestasSnapshot.docs.isNotEmpty) {
                    List<dynamic> usuarios = apuestasSnapshot.docs.first['usuarios'];
                    // Encontrar el usuario actual en la lista de usuarios de la apuesta
                    Map<String, dynamic>? usuarioActual = usuarios.firstWhere((usuario) => usuario['nombre'] == usuarioActualNombre, orElse: () => null);
                    if (usuarioActual != null) {
                      int cantidadApostada = usuarioActual['cantidad-apostada'];
                      if (cantidadApostada != 0) {
              showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Ya se ha realizado una apuesta'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
                      } else {
                        _guardarApuesta(index, _golesLocalController.text, _golesVisitanteController.text, _cantidadController.text);
                        Navigator.of(context).pop();
                      }
                    } else {
                      print('No se encontró el usuario actual en la lista de usuarios de la apuesta');
                    }
                  } else {
                    print('No se encontró ninguna apuesta con el nombre $nombreApuesta');
                  }
                }).catchError((error) {
                  print('Error al obtener la apuesta: $error');
                });
              } else {
                print('No se encontró ningún usuario con el correo electrónico $usuarioActualEmail');
              }
            }).catchError((error) {
              print('Error al obtener el usuario actual: $error');
            });
          } else {
            print('No hay ningún usuario autenticado');
          }
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


void _guardarApuesta(int index, String golesLocal, String golesVisitante, String cantidad) {
  String? usuarioActualEmail = FirebaseAuth.instance.currentUser?.email;
  if (usuarioActualEmail != null) {
    FirebaseFirestore.instance.collection('users').where('email', isEqualTo: usuarioActualEmail).get().then((usersSnapshot) {
      if (usersSnapshot.docs.isNotEmpty) {
        String usuarioActualNombre = usersSnapshot.docs.first.get('user');
        String nombreApuesta = apuestas[index]; // Nombre de la apuesta seleccionada
        
        // Construir el objeto de apuesta
        Map<String, dynamic> apuesta = {
          'nombre': usuarioActualNombre,
          'goles-local': int.parse(golesLocal),
          'goles-visitante': int.parse(golesVisitante),
          'cantidad-apostada': int.parse(cantidad),
        };

        // Buscar y actualizar la apuesta del usuario en la colección 'apuestas'
        FirebaseFirestore.instance.collection('apuestas').where('nombre', isEqualTo: nombreApuesta).get().then((apuestasSnapshot) {
          if (apuestasSnapshot.docs.isNotEmpty) {
            apuestasSnapshot.docs.forEach((apuestaDoc) {
              List<dynamic> usuarios = apuestaDoc['usuarios'];   
              for (int i = 0; i < usuarios.length; i++) {
                if (usuarios[i]['nombre'] == usuarioActualNombre) {
                  // Mostrar los valores actuales antes de actualizar
                  print('Valores actuales antes de actualizar:');
                  print('Nombre: ${usuarios[i]['nombre']}');
                  print('Goles local: ${usuarios[i]['goles-local']}');
                  print('Goles visitante: ${usuarios[i]['goles-visitante']}');
                  print('Cantidad apostada: ${usuarios[i]['cantidad-apostada']}');

                  usuarios[i]['goles-local'] = int.parse(golesLocal);
                  usuarios[i]['goles-visitante'] = int.parse(golesVisitante);
                  usuarios[i]['cantidad-apostada'] = int.parse(cantidad);
                  apuestaDoc.reference.update({'usuarios': usuarios}).then((_) {
                    print('Apuesta actualizada exitosamente para el usuario $usuarioActualNombre');
                  }).catchError((error) {
                    print('Error al actualizar la apuesta: $error');
                  });

                  // Mostrar los nuevos valores actualizados
                  print('Nuevos valores después de la actualización:');
                  print('Nombre: ${usuarios[i]['nombre']}');
                  print('Goles local: ${usuarios[i]['goles-local']}');
                  print('Goles visitante: ${usuarios[i]['goles-visitante']}');
                  print('Cantidad apostada: ${usuarios[i]['cantidad-apostada']}');
                  
                  // Agregar la cantidad apostada al campo 'bote' del documento
                  int actualBote = apuestaDoc['bote'] ?? 0;
                  int cantidadApostada = int.parse(cantidad);
                  int nuevoBote = actualBote + cantidadApostada;
                  apuestaDoc.reference.update({'bote': nuevoBote}).then((_) {
                    print('Bote actualizado exitosamente para la apuesta $nombreApuesta');
                  }).catchError((error) {
                    print('Error al actualizar el bote: $error');
                  });

                  // Descontar los betCoins del usuario
                 final int nuevoSaldo = usersSnapshot.docs.first.data()['betCoins'] - cantidadApostada;
                  if (nuevoSaldo >= 0) {
                    usersSnapshot.docs.first.reference.update({'betCoins': nuevoSaldo}).then((_) {
                      print('betCoins actualizados exitosamente para el usuario $usuarioActualNombre');
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error al actualizar los betCoins del usuario: $error'),
                        backgroundColor: Colors.red,
                      ));
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('El usuario no tiene suficientes betCoins para realizar esta apuesta.'),
                      backgroundColor: Colors.red,
                    ));
                  }

                  return;
                }
              }
            });
          } else {
            print('No se encontraron apuestas con el nombre $nombreApuesta');
          }
        }).catchError((error) {
          print('Error al obtener las apuestas: $error');
        });
      } else {
        print('No se encontró ningún usuario con el correo electrónico $usuarioActualEmail');
      }
    }).catchError((error) {
      print('Error al obtener el usuario: $error');
    });
  } else {
    print('No hay ningún usuario autenticado');
  }
}


 void _crearNuevaApuesta() async {
  if (_nombreApuestaController.text.isNotEmpty && selectedGroup != null && selectedLeague != null && selectedMatch != null) {
    try {
      // Verificar si ya existe una apuesta con el mismo nombre en el grupo seleccionado
      final existingApuestasSnapshot = await FirebaseFirestore.instance.collection('apuestas')
          .where('nombre', isEqualTo: _nombreApuestaController.text)
          .where('grupo', isEqualTo: selectedGroup)
          .limit(1)
          .get();

      if (existingApuestasSnapshot.docs.isNotEmpty) {
        // Si ya existe una apuesta con el mismo nombre en el grupo, mostrar un mensaje de error
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Ya existe una apuesta con el mismo nombre en el grupo seleccionado.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      // Continuar con la creación de la nueva apuesta si no existe una con el mismo nombre
      final groupSnapshot = await FirebaseFirestore.instance.collection('grupos').where('nombre', isEqualTo: selectedGroup).limit(1).get();

        if (groupSnapshot.docs.isNotEmpty) {
          // Obtener el documento del grupo
          final groupDoc = groupSnapshot.docs.first;

          // Obtener los usuarios del grupo
          final List<dynamic> members = groupDoc.data()?['miembros'];

          // Crear la lista de usuarios con sus apuestas
          final List<Map<String, dynamic>> usuariosConApuestas = members.map((member) {
            return {
              'nombre': member,
              'goles-local': 0,
              'goles-visitante': 0,
              'cantidad-apostada': 0,
            };
          }).toList();

        final nuevaApuestaRef = await FirebaseFirestore.instance.collection('apuestas').add({
          'bote': 0,
          'equipo_local': selectedMatch!.split(' vs ')[0],
          'equipo_visitante': selectedMatch!.split(' vs ')[1],
          'nombre': _nombreApuestaController.text,
          'grupo': selectedGroup,
          'usuarios': usuariosConApuestas,
        });

        setState(() {
          final nuevaApuesta = '${_nombreApuestaController.text}';
          apuestas.add(nuevaApuesta);
          // Limpiar las variables y los campos de texto
          _nombreApuestaController.clear();
          selectedGroup = null;
          selectedLeague = null;
          selectedMatch = null;
        });

        print('Apuesta creada exitosamente');
      } else {
        print('No se encontró el grupo $selectedGroup en la base de datos');
      }
    } catch (error) {
      print('Error al crear la apuesta: $error');
    }
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
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            widget.nombreApuesta,
            style: const TextStyle(fontSize: 16, color: Colors.indigo),
          ),
        ),
      ),
    );
  }
}
