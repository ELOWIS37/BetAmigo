import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BetCoinWidget extends StatefulWidget {
  @override
  _BetCoinWidgetState createState() => _BetCoinWidgetState();
}

class _BetCoinWidgetState extends State<BetCoinWidget> with TickerProviderStateMixin {
  late User _user;
  int _betCoins = 0;
  int _dayCount = 0;
  late DateTime _lastClaimDate = DateTime.now();
  late Timer _timer;
  late Duration _timeRemaining = Duration();
  bool _claimingReward = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _loadBetCoins();
    _loadLastClaimDate();
    _startTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500), // Duración de la animación
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose(); // Importante liberar los recursos del AnimationController
    super.dispose();
  }

  void _startAnimation() {
    _animationController.forward(from: 0);
  }

  void _loadBetCoins() async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
    setState(() {
      _betCoins = userDoc.data()?['betCoins'] ?? 0;
    });
  }

  void _loadLastClaimDate() async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
    setState(() {
      _dayCount = userDoc.data()?['dayCount'] ?? 0;
      Timestamp? lastClaimTimestamp = userDoc.data()?['lastClaimDate'];
      if (lastClaimTimestamp != null) {
        _lastClaimDate = lastClaimTimestamp.toDate();
      } else {
        _lastClaimDate = DateTime.now().subtract(Duration(days: 1)); // Set the last claim date to one day ago initially
      }
    });
  }

  void _claimDailyReward(int reward, int dayIndex) async {
    DateTime now = DateTime.now();
    DateTime lastMidnight = DateTime(now.year, now.month, now.day);

    if (!_lastClaimDate.isBefore(lastMidnight)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('¡Ya has reclamado la recompensa diaria hoy!'),
      ));
      return;
    }

    if (dayIndex != _dayCount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No puedes reclamar la recompensa de días anteriores.'),
      ));
      return;
    }

    setState(() {
      _claimingReward = true;
    });

    _startAnimation(); // Iniciar la animación

    await Future.delayed(Duration(milliseconds: 1500)); // Simula un pequeño retraso para la animación

    setState(() {
      _claimingReward = false;
      _betCoins += reward;
      _dayCount++;
      _lastClaimDate = lastMidnight; // Actualizar la fecha del último reclamo
    });

    await FirebaseFirestore.instance.collection('users').doc(_user.uid).update({
      'betCoins': _betCoins,
      'lastClaimDate': Timestamp.fromDate(_lastClaimDate),
      'dayCount': _dayCount,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('¡Has reclamado tu recompensa diaria de $reward monedas!'),
    ));

    // Start countdown for next claim if it's not already started
    if (!_timer.isActive) {
      _startTimer();
    }

    if (_dayCount == 7) {
      // Reset day count and last claim date if it's the 7th day
      _dayCount = 0;
      await FirebaseFirestore.instance.collection('users').doc(_user.uid).update({
        'lastClaimDate': Timestamp.fromDate(_lastClaimDate),
        'dayCount': _dayCount,
      });
    }
  }

  void _startTimer() {
    const oneDay = Duration(days: 1);
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    DateTime nextClaimDate = tomorrow.isAfter(_lastClaimDate) ? tomorrow : _lastClaimDate.add(oneDay);
    _timeRemaining = nextClaimDate.difference(now);
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining = _timeRemaining - Duration(seconds: 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recompensa Diaria', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: !_claimingReward, // Deshabilitar el botón de retroceso si se está reclamando la recompensa
      ),
      body: Stack(
        children: [
          AnimatedBackground(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  'Próxima recompensa diaria en: ${_formatDuration(_timeRemaining)}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    children: List.generate(7, (index) {
                      int reward = index == 6 ? 20 : 10; // Recompensa de 20 para el séptimo día, 10 para los demás
                      bool isCurrentDay = _dayCount == index;
                      bool isPastDay = _dayCount > index;
                      bool isFutureDay = _dayCount < index;

                      return GestureDetector(
                        onTap: () {
                          _claimDailyReward(reward, index);
                        },
                        child: Card(
                          elevation: 4,
                          color: isCurrentDay ? Colors.blue : (isPastDay ? Colors.green : Colors.grey),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_claimingReward && isCurrentDay)
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _animationController.value * 0.5 + 1, // Escala de 1 a 1.5
                                      child: Opacity(
                                        opacity: 1 - _animationController.value, // Opacidad de 1 a 0
                                        child: Image.asset(
                                          'assets/coin.png',
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Día ${index + 1}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Recompensa: $reward',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    if (isCurrentDay)
                                      Icon(
                                        Icons.lock_open,
                                        color: Colors.white,
                                      )
                                    else if (isPastDay)
                                      Icon(
                                        Icons.check,
                                        color: Colors.white,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}


class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(seconds: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade700, Colors.deepPurple.shade900],
          stops: [0.0, 0.5],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'BetCoin App',
    theme: ThemeData(
      primarySwatch: Colors.deepPurple,
    ),
    home: BetCoinWidget(),
  ));
}
