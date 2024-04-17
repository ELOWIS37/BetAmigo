import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialWidget extends StatefulWidget {
  @override
  _SocialWidgetState createState() => _SocialWidgetState();
}

class _SocialWidgetState extends State<SocialWidget> {
  List<String> amigos = [];
  List<Map<String, dynamic>> grupos = [];
  late String? usuarioActualId;

  TextEditingController _amigoController = TextEditingController();
  TextEditingController _grupoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Social y Amigos'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Amigos'),
              Tab(text: 'Grupos'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmigosTab() {
    return Padding(
      padding: EdgeInsets.all(16.0),
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
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _agregarAmigo(_amigoController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              textStyle: TextStyle(color: Colors.black),
            ),
            child: Text('Añadir Amigo'),
          ),
          SizedBox(height: 20),
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
                    margin: EdgeInsets.symmetric(vertical: 8.0),
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
      padding: EdgeInsets.all(16.0),
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

  void _agregarAmigo(String amigo) {
    if (amigos.contains(amigo)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('El amigo ya ha sido añadido.'),
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
      FirebaseFirestore.instance.collection('users')
        .where('user', isEqualTo: amigo)
        .get()
        .then((QuerySnapshot querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            setState(() {
              amigos.add(amigo);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Se ha añadido a $amigo como amigo.'),
                duration: Duration(seconds: 2),
              ),
            );
            FirebaseFirestore.instance.collection('users').doc(usuarioActualId).update({
              'amigos': FieldValue.arrayUnion([amigo])
            });
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Error'),
                  content: Text('El usuario no existe.'),
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
        });
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
    if (nombreGrupo.isNotEmpty && amigosSeleccionados.isNotEmpty) {
      setState(() {
        grupos.add({
          'nombre': nombreGrupo,
          'miembros': List<String>.from(amigosSeleccionados),
        });
        _grupoController.clear();
      });
      // Guardar el grupo en Firestore
      FirebaseFirestore.instance.collection('grupos').add({
        'nombre': nombreGrupo,
        'miembros': amigosSeleccionados,
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
          _mostrarDialogoError('El usuario no tiene una imagen de perfil.');
        }
      } else {
        _mostrarDialogoError('El usuario no existe.');
      }
    });
  }

  void _mostrarDialogoError(String mensaje) {
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




  void main() {
    runApp(MaterialApp(
      title: 'Social App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SocialWidget(),
    ));
  }
}