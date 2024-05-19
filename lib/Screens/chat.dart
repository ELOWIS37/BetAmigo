import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String amigo;

  const ChatScreen({required this.amigo}); // Recibe el nombre del amigo como parámetro

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _mensajeController = TextEditingController(); // Controlador para el campo de entrada de texto
  late Future<String> _chatIdFuture; // Futuro para obtener el ID del chat

  @override
  void initState() {
    super.initState();
    _chatIdFuture = _chatId(); // Inicializa el futuro para obtener el ID del chat al iniciar el widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.amigo), // Muestra el nombre del amigo en la barra de navegación
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<String>(
              future: _chatIdFuture, // El futuro para obtener el ID del chat
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Muestra un indicador de carga mientras se espera el resultado
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  if (snapshot.hasError) {
                    // Si hay un error al obtener el ID del chat, muestra un mensaje de error
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    // Si se obtiene el ID del chat correctamente, muestra los mensajes del chat
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(snapshot.data) // Utiliza el ID del chat obtenido
                          .collection('mensajes')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // Muestra un indicador de carga mientras se espera la lista de mensajes
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Construye la lista de mensajes del chat
                        return ListView.builder(
                          reverse: true, // Muestra los mensajes en orden inverso (los más recientes primero)
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var mensaje = snapshot.data!.docs[index];
                            bool esMensajePropio =
                                mensaje['remitente'] == FirebaseAuth.instance.currentUser?.uid;

                            // Construye cada mensaje individualmente
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                              child: Align(
                                alignment: esMensajePropio ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: esMensajePropio ? Colors.blue : Colors.grey[300],
                                    borderRadius: esMensajePropio
                                        ? const BorderRadius.only(
                                            topLeft: Radius.circular(20.0),
                                            bottomLeft: Radius.circular(20.0),
                                            bottomRight: Radius.circular(20.0),
                                          )
                                        : const BorderRadius.only(
                                            topRight: Radius.circular(20.0),
                                            bottomLeft: Radius.circular(20.0),
                                            bottomRight: Radius.circular(20.0),
                                          ),
                                  ),
                                  child: Text(
                                    mensaje['texto'], // Muestra el texto del mensaje
                                    style: TextStyle(
                                      color: esMensajePropio ? Colors.white : Colors.black,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController, // Asigna el controlador al campo de entrada de texto
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...', // Texto de ayuda dentro del campo de entrada
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0), // Define un borde redondeado alrededor del campo de entrada
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send), // Icono del botón de enviar
                  onPressed: () {
                    _enviarMensaje(); // Función para enviar el mensaje
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _enviarMensaje() async {
    if (_mensajeController.text.isNotEmpty) {
      String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String amigoNombre = widget.amigo;

      final amigoSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user', isEqualTo: amigoNombre)
          .get();

      if (amigoSnapshot.docs.isNotEmpty) {
        String receptorId = amigoSnapshot.docs.first.id;

        // Crea el chat si no existe y luego envía el mensaje
        await _crearChatSiNoExiste(usuarioActualId, receptorId);

        String chatId = await _generateChatId(usuarioActualId, receptorId);

        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('mensajes')
            .add({
          'texto': _mensajeController.text, // Texto del mensaje
          'remitente': usuarioActualId, // ID del remitente
          'receptor': receptorId, // ID del receptor
          'timestamp': Timestamp.now(), // Marca de tiempo del mensaje
        });

        _mensajeController.clear(); // Limpia el campo de entrada de texto después de enviar el mensaje
      } else {
        print('No se encontró al amigo con el nombre: $amigoNombre');
      }
    }
  }

  // Función para generar el ID del chat
  Future<String> _generateChatId(String usuarioActualId, String receptorId) async {
    // Genera un ID de chat combinando los IDs de usuario
    List<String> ids = [usuarioActualId, receptorId];
    ids.sort(); // Ordena los IDs alfabéticamente para garantizar la unicidad del chat
    return ids.join('_');
  }

  // Función para crear el chat si no existe
  Future<void> _crearChatSiNoExiste(String usuarioActualId, String receptorId) async {
    final chatsQuerySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participantes', arrayContainsAny: [usuarioActualId, receptorId])
        .get();

    if (chatsQuerySnapshot.docs.isEmpty) {
      // Si no existe un chat entre los usuarios, crea uno para ambos
      String chatId = await _generateChatId(usuarioActualId, receptorId);

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participantes': [usuarioActualId, receptorId], // Participantes del chat
        'ultimoMensaje': Timestamp.now(), // Marca de tiempo del último mensaje
      });

      // Guarda el ID del chat en los documentos de usuario
      await _guardarChatEnUsuario(usuarioActualId, chatId);
      await _guardarChatEnUsuario(receptorId, chatId);

      print('Chat creado con éxito');
    }
  }

  // Función para guardar el ID del chat en los documentos de usuario
  Future<void> _guardarChatEnUsuario(String userId, String chatId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'chats': FieldValue.arrayUnion([chatId]), // Agrega el ID del chat al array de chats del usuario
    });
  }

  // Función para obtener el ID del amigo
  Future<String> _getFriendId(String friendName) async {
    String friendId = '';

    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('user', isEqualTo: friendName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      friendId = snapshot.docs.first.id;
    }

    return friendId;
  }

  // Función para obtener el ID del chat entre el usuario actual y su amigo
  Future<String> _chatId() async {
    String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Obtiene el ID del amigo
    String amigoNombre = widget.amigo;
    String amigoId = await _getFriendId(amigoNombre);

    print('Usuario Actual ID: $usuarioActualId');
    print('Amigo ID: $amigoId');

    // Ordena los IDs alfabéticamente para garantizar la unicidad del chat
    List<String> ids = [usuarioActualId, amigoId];
    ids.sort();
    return ids.join('_');
  }
}
