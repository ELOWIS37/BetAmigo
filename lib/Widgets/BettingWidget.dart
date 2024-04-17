import 'package:flutter/material.dart';

class BettingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apuestas Virtuales'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Pantalla de Bombardeen segovia'),
            SizedBox(height: 20), // Espacio entre el texto y el botón
            ElevatedButton(
              onPressed: () {
                // Mostrar la ventana emergente
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return _mostrarSeleccionAmigos(context);
                  },
                );
              },
              child: Text('Crear Apuesta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mostrarSeleccionAmigos(BuildContext context) {
    List<String> amigosSeleccionados = [];
    TextEditingController _nombreApuestaController = TextEditingController();
    TextEditingController _equipo1Controller = TextEditingController();
    TextEditingController _equipo2Controller = TextEditingController();
    DateTime? _fechaSeleccionada; // Variable para almacenar la fecha seleccionada
    String? selectedGroup; // Variable para almacenar el grupo seleccionado
    String? selectedLeague; // Variable para almacenar la liga seleccionada
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AlertDialog(
          title: Text('Creación de Apuesta'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Ancho del AlertDialog
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Grupos',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    items: grupos.map((grupo) {
                      return DropdownMenuItem<String>(
                        value: grupo['nombre'],
                        child: Text(grupo['nombre']),
                      );
                    }).toList(),
                    onChanged: (String? selectedGroupValue) {
                      setState(() {
                        selectedGroup = selectedGroupValue;
                      });
                    },
                  ),
                  SizedBox(height: 20), // Espacio entre el desplegable de grupos y el desplegable de ligas
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Ligas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    items: ligas.map((liga) {
                      return DropdownMenuItem<String>(
                        value: liga,
                        child: Text(liga),
                      );
                    }).toList(),
                    onChanged: (String? selectedLeagueValue) {
                      setState(() {
                        selectedLeague = selectedLeagueValue;
                      });
                    },
                  ),
                  if (selectedLeague != null && selectedLeague!.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(height: 20), // Espacio entre el desplegable de ligas y el desplegable de partidos
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Partidos',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          items: partidos[selectedLeague!]!.map((partido) {
                            return DropdownMenuItem<String>(
                              value: partido,
                              child: Text(partido),
                            );
                          }).toList(),
                          onChanged: (String? selectedMatch) {
                            // Aquí puedes agregar la lógica para manejar la selección del partido
                          },
                        ),
                      ],
                    ),
                  SizedBox(height: 20), // Espacio entre los campos de entrada y el resto de campos
                  TextFormField(
                    controller: _nombreApuestaController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Apuesta',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _equipo1Controller,
                    decoration: InputDecoration(
                      labelText: 'Equipo 1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _equipo2Controller,
                    decoration: InputDecoration(
                      labelText: 'Equipo 2',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      final fechaSeleccionada = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      setState(() {
                        _fechaSeleccionada = fechaSeleccionada;
                      });
                    },
                    child: Text(
                      _fechaSeleccionada != null
                          ? 'Fecha Seleccionada: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}'
                          : 'Seleccionar Fecha',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            // Aquí se puede agregar un botón adicional si se necesita
          ],
        );
      },
    );
  }
}

Map<String, List<String>> partidos = {
  'Liga BBVA': ['Partido 1', 'Partido 2', 'Partido 3'],
  'Premier League': ['Partido 4', 'Partido 5', 'Partido 6'],
  'Ligue 1': ['Partido 7', 'Partido 8', 'Partido 9'],
  'Serie A': ['Partido 10', 'Partido 11', 'Partido 12'],
  'Bundesliga': ['Partido 13', 'Partido 14', 'Partido 15'],
  'Champions League': ['Partido 16', 'Partido 17', 'Partido 18'],
};

List<String> ligas = ['Liga BBVA', 'Premier League', 'Ligue 1', 'Serie A', 'Bundesliga', 'Champions League'];

List<Map<String, dynamic>> grupos = [
  {'nombre': 'Grupo 1', 'miembros': ['Amigo 1', 'Amigo 2']},
  {'nombre': 'Grupo 2', 'miembros': ['Amigo 3', 'Amigo 4']},
];
