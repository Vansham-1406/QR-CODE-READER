// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart' hide CameraException;
import 'package:qr_code_reader/document.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await [Permission.camera].request();
  await [Permission.audio].request();
  cameras = await availableCameras();
  runApp(const MaterialApp(
    home: HomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(137, 170, 229, 1),
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 35),
            height: 380,
            width: MediaQuery.of(context).size.width,
            color: const Color.fromRGBO(137, 170, 229, 1),
            child: Column(
              children: [
                Image.asset(
                  "assets/scanner.png",
                  height: 300,
                ),
                const Text(
                  "QR CODE READER",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                child: Container(
                  height: 80,
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 20),
                  width: 120,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.document_scanner_outlined,
                        size: 30,
                      ),
                      SizedBox(height: 5),
                      Text("Scanner")
                    ],
                  ),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Camera(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              InkWell(
                child: Container(
                  height: 80,
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 20),
                  width: 120,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.save,
                        size: 30,
                      ),
                      SizedBox(height: 5),
                      Text("Saved QR code")
                    ],
                  ),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Document(),
                    ),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

class Camera extends StatefulWidget {
  const Camera({Key? key}) : super(key: key);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  late CameraController _controller;
  final GlobalKey _gLobalkey = GlobalKey();
  QRViewController? controller;
  Barcode? result;
  late BuildContext scaffoldContext;
  bool _shouldScan = true;
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    _controller = CameraController(cameras[0], ResolutionPreset.max);
    await _controller.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onQRCodeScanned(String? code) async {
    if (code != null && _shouldScan) {
      _shouldScan = false;
      await showDialog(
        context: scaffoldContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('QR Code Scanned'),
            content: Text('Result: $code'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: const Text('OK (Move to Home Page)'),
              ),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: const Text('Copy to Clipboard'),
              ),
              TextButton(
                onPressed: () async {
                  await _saveCodeToLocalPreferences(code);
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: const Text('Save the text'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _shouldScan = true;
                },
                child: const Text('Cancel (Continue Scanning)'),
              ),
            ],
          );
        },
      );
    }
  }

  void qr(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((event) {
      setState(() {
        result = event;
      });

      if (result != null) {
        _onQRCodeScanned(result!.code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color.fromRGBO(137, 170, 229, 1),
          ),
          _controller.value.isInitialized
              ? Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: QRView(key: _gLobalkey, onQRViewCreated: qr),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40),
              child: const Text(
                'Scan the code through the box',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _saveCodeToLocalPreferences(String code) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> savedCodes = prefs.getStringList('savedCodes') ?? [];
  savedCodes.add(code);
  await prefs.setStringList('savedCodes', savedCodes);
}
