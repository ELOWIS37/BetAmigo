import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String amigo;

  const ChatScreen({required this.amigo});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  late Future<String> _chatIdFuture;

  @override
  void initState() {
    super.initState();
    _chatIdFuture = _chatId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.amigo),
      ),
      body: Column(
        children: [
          FutureBuilder<String>(
            future: _chatIdFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Text('Chat ID: ${snapshot.data}');
                }
              }
            },
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: _chatIdFuture,
              builder: (context, chatIdSnapshot) {
                if (chatIdSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatIdSnapshot.data)
                      .collection('mensajes')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var mensaje = snapshot.data!.docs[index];
                        bool esMensajePropio =
                            mensaje['remitente'] == FirebaseAuth.instance.currentUser?.uid;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          child: Align(
                            alignment: esMensajePropio ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
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
                                mensaje['texto'],
                                style: TextStyle(
                                  color: esMensajePropio ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _enviarMensaje();
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

        // Crear el chat si no existe
        await _crearChatSiNoExiste(usuarioActualId, receptorId);

        String chatId = await _generateChatId(usuarioActualId, receptorId);

        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('mensajes')
            .add({
          'texto': _mensajeController.text,
          'remitente': usuarioActualId,
          'receptor': receptorId,
          'timestamp': Timestamp.now(),
        });

        _mensajeController.clear();
      } else {
        print('No se encontró al amigo con el nombre: $amigoNombre');
      }
    }
  }

  Future<String> _generateChatId(String usuarioActualId, String receptorId) async {
    // Generar un ID de chat combinando los IDs de usuario
    List<String> ids = [usuarioActualId, receptorId];
    ids.sort(); // Ordenar los IDs alfabéticamente
    return ids.join('_');
  }

  Future<void> _crearChatSiNoExiste(String usuarioActualId, String receptorId) async {
    final chatsQuerySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participantes', arrayContainsAny: [usuarioActualId, receptorId])
        .get();

    if (chatsQuerySnapshot.docs.isEmpty) {
      // Si no existe un chat entre los usuarios, crearlo para ambos
      String chatId = await _generateChatId(usuarioActualId, receptorId);

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participantes': [usuarioActualId, receptorId],
        'ultimoMensaje': Timestamp.now(),
      });

      // Guardar el ID del chat en los documentos de usuario
      await _guardarChatEnUsuario(usuarioActualId, chatId);
      await _guardarChatEnUsuario(receptorId, chatId);

      print('Chat creado con éxito');
    }
  }

  Future<void> _guardarChatEnUsuario(String userId, String chatId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'chats': FieldValue.arrayUnion([chatId]),
    });
  }

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

  Future<String> _chatId() async {
    String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Obtener el ID del amigo
    String amigoNombre = widget.amigo;
    String amigoId = await _getFriendId(amigoNombre);

    print('Usuario Actual ID: $usuarioActualId');
    print('Amigo ID: $amigoId');

    // Ordenar los IDs alfabéticamente para garantizar la unicidad del chat
    List<String> ids = [usuarioActualId, amigoId];
    ids.sort();
    return ids.join('_');
  }
}
