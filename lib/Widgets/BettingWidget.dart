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
                    return _mostrarSeleccionAmigos();
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

  Widget _mostrarSeleccionAmigos() {
    List<String> amigosSeleccionados = [];
    TextEditingController _nombreApuestaController = TextEditingController();
    TextEditingController _equipo1Controller = TextEditingController();
    TextEditingController _equipo2Controller = TextEditingController();
    DateTime? _fechaSeleccionada; // Variable para almacenar la fecha seleccionada
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
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Grupo',
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
                    onChanged: (String? nombreGrupoSeleccionado) {
                      setState(() {
                        amigosSeleccionados.clear();
                        if (nombreGrupoSeleccionado != null) {
                          for (var grupo in grupos) {
                            if (grupo['nombre'] == nombreGrupoSeleccionado) {
                              amigosSeleccionados.addAll(grupo['miembros']);
                              break;
                            }
                          }
                        }
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _equipo1Controller,
                          decoration: InputDecoration(
                            labelText: 'Equipo 1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          controller: _equipo2Controller,
                          decoration: InputDecoration(
                            labelText: 'Equipo 2',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ],
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

List<Map<String, dynamic>> grupos = [
  {'nombre': 'Grupo 1', 'miembros': ['Amigo 1', 'Amigo 2']},
  {'nombre': 'Grupo 2', 'miembros': ['Amigo 3', 'Amigo 4']},
];
