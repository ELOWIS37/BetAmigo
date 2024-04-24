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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.amigo),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId())
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
                    bool esMensajePropio = mensaje['remitente'] == FirebaseAuth.instance.currentUser?.uid;

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

  String _chatId() {
    String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String amigoId = widget.amigo;

    List<String> ids = [usuarioActualId, amigoId]..sort();
    return ids.join('_');
  }



 void _enviarMensaje() async {
  if (_mensajeController.text.isNotEmpty) {
    String chatId = _chatId();
    String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String amigoNombre = widget.amigo;

    // Obtener el ID del amigo usando el nombre
    final amigoSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('user', isEqualTo: amigoNombre)
        .get();

    if (amigoSnapshot.docs.isNotEmpty) {
      String receptorId = amigoSnapshot.docs.first.id;

      _crearChatSiNoExiste(chatId);

      FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('mensajes')
          .doc() // Genera un ID único para el mensaje
          .set({
        'texto': _mensajeController.text,
        'remitente': usuarioActualId,
        'receptor': receptorId,
        'timestamp': Timestamp.now(),
      })
      .then((value) {
        print('Mensaje enviado con éxito');
      })
      .catchError((error) {
        print('Error al enviar el mensaje: $error');
      });

      _mensajeController.clear();
    } else {
      print('No se encontró al amigo con el nombre: $amigoNombre');
    }
  }
}





  void _crearChatSiNoExiste(String chatId) async {
    String usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String amigoNombre = widget.amigo;

    final amigoSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('user', isEqualTo: amigoNombre)
        .get();

    if (amigoSnapshot.docs.isNotEmpty) {
      String amigoId = amigoSnapshot.docs.first.id;

      final chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participantes', arrayContainsAny: [usuarioActualId, amigoId])
          .get();

      if (chatSnapshot.docs.isNotEmpty) {
        print('El chat ya existe');
        return;
      }

      FirebaseFirestore.instance.runTransaction((transaction) async {
        final newChatSnapshot = await transaction.get(
          FirebaseFirestore.instance.collection('chats').doc(chatId),
        );

        if (!newChatSnapshot.exists) {
          transaction.set(
            FirebaseFirestore.instance.collection('chats').doc(chatId),
            {
              'participantes': [usuarioActualId, amigoId],
              'ultimoMensaje': Timestamp.now(),
            },
          );
          print('Chat creado con éxito');
        } else {
          transaction.update(
            FirebaseFirestore.instance.collection('chats').doc(chatId),
            {
              'ultimoMensaje': Timestamp.now(),
            },
          );
          print('Tiempo del último mensaje actualizado con éxito');
        }
      }).catchError((error) {
        print('Error en la transacción: $error');
      });
    } else {
      print('No se encontró al amigo con el nombre: $amigoNombre');
    }
  }
}
