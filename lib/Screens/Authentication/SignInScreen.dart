import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:betamigo/Screens/MainScreen.dart'; // Importa la pantalla MainScreen

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  bool _obscurePassword = true; // Variable para controlar la visibilidad de la contraseña

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen
          Positioned.fill(
            child: Image.asset(
              'assets/soccer_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Contenido
          Center(
            child: FadeTransition(
              opacity: _animation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.65,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 16),
                      SizedBox(height: 16),
                      // Tabs
                      TabBar(
                        tabs: [
                          Tab(text: 'Iniciar Sesión'),
                          Tab(text: 'Registrarse'),
                        ],
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Contenido de la pestaña de iniciar sesión
                            _buildSignInTab(),
                            // Contenido de la pestaña de registrarse
                            _buildRegisterTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Logo encima de todo
          // Reemplaza el Positioned existente con AnimatedPositioned
          // AnimatedPositioned para el logo
          AnimatedPositioned(
            duration: MediaQuery.of(context).viewInsets.bottom > 0
                ? Duration(milliseconds: 100) // Si el teclado está activo, duración corta
                : Duration(milliseconds: 300), // Si el teclado no está activo, duración larga
            top: MediaQuery.of(context).viewInsets.bottom > 0 ? -200 : 0, // Mueve la imagen hacia arriba cuando el teclado está activo
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _animation,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Image.asset(
                  'assets/logobetamigo.png',
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: MediaQuery.of(context).size.height * 0.25,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Contenido de la pestaña de iniciar sesión
  Widget _buildSignInTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(emailController, 'Correo'),
          SizedBox(height: 16),
          _buildPasswordField(passwordController, 'Contraseña'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Iniciado sesión correctamente!'),
                ));
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainScreen()),
                );
              } catch (e) {
                print('Error al iniciar sesión: $e');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error al iniciar sesión: $e'),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 148, 196, 236),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  // Contenido de la pestaña de registrarse
  Widget _buildRegisterTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(userController, 'Usuario'),
          SizedBox(height: 16),
          _buildTextField(emailController, 'Correo'),
          SizedBox(height: 16),
          _buildPasswordField(passwordController, 'Contraseña'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _register(context); // Llama a la función de registro
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 148, 196, 236),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Registrarse'),
          ),
        ],
      ),
    );
  }

  // Función para construir un campo de texto con borde
  Widget _buildTextField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Función para construir un campo de contraseña con opción de ocultar/mostrar
  Widget _buildPasswordField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
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

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'user': userController.text,
        'email': emailController.text,
        'id': userCredential.user!.uid,
        'profileImageid': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Usuario registrado correctamente!'),
      ));

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } catch (e) {
      print('Error al registrar el usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al registrar el usuario: $e'),
      ));
    }
  }
}
