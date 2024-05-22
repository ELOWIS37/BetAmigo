import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'resultadosapuesta.dart';

class BettingWidget extends StatefulWidget {
  @override
  _BettingWidgetState createState() => _BettingWidgetState();
}

class _BettingWidgetState extends State<BettingWidget> {

   // Define tus colores y gradientes aquí
  final Color appBarColor = Colors.indigo;
  final Color buttonColor = Colors.indigo;
  final Color textColor = const Color.fromARGB(255, 0, 0, 0);
  final Color cardColor = Colors.white;
  final Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.lightBlueAccent, Colors.greenAccent],
  );
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
          _fetchUserBets();
        });
      }
    }
  }

Future<void> _fetchUserBets() async {
  String usuarioActualEmail = FirebaseAuth.instance.currentUser?.email ?? '';
  final userSnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: usuarioActualEmail).limit(1).get();

  if (userSnapshot.docs.isNotEmpty) {
    final userName = userSnapshot.docs.first.data()?['user'];
    print('Nombre de usuario: $userName');

    final groupBetsSnapshot = await FirebaseFirestore.instance.collection('apuestas').get();
    
    print('Apuestas encontradas:');
    groupBetsSnapshot.docs.forEach((doc) {
      print('Apuesta: ${doc.data()}');
      List<dynamic> usuarios = doc.data()?['usuarios'];
      print('Usuarios en esta apuesta: $usuarios');
      if (usuarios.any((usuario) => usuario['nombre'] == userName)) {
        print('Usuario encontrado en esta apuesta');
      } else {
        print('Usuario no encontrado en esta apuesta');
      }
    });

    List<String> userBets = [];
    groupBetsSnapshot.docs.forEach((doc) {
      List<dynamic> usuarios = doc.data()?['usuarios'];
      if (usuarios.any((usuario) => usuario['nombre'] == userName)) {
        userBets.add(doc.data()?['nombre'] as String);
      }
    });

    print('Apuestas del usuario: $userBets');

    setState(() {
      apuestas = userBets;
    });
  }
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Apuestas Virtuales',
        style: TextStyle(color: Colors.black), // Color del texto en negro
      ),
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¡Crea tu Apuesta!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
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
              child: Text('Crear Apuesta', style: TextStyle(fontSize: 18, color: Colors.black)), // Cambiar color del texto a negro
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Cambiar el color a blanco
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Apuestas Recientes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Cambiar color del texto a negro
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
          ], // Children of the Column
        ), // Column
      ), // Padding
    ), // Container
  ); // Scaffold
}




  Widget _mostrarSeleccionApuesta(BuildContext context) {
  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return AlertDialog(
        title: const Text('Nueva Apuesta'),
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
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
                if (selectedLeague != null && selectedLeague!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  matches.isNotEmpty ? DropdownButtonFormField<String>(
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
                  ) : const Text(
                    'No hay partidos para esta semana',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _crearNuevaApuesta();
              Navigator.of(context).pop();
            },
            child: const Text('Aceptar', style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 0, 0, 0))),
            style: ElevatedButton.styleFrom(
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
  TextEditingController _cantidadController = TextEditingController(text: '10');
  TextEditingController _golesLocalController = TextEditingController(text: '0');
  TextEditingController _golesVisitanteController = TextEditingController(text: '0');

  void _incrementGoles(TextEditingController controller) {
    int currentValue = int.tryParse(controller.text) ?? 0;
    if (currentValue < 10) {
      controller.text = (currentValue + 1).toString();
    }
  }

  void _decrementGoles(TextEditingController controller) {
    int currentValue = int.tryParse(controller.text) ?? 0;
    if (currentValue > 0) {
      controller.text = (currentValue - 1).toString();
    }
  }

  void _incrementCantidad() {
    int currentValue = int.tryParse(_cantidadController.text) ?? 0;
    if (currentValue < 200) {
      currentValue += 10;
      _cantidadController.text = currentValue.toString();
    }
  }

  void _decrementCantidad() {
    int currentValue = int.tryParse(_cantidadController.text) ?? 0;
    if (currentValue > 10) {
      currentValue -= 10;
      _cantidadController.text = currentValue.toString();
    }
  }

  return Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20.0),
    ),
    backgroundColor: Colors.white,
    elevation: 0.0,
    child: SingleChildScrollView(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Introduce tu apuesta',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () => _decrementGoles(_golesLocalController),
              ),
              Expanded(
                child: TextField(
                  controller: _golesLocalController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18.0),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Goles Locales',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _incrementGoles(_golesLocalController),
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () => _decrementGoles(_golesVisitanteController),
              ),
              Expanded(
                child: TextField(
                  controller: _golesVisitanteController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18.0),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Goles Visitantes',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _incrementGoles(_golesVisitanteController),
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: _decrementCantidad,
              ),
              Expanded(
                child: TextField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18.0),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Cantidad Apostada',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _incrementCantidad,
              ),
            ],
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.grey[200],
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
                child: Text('Apostar', style: TextStyle(color: Colors.black,fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void _guardarApuesta(int index, String golesLocal, String golesVisitante, String cantidad) {
  String? usuarioActualEmail = FirebaseAuth.instance.currentUser?.email;
  if (usuarioActualEmail != null) {
    FirebaseFirestore.instance.collection('users').where('email', isEqualTo: usuarioActualEmail).get().then((usersSnapshot) {
      if (usersSnapshot.docs.isNotEmpty) {
        String usuarioActualNombre = usersSnapshot.docs.first.get('user');
        String nombreApuesta = apuestas[index]; // Nombre de la apuesta seleccionada
        int cantidadApostada = int.parse(cantidad);
        int betCoins = usersSnapshot.docs.first.data()['betCoins']; // Obtener el saldo actual de betCoins

        if (betCoins < cantidadApostada) {
          // Mostrar un mensaje de error si el usuario no tiene suficientes betCoins
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('El usuario no tiene suficientes betCoins para realizar esta apuesta.'),
            backgroundColor: Colors.red,
          ));
          return; // Salir de la función si no tiene suficientes betCoins
        }

        // Construir el objeto de apuesta
        Map<String, dynamic> apuesta = {
          'nombre': usuarioActualNombre,
          'goles-local': int.parse(golesLocal),
          'goles-visitante': int.parse(golesVisitante),
          'cantidad-apostada': cantidadApostada,
        };

        // Buscar y actualizar la apuesta del usuario en la colección 'apuestas'
        FirebaseFirestore.instance.collection('apuestas').where('nombre', isEqualTo: nombreApuesta).get().then((apuestasSnapshot) {
          if (apuestasSnapshot.docs.isNotEmpty) {
            apuestasSnapshot.docs.forEach((apuestaDoc) {
              List<dynamic> usuarios = apuestaDoc['usuarios'];   
              for (int i = 0; i < usuarios.length; i++) {
                if (usuarios[i]['nombre'] == usuarioActualNombre) {
                  usuarios[i]['goles-local'] = int.parse(golesLocal);
                  usuarios[i]['goles-visitante'] = int.parse(golesVisitante);
                  usuarios[i]['cantidad-apostada'] = cantidadApostada;
                  apuestaDoc.reference.update({'usuarios': usuarios}).then((_) {
                    print('Apuesta actualizada exitosamente para el usuario $usuarioActualNombre');
                  }).catchError((error) {
                    print('Error al actualizar la apuesta: $error');
                  });

                  // Agregar la cantidad apostada al campo 'bote' del documento
                  int actualBote = apuestaDoc['bote'] ?? 0;
                  int nuevoBote = actualBote + cantidadApostada;
                  apuestaDoc.reference.update({'bote': nuevoBote}).then((_) {
                    print('Bote actualizado exitosamente para la apuesta $nombreApuesta');
                  }).catchError((error) {
                    print('Error al actualizar el bote: $error');
                  });

                  // Descontar los betCoins del usuario
                  final int nuevoSaldo = betCoins - cantidadApostada;
                  usersSnapshot.docs.first.reference.update({'betCoins': nuevoSaldo}).then((_) {
                    print('betCoins actualizados exitosamente para el usuario $usuarioActualNombre');
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error al actualizar los betCoins del usuario: $error'),
                      backgroundColor: Colors.red,
                    ));
                  });

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
      // Verificar si ya existe una apuesta con el mismo nombre en cualquier grupo
      final existingApuestasSnapshot = await FirebaseFirestore.instance.collection('apuestas')
          .where('nombre', isEqualTo: _nombreApuestaController.text)
          .limit(1)
          .get();

      if (existingApuestasSnapshot.docs.isNotEmpty) {
        // Si ya existe una apuesta con el mismo nombre en cualquier grupo, mostrar un mensaje de error
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Ya existe una apuesta con el mismo nombre.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
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
        final groupDoc = groupSnapshot.docs.first;
        final List<dynamic> members = groupDoc.data()?['miembros'];
        final List<Map<String, dynamic>> usuariosConApuestas = members.map((member) {
          return {
            'nombre': member,
            'goles-local': 0,
            'goles-visitante': 0,
            'cantidad-apostada': 0,
          };
        }).toList();

        final nuevaApuestaRef = await FirebaseFirestore.instance.collection('apuestas').add({
          'nombre_partido': selectedMatch!,
          'bote': 0,
          'cobrado':'no',
          'equipo_local': selectedMatch!.split(' vs ')[0],
          'equipo_visitante': selectedMatch!.split(' vs ')[1],
          'nombre': _nombreApuestaController.text,
          'grupo': selectedGroup,
          'usuarios': usuariosConApuestas,
          'league_code': leagueCodes[selectedLeague!], // Añadir el código de la liga
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
      duration: const Duration(milliseconds: 500),
    );
    _animationOffsetIn = Tween<Offset>(
      begin: const Offset(2, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationOffsetOut = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-2, 0),
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

  void _mostrarResultado() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadosApuesta(nombreApuesta: widget.nombreApuesta),
      ),
    );
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.nombreApuesta,
                style: const TextStyle(fontSize: 16, color: Color.fromARGB(255,67, 199, 249)),
              ),
              IconButton(
                icon: Icon(Icons.emoji_events, color: Color.fromARGB(255, 243, 224, 19)),
                onPressed: _mostrarResultado,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


