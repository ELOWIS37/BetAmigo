import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

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
      body: DailyShop(),
    );
  }
}

class DailyShop extends StatefulWidget {
  @override
  _DailyShopState createState() => _DailyShopState();
}

class _DailyShopState extends State<DailyShop> {
  List<int> _badgeIds = [];
  late DateTime _lastUpdate;

  @override
  void initState() {
    super.initState();
    _lastUpdate = DateTime.now();
    _populateBadgeIds();
  }

  void _populateBadgeIds() {
    FirebaseFirestore.instance.collection('dailyItems').doc('today').get().then((snapshot) {
      if (snapshot.exists) {
        DateTime lastUpdate = (snapshot.data() as dynamic)['lastUpdate'].toDate();
        if (DateTime.now().difference(lastUpdate).inHours >= 24) {
          _generateNewItems();
        } else {
          setState(() {
            _badgeIds = List<int>.from((snapshot.data() as dynamic)['items']);
          });
        }
      } else {
        _generateNewItems();
      }
    }).catchError((error) {
      print('Error fetching daily items: $error');
    });
  }

  void _generateNewItems() {
    Random random = Random();
    _badgeIds.clear();
    while (_badgeIds.length < 3) {
      int badgeId = random.nextInt(20) + 1;
      if (!_badgeIds.contains(badgeId)) {
        _badgeIds.add(badgeId);
      }
    }
    _saveDailyItems();
  }

  Future<void> _saveDailyItems() async {
    await FirebaseFirestore.instance.collection('dailyItems').doc('today').set({
      'items': _badgeIds,
      'lastUpdate': DateTime.now(),
    });
    setState(() {
      _lastUpdate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    "../../assets/fondoTiendaDiaria/marcoMadera.png",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "../../assets/fondoTiendaDiaria/tituloTienda.png",
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _badgeIds
                        .map(
                          (badgeId) => BadgeItem(badgeId: badgeId),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeItem extends StatefulWidget {
  final int badgeId;

  const BadgeItem({Key? key, required this.badgeId}) : super(key: key);

  @override
  _BadgeItemState createState() => _BadgeItemState();
}

class _BadgeItemState extends State<BadgeItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MouseRegion(
            onEnter: (_) {
              setState(() {
                _isHovering = true;
              });
            },
            onExit: (_) {
              setState(() {
                _isHovering = false;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  transform: Matrix4.identity()..scale(_isHovering ? 1.1 : 1.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white,
                      width: 3.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      "../../assets/imagenTeam/team${widget.badgeId}.png",
                      fit: BoxFit.contain,
                      width: MediaQuery.of(context).size.width / 4.0,
                      height: MediaQuery.of(context).size.height / 3.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _buyItem(widget.badgeId),
            child: Text('Comprar'),
          ),
        ],
      ),
    );
  }

  Future<void> _buyItem(int itemId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'purchasedBadges': FieldValue.arrayUnion([itemId]),
      });
    }
  }
}
