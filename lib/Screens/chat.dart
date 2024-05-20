import 'dart:math';

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
    _chatIdFuture = _getChatId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').where('user', isEqualTo: widget.amigo).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircleAvatar(
                  backgroundImage: AssetImage('assets/imagenuser/usuario1.png'),
                  radius: 16,
                );
              }
              if (snapshot.hasError || snapshot.data!.docs.isEmpty ?? true) {
                print('No se encontró el usuario: ${widget.amigo}');
                return const CircleAvatar(
                  backgroundImage: AssetImage('assets/imagenuser/usuario1.png'),
                  radius: 16,
                );
              }
              final userData = snapshot.data?.docs.first.data() as Map<String, dynamic>?;

              if (userData == null || !userData.containsKey('profileImageid')) {
                print('No se encontró el campo profileImageid para el usuario: ${widget.amigo}');
                return const CircleAvatar(
                  backgroundImage: AssetImage('assets/imagenuser/usuario1.png'),
                  radius: 16,
                );
              }
              
              final profileImageUrl = userData['profileImageid'] as String?;
              if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
                return CircleAvatar(
                  backgroundImage: NetworkImage(profileImageUrl),
                  radius: 16,
                );
              } else {
                print('No se encontró la URL de la imagen de perfil para el usuario: ${widget.amigo}');
                return const CircleAvatar(
                  backgroundImage: AssetImage('assets/imagenuser/usuario1.png'),
                  radius: 16,
                );
              }
            },
          ),




            SizedBox(width: 8),
            Text(widget.amigo),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<String>(
              future: _chatIdFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return _buildMessageList(snapshot.data!);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList(String chatId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('mensajes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final messages = snapshot.data?.docs ?? [];
        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageItem(message);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(QueryDocumentSnapshot message) {
    final isCurrentUser = message['remitente'] == FirebaseAuth.instance.currentUser?.uid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) _buildFriendAvatar(),
          SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.grey[300],
              borderRadius: isCurrentUser
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
              message['texto'],
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
                fontSize: 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildFriendAvatar() {
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance.collection('users').where('user', isEqualTo: widget.amigo).get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircleAvatar(
          backgroundImage: AssetImage('assets/imagenuser/usuario1.png'),
          radius: 16,
        );
      }
      if (snapshot.hasError || snapshot.data!.docs.isEmpty ?? true) {
        print('No se encontró el usuario: ${widget.amigo}');
        return const CircleAvatar(
          backgroundImage: AssetImage('assets/imagenuser/usuario1.png'),
          radius: 16,
        );
      }
      final userData = snapshot.data?.docs.first.data() as Map<String, dynamic>?;

      if (userData == null || !userData.containsKey('profileImageid')) {
        print('No se encontró el campo profileImageid para el usuario: ${widget.amigo}');
        return const CircleAvatar(
          backgroundImage: AssetImage('assets/imagenuser/usuario1.png'),
          radius: 16,
        );
      }
      
      final profileImageUrl = userData['profileImageid'] as String?;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        return CircleAvatar(
          backgroundImage: NetworkImage(profileImageUrl),
          radius: 16,
        );
      } else {
        print('No se encontró la URL de la imagen de perfil para el usuario: ${widget.amigo}');
        return const CircleAvatar(
          backgroundImage: AssetImage('assets/imagenuser/usuario1.png'),
          radius: 16,
        );
      }
    },
  );
}


  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _mensajeController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _enviarMensaje,
          ),
        ],
      ),
    );
  }

  Future<void> _enviarMensaje() async {
    if (_mensajeController.text.isNotEmpty) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final amigoId = await _getFriendId(widget.amigo);

      await _crearChatSiNoExiste(currentUserId, amigoId);

      final chatId = await _generateChatId(currentUserId, amigoId);
      FirebaseFirestore.instance.collection('chats').doc(chatId).collection('mensajes').add({
        'texto': _mensajeController.text,
        'remitente': currentUserId,
        'receptor': amigoId,
        'timestamp': Timestamp.now(),
      });

      _mensajeController.clear();
    }
  }

  Future<String> _generateChatId(String userId1, String userId2) async {
    final ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _crearChatSiNoExiste(String currentUserId, String amigoId) async {
    final chatId = await _generateChatId(currentUserId, amigoId);
    final chatSnapshot = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();

    if (!chatSnapshot.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participantes': [currentUserId, amigoId],
        'ultimoMensaje': Timestamp.now(),
      });

      await _guardarChatEnUsuario(currentUserId, chatId);
      await _guardarChatEnUsuario(amigoId, chatId);
    }
  }

  Future<void> _guardarChatEnUsuario(String userId, String chatId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'chats': FieldValue.arrayUnion([chatId]),
    });
  }

  Future<String> _getFriendId(String friendName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('user', isEqualTo: friendName)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : '';
  }

  Future<String> _getChatId() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final amigoId = await _getFriendId(widget.amigo);

    final ids = [currentUserId, amigoId];
    ids.sort();
    return ids.join('_');
  }
}
