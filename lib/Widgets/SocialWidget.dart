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
  late String? usuarioActualId; // Variable para almacenar el ID del usuario actual

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
              // Color del texto del botón
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
              // Color del texto del botón
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
      // El amigo ya está en la lista
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
            // El amigo existe en Firestore
            setState(() {
              amigos.add(amigo);
            });
            // Mostrar mensaje informativo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Se ha añadido a $amigo como amigo.'),
                duration: Duration(seconds: 2),
              ),
            );
            // Agregar amigo al usuario actual en Firestore
            FirebaseFirestore.instance.collection('users').doc(usuarioActualId).update({
              'amigos': FieldValue.arrayUnion([amigo])
            });
          } else {
            // El amigo no existe en Firestore
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
          // El usuario no tiene una URL de imagen de perfil
          _mostrarDialogoError('El usuario no tiene una imagen de perfil.');
        }
      } else {
        // El amigo no existe en Firestore
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
    // Eliminar amigo del usuario actual en Firestore
    FirebaseFirestore.instance.collection('users').doc(usuarioActualId).update({
      'amigos': FieldValue.arrayRemove([amigo])
    });
  }

  @override
  void initState() {
    super.initState();
    _obtenerUsuarioActual();
    _cargarAmigosUsuario(); // Cargar amigos del usuario al iniciar la aplicación
  }

  void _obtenerUsuarioActual() {
    // Obtener el ID del usuario actual desde Firebase Authentication
    usuarioActualId = FirebaseAuth.instance.currentUser?.uid;
  }

  void _cargarAmigosUsuario() {
    // Cargar la lista de amigos del usuario desde Firestore
    FirebaseFirestore.instance.collection('users').doc(usuarioActualId).get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          amigos = List<String>.from((documentSnapshot.data() as Map<String, dynamic>)['amigos']);
        });
      }
    });
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
