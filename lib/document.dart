import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Document extends StatefulWidget {
  const Document({Key? key}) : super(key: key);

  @override
  _DocumentState createState() => _DocumentState();
}

class _DocumentState extends State<Document> {
  List<String> savedCodes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCodes();
  }

  Future<void> _loadSavedCodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedCodes = prefs.getStringList('savedCodes') ?? [];
    });
  }

  Future<void> _deleteCode(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedCodes.removeAt(index);
      prefs.setStringList('savedCodes', savedCodes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(137, 170, 229, 1),
        title: const Text("Saved Text"),
        centerTitle: true,
      ),
      body: savedCodes.isEmpty
          ? Center(
              child: Text(
                'No saved text. Please scan a QR code.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: savedCodes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(savedCodes[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCode(index),
                  ),
                );
              },
            ),
    );
  }
}
