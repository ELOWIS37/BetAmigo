import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:betamigo/Screens/Authentication/SignInScreen.dart';
import 'package:betamigo/Widgets/BettingWidget.dart';
import 'package:betamigo/Widgets/LeagueSelectionWidget.dart';
import 'package:betamigo/Widgets/SocialWidget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late String _profileImageId = '';
  final List<String> _imageIds = [
    'usuario1',
    'usuario2',
    'usuario3',
    'usuario4',
    'usuario5',
    'usuario6',
    'usuario7',
    'usuario8',
    'usuario9',
    'usuario10',
    'usuario11',
    'usuario12',
    'usuario13',
    'usuario14',
    'usuario15'
  ];

  static final List<Widget> _widgetOptions = <Widget>[
    LeagueSelectionWidget(),
    SocialWidget(),
    BettingWidget(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImageId();
  }

  Future<void> _loadProfileImageId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userData =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String profileImageId = userData.get('profileImageid');
      setState(() {
        _profileImageId = profileImageId.isNotEmpty ? profileImageId : 'usuario1';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _onItemTapped(0),
              child: Row(
                children: [
                  Icon(Icons.sports_soccer, color: _selectedIndex == 0 ? Colors.blue : Colors.black),
                  if (!isSmallScreen) ...[
                    SizedBox(width: 4),
                    Text('Ligas y Partidos',
                        style: TextStyle(color: _selectedIndex == 0 ? Colors.blue : Colors.black)),
                  ]
                ],
              ),
            ),
            SizedBox(width: 16),
            GestureDetector(
              onTap: () => _onItemTapped(1),
              child: Row(
                children: [
                  Icon(Icons.group, color: _selectedIndex == 1 ? Colors.blue : Colors.black),
                  if (!isSmallScreen) ...[
                    SizedBox(width: 4),
                    Text('Social y Amigos',
                        style: TextStyle(color: _selectedIndex == 1 ? Colors.blue : Colors.black)),
                  ]
                ],
              ),
            ),
            SizedBox(width: 16),
            GestureDetector(
              onTap: () => _onItemTapped(2),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: _selectedIndex == 2 ? Colors.blue : Colors.black),
                  if (!isSmallScreen) ...[
                    SizedBox(width: 4),
                    Text('Apuestas Virtuales',
                        style: TextStyle(color: _selectedIndex == 2 ? Colors.blue : Colors.black)),
                  ]
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: ListTile(
                    title: Text('Perfil'),
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileDialog(context);
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    title: Text('Cerrar Sesión'),
                    onTap: () {
                      Navigator.pop(context);
                      _signOut(context);
                    },
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showProfileDialog(context),
                    child: CircleAvatar(
                      radius: 40,
                      // Utilizamos la ruta local almacenada en _profileImageId para cargar la imagen de perfil
                      backgroundImage: _profileImageId.isNotEmpty ? AssetImage('assets/imagenuser/$_profileImageId.png') : null,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('Cerrar Sesión'),
              onTap: () {
                _signOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }

Future<void> _showProfileDialog(BuildContext context) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    List<String> imageIds = _imageIds;

    DocumentSnapshot<Map<String, dynamic>> userData =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    String username = userData.get('user');
    String email = userData.get('email');
    String profileImageId = userData.get('profileImageid'); // Obtener la URL de la imagen de perfil

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedImageId = _profileImageId;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Perfil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        backgroundImage: profileImageId.isNotEmpty ? NetworkImage(profileImageId) : null, // Mostrar la imagen de perfil almacenada en Firebase
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username: $username'),
                          SizedBox(height: 8),
                          Text('Email: $email'),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('Selecciona tu imagen de perfil:'),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: imageIds.map((imageId) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImageId = imageId;
                          });
                          _pickAndSetImage(imageId); // Actualiza la imagen de perfil cuando se selecciona una imagen
                        },
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: imageId == selectedImageId ? Colors.blue : Colors.transparent,
                              width: 4,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.transparent,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/imagenuser/$imageId.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _profileImageId = selectedImageId;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInScreen()));
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Este método guarda la ruta local de la imagen seleccionada en Firestore
Future<void> _pickAndSetImage(String imageId) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      String imagePath = 'assets/imagenuser/$imageId.png';

      // Obtenemos los datos actuales del usuario
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      // Copiamos todos los datos actuales del usuario
      Map<String, dynamic> updatedUserData = userData.data() ?? {};
      // Actualizamos el campo profileImageid
      updatedUserData['profileImageid'] = imagePath;

      // Actualizamos solo el campo profileImageid en Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updatedUserData);

      setState(() {
        _profileImageId = imagePath; // Actualiza la URL de la imagen de perfil en el estado local
      });
    } catch (e) {
      print('Error setting image: $e');
    }
  }
}


void main() {
  runApp(MaterialApp(
    title: 'Bet Amigo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: MainScreen(),
  ));
}
}
