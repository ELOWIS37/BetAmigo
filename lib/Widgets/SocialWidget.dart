import 'package:betamigo/Screens/chat.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';


void main() {
  runApp(MaterialApp(
    title: 'Social App',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const SocialWidget(),
  ));
}

class SocialWidget extends StatefulWidget {
  const SocialWidget({super.key});

  @override
  _SocialWidgetState createState() => _SocialWidgetState();
}

class _SocialWidgetState extends State<SocialWidget> {
  List<String> amigos = [];
  List<Map<String, dynamic>> grupos = [];
  List<String> solicitudes = [];
  late String? usuarioActualId;

  final TextEditingController _amigoController = TextEditingController();
  final TextEditingController _grupoController = TextEditingController();


void _aceptarSolicitud(String from) {
  String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Agregar al amigo a la lista de amigos del usuario actual
  FirebaseFirestore.instance.collection('users').doc(usuarioActualId).update({
    'amigos': FieldValue.arrayUnion([from])
  }).catchError((error) {
    print('Error al agregar el amigo: $error');
  });

  // Buscar al usuario por nombre y agregar al usuario actual a su lista de amigos
  FirebaseFirestore.instance.collection('users').where('user', isEqualTo: from).get().then((QuerySnapshot querySnapshot) {
    if (querySnapshot.docs.isNotEmpty) {
      String usuarioSolicitudId = querySnapshot.docs.first.id;
      
      // Obtener el nombre del usuario actual
      String nombreUsuarioActual;
      FirebaseFirestore.instance.collection('users').doc(usuarioActualId).get().then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          nombreUsuarioActual = (documentSnapshot.data() as Map<String, dynamic>)['user'] ?? '';
          
          // Actualizar la lista de amigos del usuario que envió la solicitud con el nombre del usuario actual
          FirebaseFirestore.instance.collection('users').doc(usuarioSolicitudId).update({
            'amigos': FieldValue.arrayUnion([nombreUsuarioActual])
          }).catchError((error) {
            print('Error al agregar el amigo al usuario que envió la solicitud: $error');
          });
        }
      });
    } else {
      print('El usuario con nombre $from no existe.');
    }
  });

  // Eliminar la solicitud de amistad pendiente
  FirebaseFirestore.instance.collection('users').doc(usuarioActualId).collection('solicitudes')
    .where('from', isEqualTo: from)
    .get()
    .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
    });

  // Actualizar la lista de solicitudes en la interfaz
  setState(() {
    solicitudes.removeWhere((solicitud) => solicitud == from);
  });
}



Widget _buildSolicitudesTab() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: StreamBuilder<List<String>>(
      stream: _cargarSolicitudes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final solicitudes = snapshot.data ?? [];

        return solicitudes.isEmpty
          ? const Center(
              child: Text(
                'No hay solicitudes de amistad pendientes.',
                style: TextStyle(fontSize: 18.0),
              ),
            )
          : Expanded(
              child: ListView.builder(
                itemCount: solicitudes.length,
                itemBuilder: (context, index) {
                  final solicitud = solicitudes[index];
                  return ListTile(
                    title: Text('Solicitud de amistad de $solicitud'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _aceptarSolicitud(solicitud);
                          },
                          child: const Text('Aceptar'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            _denegarSolicitud(solicitud);
                          },
                          child: const Text('Denegar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
      },
    ),
  );
}

void _denegarSolicitud(String from) {
  String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Eliminar la solicitud de amistad pendiente
  FirebaseFirestore.instance.collection('users').doc(usuarioActualId).collection('solicitudes')
    .where('from', isEqualTo: from)
    .get()
    .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
    });

  // Actualizar la lista de solicitudes en la interfaz
  setState(() {
    solicitudes.removeWhere((solicitud) => solicitud == from);
  });
}




@override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 3, // Ajustar el número de pestañas según sea necesario
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Social y Amigos'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Amigos'),
            Tab(text: 'Grupos'),
            Tab(text: 'Solicitudes'),
          ],
        ),
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
        child: TabBarView(
          children: [
            _buildAmigosTab(),
            _buildGruposTab(),
            _buildSolicitudesTab(),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildAmigosTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _amigoController,
            decoration: InputDecoration(
              hintText: 'Nombre de amigo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _enviarSolicitudAmistad(_amigoController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              textStyle: const TextStyle(color: Colors.black),
            ),
            child: const Text('Enviar Solicitud de Amistad'),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: amigos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _mostrarDetalleAmigo(amigos[index]);
                  },
                  child: Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        amigos[index],
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _buildGruposTab() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Controles para crear un nuevo grupo
        TextField(
          controller: _grupoController,
          decoration: InputDecoration(
            hintText: 'Nombre del grupo',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _mostrarSeleccionAmigos();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(51, 51, 51, 51),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            textStyle: TextStyle(color: Colors.white),
          ),
          child: Text('Agregar Amigos al Grupo'),
        ),
        SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: grupos.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 4.0,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ExpansionTile(
                  title: Text(
                    grupos[index]['nombre'],
                    style: TextStyle(fontSize: 18.0),
                  ),
                  children: _buildGrupoChildren(grupos[index]['miembros']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _eliminarGrupo(grupos[index]['nombre']);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

void _eliminarGrupo(String nombreGrupo) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text('Eliminar Grupo'),
        content: Text('¿Estás seguro de que quieres eliminar el grupo $nombreGrupo?'),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            child: Text('Eliminar'),
            onPressed: () {
              // Elimina el grupo
              _eliminarGrupoConfirmado(nombreGrupo);
              Navigator.of(context).pop(); // Cierra el diálogo
            },
          ),
        ],
      );
    },
  );
}
void _eliminarGrupoConfirmado(String nombreGrupo) {
  setState(() {
    // Elimina el grupo de la lista de grupos
    grupos.removeWhere((grupo) => grupo['nombre'] == nombreGrupo);
  });

  // Busca y elimina el documento del grupo en Firestore
  FirebaseFirestore.instance.collection('grupos').where('nombre', isEqualTo: nombreGrupo).get().then((querySnapshot) {
    querySnapshot.docs.forEach((doc) {
      // Elimina el documento del grupo
      doc.reference.delete().then((value) {
        print('Grupo $nombreGrupo eliminado de la base de datos.');
      }).catchError((error) {
        print('Error al eliminar el grupo de la base de datos: $error');
      });
    });
  }).catchError((error) {
    print('Error al buscar el grupo en la base de datos: $error');
  });
}



  List<Widget> _buildGrupoChildren(List<String> miembros) {
    List<Widget> children = [];
    children.add(
      ListTile(
        title: Text('Miembros:'),
        dense: true,
      ),
    );
    children.addAll(
      miembros.map((miembro) {
        return ListTile(
          title: Text(miembro),
          dense: true,
        );
      }).toList(),
    );
    return children;
  }

  void _enviarSolicitudAmistad(String amigo) {
  if (amigo == FirebaseAuth.instance.currentUser?.displayName) {
    _mostrarError('No puedes enviarte una solicitud de amistad a ti mismo.');
    return;
  }

  if (solicitudes.contains(amigo) || amigos.contains(amigo)) {
    _mostrarError('Ya has enviado una solicitud de amistad a este usuario o ya son amigos.');
    return;
  }

  var user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>? ?? {};

        FirebaseFirestore.instance.collection('users')
          .where('user', isEqualTo: amigo)
          .get()
          .then((QuerySnapshot querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              final userId = querySnapshot.docs.first.id;
              final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

              // Agregar la solicitud de amistad a Firestore
              userRef.collection('solicitudes').add({
                'from': data['user'], // Utiliza el valor del campo 'user' del usuario actual
                'timestamp': DateTime.now(),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Solicitud de amistad enviada a $amigo.'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              _mostrarError('El usuario no existe.');
            }
          });
      } else {
        _mostrarError('No se pudo encontrar el documento del usuario.');
      }
    });
  } else {
    print('No hay ningún usuario conectado.');
  }
}


  void _mostrarSeleccionAmigos() {
    List<String> amigosSeleccionados = [];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Seleccionar Amigos'),
              content: SingleChildScrollView(
                child: Column(
                  children: amigos.map((amigo) {
                    return CheckboxListTile(
                      title: Text(amigo),
                      value: amigosSeleccionados.contains(amigo),
                      onChanged: (bool? seleccionado) {
                        setState(() {
                          if (seleccionado != null && seleccionado) {
                            amigosSeleccionados.add(amigo);
                          } else {
                            amigosSeleccionados.remove(amigo);
                          }
                        });
                      },
                    );
                  }).toList(),
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
                    _crearGrupo(amigosSeleccionados);
                    Navigator.of(context).pop();
                  },
                  child: Text('Crear Grupo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

void _crearGrupo(List<String> amigosSeleccionados) {
  String nombreGrupo = _grupoController.text.trim();
  String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';

  if (nombreGrupo.isNotEmpty && amigosSeleccionados.isNotEmpty) {
    // Obtener el documento del usuario actual
    FirebaseFirestore.instance.collection('users').doc(usuarioActualId).get().then((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
      if (documentSnapshot.exists) {
        String usuarioActual = documentSnapshot.data()?['user'] ?? ''; //  'user' es el campo que contiene el nombre del usuario

        // Verificar si el nombre del grupo es único
        FirebaseFirestore.instance.collection('grupos').where('nombre', isEqualTo: nombreGrupo).get().then((QuerySnapshot querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            // Mostrar un mensaje de error si el nombre del grupo ya existe
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Error'),
                  content: Text('El nombre del grupo ya existe. Por favor, elige otro nombre.'),
                  actions: <Widget>[
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
            // Si el nombre del grupo es único, añadir al usuario actual como miembro y guardar en Firestore
            amigosSeleccionados.add(usuarioActual); // Añadir el nombre del usuario actual como miembro

            // Convertir la lista a una lista mutable
            List<String> miembros = List<String>.from(amigosSeleccionados);

            setState(() {
              grupos.add({
                'nombre': nombreGrupo,
                'miembros': miembros,
              });
              _grupoController.clear();
            });

            // Guardar el grupo en Firestore
            FirebaseFirestore.instance.collection('grupos').add({
              'nombre': nombreGrupo,
              'miembros': miembros,
            });
          }
        });
      }
    });
  } else {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Debes ingresar un nombre para el grupo y seleccionar al menos un amigo.'),
          actions: <Widget>[
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
  }
}
void _mostrarDetalleAmigo(String amigo) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(amigo: amigo),
    ),
  );
}

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(mensaje),
          actions: <Widget>[
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
  }

  void _eliminarAmigo(String amigo) {
    setState(() {
      amigos.remove(amigo);
    });
    FirebaseFirestore.instance.collection('users').doc(usuarioActualId).update({
      'amigos': FieldValue.arrayRemove([amigo])
    });
  }

  @override
  void initState() { 
    super.initState(); 
    _obtenerUsuarioActual(); 
    _cargarAmigosUsuario(); 
    _cargarGrupos(); // Cargar grupos del usuario al iniciar la aplicación
    _cargarSolicitudes(); // Cargar solicitudes de amistad del usuario
  }

  void _obtenerUsuarioActual() {
    usuarioActualId = FirebaseAuth.instance.currentUser?.uid;
  }

  void _cargarAmigosUsuario() {
    FirebaseFirestore.instance.collection('users').doc(usuarioActualId).get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          amigos = List<String>.from((documentSnapshot.data() as Map<String, dynamic>)['amigos']);
        });
      }
    });
  }

  void _cargarGrupos() async {
  // Obtener el nombre de usuario actual
  String? nombreUsuario;
  var user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>? ?? {};
        nombreUsuario = data['user'];
      } else {
        print('No se pudo encontrar el documento del usuario.');
      }
    });
  } else {
    print('No hay ningún usuario conectado.');
  }

  // Verificar si se obtuvo el nombre de usuario
  if (nombreUsuario != null) {
    FirebaseFirestore.instance.collection('grupos').where('miembros', arrayContains: nombreUsuario).get().then((QuerySnapshot querySnapshot) {
      List<Map<String, dynamic>> loadedGrupos = [];
      querySnapshot.docs.forEach((doc) {
        print('Nombre del grupo: ' + doc["nombre"]);
        print('Miembros del grupo: ' + doc["miembros"].join(', '));

        // Agregar el grupo a la lista de grupos cargados
        loadedGrupos.add({
          'nombre': doc["nombre"],
          'miembros': List<String>.from(doc["miembros"]),
        });
      });

      // Actualizar el estado del widget con los grupos cargados
      setState(() {
        grupos = loadedGrupos;
      });
    });
  } else {
    print('No se pudo obtener el nombre de usuario.');
  }
}

  Stream<List<String>> _cargarSolicitudes() {
  return FirebaseFirestore.instance.collection('users').doc(usuarioActualId).collection('solicitudes')
    .snapshots()
    .map((querySnapshot) => querySnapshot.docs.map((doc) => doc['from'] as String).toList());
  }

}