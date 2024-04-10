import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:betamigo/Screens/MainScreen.dart';
import 'package:betamigo/Screens/Authentication/SignInScreen.dart';

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return MainScreen();
    } else {
      return SignInScreen();
    }
  }
}
