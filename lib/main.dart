import 'package:betamigo/Screens/Authentication/authentication_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importa flutter/services para utilizar SystemChrome
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Importa las opciones de Firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Establecer la orientación de la pantalla como vertical
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bet Amigo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthenticationWrapper(), // Establece el widget de pantalla principal
    );
  }
}
