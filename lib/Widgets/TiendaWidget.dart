import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

void main() {
  runApp(MaterialApp(
    title: 'Daily Shop',
    home: TiendaWidget(),
  ));
}

class TiendaWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tienda Diaria'),
      ),
    );
  }
}

