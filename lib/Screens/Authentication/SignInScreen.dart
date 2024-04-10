import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:betamigo/Screens/MainScreen.dart'; // Importa la pantalla MainScreen

class SignInScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Número de pestañas
      child: Scaffold(
        appBar: AppBar(
          title: Text('BetAmigo'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Iniciar Sesión'), // Pestaña para iniciar sesión
              Tab(text: 'Registrarse'), // Pestaña para registrarse
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Contenido de la pestaña de iniciar sesión
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Correo'),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: emailController.text,
                          password: passwordController.text,
                        );
                        // Muestra un mensaje de éxito al iniciar sesión
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Iniciado sesión correctamente!'),
                        ));
                        // Redirige a la pantalla MainScreen después de iniciar sesión correctamente
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MainScreen()),
                        );
                      } catch (e) {
                        print('Error al iniciar sessión: $e');
                        // Muestra un mensaje de error
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error al iniciar sessión: $e'),
                        ));
                      }
                    },
                    child: Text('Iniciar Sesión'),
                  ),
                ],
              ),
            ),

            // Contenido de la pestaña de registrarse
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    controller: userController,
                    decoration: InputDecoration(labelText: 'Usuario'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Correo'),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _register(context); // Llama a la función de registro
                    },
                    child: Text('Registrarse'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para registrar un nuevo usuario
  Future<void> _register(BuildContext context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Guarda el ID del usuario en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'user': userController.text,
        'email': emailController.text,
        'id': userCredential.user!.uid
        // Puedes agregar más información del usuario aquí si lo deseas
      });

      // Muestra un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Usuario registrado correctamente!'),
      ));

      // Después de registrar, inicia sesión automáticamente
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Redirige a la pantalla MainScreen después de iniciar sesión correctamente
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } catch (e) {
      print('Error al registrar el usuario: $e');
      // Muestra un mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al registrar el usuario: $e'),
      ));
    }
  }
}
