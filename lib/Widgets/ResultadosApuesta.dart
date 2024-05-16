import 'package:flutter/material.dart';

class ResultadosApuesta extends StatelessWidget {
  final String nombreApuesta;

  const ResultadosApuesta({Key? key, required this.nombreApuesta}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de la Apuesta'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Resultados para: $nombreApuesta',
            style: const TextStyle(fontSize: 24, color: Colors.indigo),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
