import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // void _aceptarSolicitud(String from) {
  //   // Agregar al amigo a la lista de amigos
  //   FirebaseFirestore.instance.collection('users').doc(usuarioActualId).update({
  //     'amigos': FieldValue.arrayUnion([from])
  //   });

  //   // Eliminar la solicitud de amistad pendiente
  //   FirebaseFirestore.instance.collection('users').doc(usuarioActualId).collection('solicitudes')
  //     .where('from', isEqualTo: from)
  //     .get()
  //     .then((QuerySnapshot querySnapshot) {
  //       querySnapshot.docs.forEach((doc) {
  //         doc.reference.delete();
  //       });
  //     });

  //   // Actualizar la lista de solicitudes en la interfaz
  //   setState(() {
  //     solicitudes.removeWhere((solicitud) => solicitud == from);
  //   });
  // }
void _aceptarSolicitud(String from) {
  String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Agregar al amigo a la lista de amigos del usuario actual
  FirebaseFirestore.instance.collection('users').doc(usuarioActualId).update({
    'amigos': FieldValue.arrayUnion([from])
  });

  // Agregar al usuario actual a la lista de amigos del usuario que envió la solicitud
  FirebaseFirestore.instance.collection('users').where('email', isEqualTo: from).get().then((QuerySnapshot querySnapshot) {
    if (querySnapshot.docs.isNotEmpty) {
      String usuarioSolicitudId = querySnapshot.docs.first.id;
      
      FirebaseFirestore.instance.collection('users').doc(usuarioSolicitudId).update({
        'amigos': FieldValue.arrayUnion([usuarioActualId])
      });
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


// Widget _buildSolicitudesTab() {
//   return Padding(
//     padding: const EdgeInsets.all(16.0),
//     child: StreamBuilder<List<String>>(
//       stream: _cargarSolicitudes(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final solicitudes = snapshot.data ?? [];

//         return solicitudes.isEmpty
//           ? const Center(
//               child: Text(
//                 'No hay solicitudes de amistad pendientes.',
//                 style: TextStyle(fontSize: 18.0),
//               ),
//             )
//           : Expanded(
//               child: ListView.builder(
//                 itemCount: solicitudes.length,
//                 itemBuilder: (context, index) {
//                   final solicitud = solicitudes[index];
//                   return ListTile(
//                     title: Text('Solicitud de amistad de $solicitud'),
//                     trailing: ElevatedButton(
//                       onPressed: () {
//                         _aceptarSolicitud(solicitud);
//                       },
//                       child: const Text('Aceptar'),
//                     ),
//                   );
//                 },
//               ),
//             );
//       },
//     ),
//   );
// }

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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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

//   void _crearGrupo(List<String> amigosSeleccionados) {
//   String nombreGrupo = _grupoController.text.trim();
//   String usuarioActual = FirebaseAuth.instance.currentUser?.displayName ?? '';

//   if (nombreGrupo.isNotEmpty && amigosSeleccionados.isNotEmpty) {
//     // Añadir al usuario actual a la lista de amigos seleccionados
//     if (!amigosSeleccionados.contains(usuarioActual)) {
//       amigosSeleccionados.add(usuarioActual);
//     }

//     setState(() {
//       grupos.add({
//         'nombre': nombreGrupo,
//         'miembros': List<String>.from(amigosSeleccionados),
//       });
//       _grupoController.clear();
//     });

//     // Guardar el grupo en Firestore
//     FirebaseFirestore.instance.collection('grupos').add({
//       'nombre': nombreGrupo,
//       'miembros': amigosSeleccionados,
//     });
//   } else {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Error'),
//           content: Text('Debes ingresar un nombre para el grupo y seleccionar al menos un amigo.'),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

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


  // void _crearGrupo(List<String> amigosSeleccionados) {
  //   String nombreGrupo = _grupoController.text.trim();
  //   if (nombreGrupo.isNotEmpty && amigosSeleccionados.isNotEmpty) {
  //     setState(() {
  //       grupos.add({
  //         'nombre': nombreGrupo,
  //         'miembros': List<String>.from(amigosSeleccionados),
  //       });
  //       _grupoController.clear();
  //     });
  //     // Guardar el grupo en Firestore
  //     FirebaseFirestore.instance.collection('grupos').add({
  //       'nombre': nombreGrupo,
  //       'miembros': amigosSeleccionados,
  //     });
  //   } else {
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: Text('Error'),
  //           content: Text('Debes ingresar un nombre para el grupo y seleccionar al menos un amigo.'),
  //           actions: <Widget>[
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               child: Text('OK'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }
  // }

  void _mostrarDetalleAmigo(String amigo) {
    FirebaseFirestore.instance.collection('users')
        .where('user', isEqualTo: amigo)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('profileImageid')) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Detalles de Amigo'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Nombre: $amigo'),
                    SizedBox(height: 10),
                    Image.network(
                      userData['profileImageid'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      _eliminarAmigo(amigo);
                      Navigator.of(context).pop();
                    },
                    child: Text('Eliminar'),
                  ),
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
        } else {
          _mostrarError('El usuario no tiene una imagen de perfil.');
        }
      } else {
        _mostrarError('El usuario no existe.');
      }
    });
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

  // void _cargarSolicitudes() {
  // FirebaseFirestore.instance.collection('users').doc(usuarioActualId).collection('solicitudes').get().then((QuerySnapshot querySnapshot) {
  //   if (querySnapshot.docs.isNotEmpty) {
  //     setState(() {
  //       solicitudes = querySnapshot.docs.map((doc) => doc['from'] as String).toList();
  //     });
  //   }
  // });

  Stream<List<String>> _cargarSolicitudes() {
  return FirebaseFirestore.instance.collection('users').doc(usuarioActualId).collection('solicitudes')
    .snapshots()
    .map((querySnapshot) => querySnapshot.docs.map((doc) => doc['from'] as String).toList());
  }

}

