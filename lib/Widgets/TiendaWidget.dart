import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';

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
        // title: Text('Tienda Diaria'),
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
  List<int> _imageIds = [];
  late Timer _timer;
  late DateTime _lastUpdate;

  @override
  void initState() {
    super.initState();
    _lastUpdate = DateTime.now();
    _populateImageIds();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (DateTime.now().difference(_lastUpdate).inHours >= 24) {
        setState(() {
          _populateImageIds();
          _lastUpdate = DateTime.now();
        });
      }
    });
  }

  void _populateImageIds() {
    Random random = Random();
    _imageIds.clear();
    while (_imageIds.length < 3) {
      int imagenId = random.nextInt(20) + 1;
      if (!_imageIds.contains(imagenId)) {
        _imageIds.add(imagenId);
      }
    }
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
                    width: MediaQuery.of(context).size.width * 0.7, // Ancho de la imagen
                    height: MediaQuery.of(context).size.height * 0.3, // Alto de la imagen
                  ),
                  SizedBox(height: 40), // Espacio entre el título y las imágenes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _imageIds
                        .map(
                          (imagenId) => ImageItem(imagenId: imagenId),
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class ImageItem extends StatefulWidget {
  final int imagenId;

  const ImageItem({Key? key, required this.imagenId}) : super(key: key);

  @override
  _ImageItemState createState() => _ImageItemState();
}

class _ImageItemState extends State<ImageItem> {
  late bool _isHovering;

  @override
  void initState() {
    super.initState();
    _isHovering = false;
  }

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
                  transform: Matrix4.identity()
                    ..scale(_isHovering ? 1.1 : 1.0),
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
                      "../../assets/imagenTeam/team${widget.imagenId}.png",
                      fit: BoxFit.cover,
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
            onPressed: () {
              // Acción cuando se presiona el botón de comprar
            },
            child: Text('Comprar'),
          ),
        ],
      ),
    );
  }
}
