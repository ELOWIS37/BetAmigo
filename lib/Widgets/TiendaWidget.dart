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
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: constraints.maxWidth,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20), // Añadido para empujar todo hacia arriba
                        Image.asset(
                          "../../assets/fondoTiendaDiaria/tituloTienda.png",
                          width: constraints.maxWidth * 0.7,
                          height: constraints.maxHeight * 0.25,
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _badgeIds
                              .map(
                                (badgeId) => Flexible(child: BadgeItem(badgeId: badgeId)),
                              )
                              .toList(),
                        ),
                        SizedBox(height: 20), // Añadido para evitar el desbordamiento inferior
                      ],
                    ),
                  ),
                ),
              );
            },
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

class _BadgeItemState extends State<BadgeItem> with TickerProviderStateMixin {
  bool _isHovering = false;
  bool _isPurchased = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _checkIfPurchased();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _checkIfPurchased() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      List<dynamic> purchasedBadges = userDoc.get('purchasedBadges');
      setState(() {
        _isPurchased = purchasedBadges.contains(widget.badgeId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Column(
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
                      width: MediaQuery.of(context).size.width * 0.25,
                      height: MediaQuery.of(context).size.width * 0.25, // Ajustar la altura para mantener la proporción
                    ),
                  ),
                ),
                _isPurchased ? _buildPurchasedOverlay() : SizedBox(),
              ],
            ),
          ),
          SizedBox(height: 8.0),
          _isPurchased ? _buildPurchasedLabel(context) : _buildBuyButton(),
        ],
      ),
    );
  }

  Widget _buildPurchasedOverlay() {
    return Positioned(
      top: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasedLabel(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return ScaleTransition(
      scale: _animation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              if (screenWidth >= 525) ...[
                SizedBox(width: 8),
                Text(
                  '¡COMPRADO!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuyButton() {
    return ElevatedButton(
      onPressed: () => _buyItem(widget.badgeId),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        'Comprar',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Future<void> _buyItem(int itemId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'purchasedBadges': FieldValue.arrayUnion([itemId]),
      });
      setState(() {
        _isPurchased = true;
      });
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
