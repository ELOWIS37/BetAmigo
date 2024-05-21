import 'package:flutter/material.dart';
import 'package:betamigo/Widgets/LiveScoresWidget.dart';

class LeagueSelectionWidget extends StatefulWidget {
  @override
  _LeagueSelectionWidgetState createState() => _LeagueSelectionWidgetState();
}

class _LeagueSelectionWidgetState extends State<LeagueSelectionWidget> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ligas y Partidos'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlueAccent,
              Colors.greenAccent,
            ],
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 20.0,
                  crossAxisSpacing: 20.0,
                ),
                padding: EdgeInsets.all(20.0),
                itemCount: 6,
                itemBuilder: (context, index) {
                  String league;
                  String imagePath;

                  switch (index) {
                    case 0:
                      league = 'BL1';
                      imagePath = 'assets/bundesliga.png';
                      break;
                    case 1:
                      league = 'PD';
                      imagePath = 'assets/laliga.png';
                      break;
                    case 2:
                      league = 'PL';
                      imagePath = 'assets/pl.png';
                      break;
                    case 3:
                      league = 'FL1';
                      imagePath = 'assets/ligue1.png';
                      break;
                    case 4:
                      league = 'SA';
                      imagePath = 'assets/seria.png';
                      break;
                    case 5:
                      league = 'CL';
                      imagePath = 'assets/champions.png';
                      break;
                    default:
                      league = '';
                      imagePath = '';
                  }

                  return MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _selectedIndex = -1;
                      });
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LiveScoresWidget(league: league),
                          ),
                        );
                      },
                      child: Card(
                        elevation: _selectedIndex == index ? 10 : 2, // Aumenta la elevación al pasar el cursor sobre el elemento
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: _selectedIndex == index ? Colors.blueAccent : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
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
      ),
    );
  }
}
