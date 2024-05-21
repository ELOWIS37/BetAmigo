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

void main() {
  runApp(MaterialApp(
    title: 'Bet Amigo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: MainScreen(),
  ));
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

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
    'team1',
    'team2',
    'team3',
    'team4',
    'team5',
    'team6',
    'team7',
    'team8',
    'team9',
    'team10',
    'team11',
    'team12',
    'team13',
    'team14',
    'team15',
    'team16',
    'team17',
    'team18',
    'team19',
    'team20',
    'team21',
    'team22',
    'team23'
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
      _profileImageIdNotifier.value = profileImageId.isNotEmpty ? profileImageId : 'imagenpordefecto';
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
          Row(
            children: [
              StreamBuilder<int>(
                stream: _betCoinsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  int betCoins = snapshot.data ?? 0;
                  return Row(
                    children: [
                      Image.asset('assets/coin.png', width: 20, height: 20), // Aquí carga la imagen de la moneda
                      SizedBox(width: 4), // Espacio entre la imagen y el número
                      Text('$betCoins'), // Muestra el número de BetCoins
                    ],
                  );
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.lightBlueAccent,
                    Colors.greenAccent,
                  ],
                ),
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
              title: Text('Tienda Diaria'), // Agrega la opción del drawer para la recompensa diaria
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => CombinedShop()));
              },
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
    String profileImageId = userData.get('profileImageid');
    int betCoins = userData.get('betCoins');

    List<bool> shieldPurchases = List.generate(_imageTeamIds.length, (index) => false);
    
    if (userData.exists) {
      List<dynamic> purchasedBadges = userData.get('purchasedBadges') ?? [];
      purchasedBadges.forEach((badgeId) {
        int index = _imageTeamIds.indexOf('team${badgeId.toString()}');
        if (index != -1) {
          shieldPurchases[index] = true;
        }
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedImageId = _profileImageId;
        String selectedTab = 'CHARACTERS';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Perfil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.transparent,
                        backgroundImage: profileImageId.isNotEmpty ? NetworkImage(profileImageId) : null,
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
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Image.asset('assets/coin.png', width: 24, height: 24),
                              SizedBox(width: 8),
                              const Text(
                                'BetCoins: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '$betCoins',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
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
                                    _pickAndSetImage(imageId, 'user');
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
                            : _imageTeamIds.asMap().entries.map((entry) {
                                int index = entry.key;
                                String imageId = entry.value;
                                bool isPurchased = shieldPurchases[index];
                                return GestureDetector(
  onTap: () {
    setState(() {
      selectedImageId = imageId;
    });
    if (isPurchased) {
      _pickAndSetImage(imageId, 'team');
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Escudo Bloqueado'),
            content: Text('¡Debes comprar este escudo antes de seleccionarlo!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cerrar'),
              ),
            ],
          );
        },
      );
    }
  },
  child: Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: imageId == selectedImageId ? Colors.blue : Colors.transparent,
            width: 4,
          ),
          // Aquí cambia la ruta de la imagen
          image: DecorationImage(
            image: AssetImage('imagenTeam/$imageId.png'),
            fit: BoxFit.contain, // Ajusta la imagen para que se vea completamente dentro del contenedor
          ),
        ),
      ),
      if (!isPurchased)
        Positioned.fill(
          child: Icon(
            Icons.lock,
            color: Colors.grey[600],
            size: 40,
          ),
        ),
    ],
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

  Future<void> _pickAndSetImage(String imageId, String imageType) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      String imagePath = '';
      if (imageType == 'user') {
        imagePath = 'assets/imagenuser/$imageId.png';
      } else if (imageType == 'team') {
        imagePath = '../../assets/imagenTeam/$imageId.png';
      }
      DocumentSnapshot<Map<String, dynamic>> userData =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      Map<String, dynamic> updatedUserData = userData.data() ?? {};
      updatedUserData['profileImageid'] = imagePath;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updatedUserData);

      _profileImageIdNotifier.value = imagePath; // Notifica el cambio a ValueNotifier
      setState(() {
        _profileImageId = imagePath; // Actualiza la imagen de perfil en la pantalla
      });
    } catch (e) {
      print('Error setting image: $e');
    }
  }
}


}
