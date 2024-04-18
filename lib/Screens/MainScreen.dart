import 'dart:io';

import 'package:betamigo/Widgets/TiendaWidget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:betamigo/Screens/Authentication/SignInScreen.dart';
import 'package:betamigo/Widgets/BettingWidget.dart';
import 'package:betamigo/Widgets/LeagueSelectionWidget.dart';
import 'package:betamigo/Widgets/SocialWidget.dart';
import 'package:betamigo/Widgets/BetCoinWidget.dart'; // Importa el widget BetCoinWidget

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key});

  @override
  _MainScreenState createState() => _MainScreenState();
}
// PUEDE...DEJAR LA PAGINA PRINCIPAL MAS BONITA??? OOOOO YA SE YA SE, SBS CUANDO ENTRAS EN UNA LIGA, EN UN PARTIDO...QUE SALE EL CUADRO BLANCO? PUES QUE AHI PONGA LO DE LAS IMAGENES Y QUE LO DEJE GUAPO Y QUITE LO DEL SHEDULED NO DEL NULL - NULL...
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late String _profileImageId = '';
  late int _betCoins = 0; // Agrega una variable para almacenar los BetCoins
  late ValueNotifier<int> _betCoinsNotifier; // Nuevo ValueNotifier

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

  final List<String> _imageTeamIds = [
    'barcelona',
    'madrid',
    'atleticoMadrid',
    'girona',
    'chelsea',
    'liverpool',
    'city',
    'united',
    'arsenal',
    'leverkusen',
    'munchen',
    'dortmund',
    'psg',
    'monaco',
    'lyon',
    'marsella',
    'inter',
    'milan',
    'juventus',
    'napoli'
  ];

  static final List<Widget> _widgetOptions = <Widget>[
    LeagueSelectionWidget(),
    SocialWidget(),
    BettingWidget(),
  ];
  
  
  final ValueNotifier<String> _profileImageIdNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _betCoinsNotifier = ValueNotifier<int>(_betCoins); // Inicializa el ValueNotifier con el valor actual de _betCoins
    _loadProfileImageId();
    _loadBetCoins(); // Carga los BetCoins al inicializar la pantalla
   
  }

  Future<void> _loadProfileImageId() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot<Map<String, dynamic>> userData =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    String profileImageId = userData.get('profileImageid');
    _profileImageIdNotifier.value = profileImageId.isNotEmpty ? profileImageId : 'usuario1';
  }
}

Future<void> _loadBetCoins() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot<Map<String, dynamic>> userData =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    int betCoins = userData.get('betCoins');
    setState(() {
      _betCoins = betCoins;
      _betCoinsNotifier.value = betCoins; // Actualiza el ValueNotifier
    });
  }
}

Stream<int> _betCoinsStream() {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((snapshot) {
      return snapshot.data()?['betCoins'] ?? 0;
    });
  }
  return Stream.value(0);
}




  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    // ------------------- 

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
        // actions: [
        //   Row(
        //     children: [
        //       Text('BetCoins: $_betCoins'), // Muestra el número de BetCoins
        //       PopupMenuButton(
        //         itemBuilder: (BuildContext context) {
        //           return [
        //             PopupMenuItem(
        //               child: ListTile(
        //                 title: Text('Perfil'),
        //                 onTap: () {
        //                   Navigator.pop(context);
        //                   _showProfileDialog(context);
        //                 },
        //               ),
        //             ),
        //             PopupMenuItem(
        //               child: ListTile(
        //                 title: Text('Cerrar Sesión'),
        //                 onTap: () {
        //                   Navigator.pop(context);
        //                   _signOut(context);
        //                 },
        //               ),
        //             ),
        //           ];
        //         },
        //       ),
        //     ],
        //   ),
        // ],
        // ------------------- ACTION -------------------
       actions: [
  Row(
    children: [
      StreamBuilder<int>(
        stream: _betCoinsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          int betCoins = snapshot.data ?? 0;
          return Text('BetCoins: $betCoins');
        },
      ),
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
                  // GestureDetector(
                  //   onTap: () => _showProfileDialog(context),
                
                  //   child: CircleAvatar(
                  //     radius: 40,
                  //     backgroundImage: _profileImageIdNotifier.value.isNotEmpty ? AssetImage(_profileImageIdNotifier.value) : null,
                  //   ),
                  // ),
                  ValueListenableBuilder<String>(
                    valueListenable: _profileImageIdNotifier,
                    builder: (context, profileImageId, child) {
                      return GestureDetector(
                        onTap: () => _showProfileDialog(context),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: profileImageId.isNotEmpty ? AssetImage(profileImageId) : null,
                        ),
                      );
                    },
                  )



                ],
              ),
            ),
            ListTile(
              title: Text('Recompensa Diaria'), // Agrega la opción del drawer para la recompensa diaria
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => BetCoinWidget()));
              },
            ),
            ListTile(
              title: Text('Tienda diaria'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => TiendaWidget()));
              }
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
    DocumentSnapshot<Map<String, dynamic>> userData =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    String username = userData.get('user');
    String email = userData.get('email');
    String profileImageId = userData.get('profileImageid'); // Obtener la URL de la imagen de perfil

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedImageId = _profileImageId;
        String selectedTab = 'CHARACTERS'; // Por defecto, mostrar la pestaña de personajes
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Perfil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contenido del perfil (nombre de usuario, email, imagen de perfil)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.transparent,
                        backgroundImage: profileImageId.isNotEmpty ? NetworkImage(profileImageId) : null, // Mostrar la imagen de perfil almacenada en Firebase
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Username:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            username,
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          const Text(
                            'Email:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Selector de pestañas para personajes y equipos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = 'CHARACTERS';
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'PERSONAJES',
                            style: TextStyle(
                              color: selectedTab == 'CHARACTERS' ? Colors.blue : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = 'TEAMS';
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'EQUIPOS',
                            style: TextStyle(
                              color: selectedTab == 'TEAMS' ? Colors.blue : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Imágenes según la pestaña seleccionada
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Wrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        children: selectedTab == 'CHARACTERS'
                            ? _imageIds.map((imageId) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImageId = imageId;
                                    });
                                    _pickAndSetImage(imageId); // Actualiza la imagen de perfil cuando se selecciona una imagen
                                  },
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: imageId == selectedImageId ? Colors.blue : Colors.transparent,
                                        width: 4,
                                      ),
                                      image: DecorationImage(
                                        image: AssetImage('assets/imagenuser/$imageId.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList()
                            : _imageTeamIds.map((imageId) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImageId = imageId;
                                    });
                                    _pickAndSetImage(imageId); // Actualiza la imagen de perfil cuando se selecciona una imagen
                                  },
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: imageId == selectedImageId ? Colors.blue : Colors.transparent,
                                        width: 4,
                                      ),
                                      image: DecorationImage(
                                        image: AssetImage('../assets/imageTeam/$imageId.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),
                    ),
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
// Future<void> _pickAndSetImage(String imageId) async {
//   User? user = FirebaseAuth.instance.currentUser;
//   if (user != null) {
//     try {
//       String imagePath = 'assets/imagenuser/$imageId.png';

//       // Obtenemos los datos actuales del usuario
//       DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
//       // Copiamos todos los datos actuales del usuario
//       Map<String, dynamic> updatedUserData = userData.data() ?? {};
//       // Actualizamos el campo profileImageid
//       updatedUserData['profileImageid'] = imagePath;

//       // Actualizamos solo el campo profileImageid en Firestore
//       await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updatedUserData);

//       setState(() {
//         _profileImageId = imagePath; // Actualiza la URL de la imagen de perfil en el estado local
//       });
//     } catch (e) {
//       print('Error setting image: $e');
//     }
//   }
// }
Future<void> _pickAndSetImage(String imageId) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      String imagePath = 'assets/imagenuser/$imageId.png';
      DocumentSnapshot<Map<String, dynamic>> userData =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      Map<String, dynamic> updatedUserData = userData.data() ?? {};
      updatedUserData['profileImageid'] = imagePath;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updatedUserData);

      _profileImageIdNotifier.value = imagePath; // Notifica el cambio a ValueNotifier
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
