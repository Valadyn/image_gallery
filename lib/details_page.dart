import 'dart:core';
import 'package:flutter/material.dart';
import "string_extension.dart";

class DetailScreenPage extends StatefulWidget {
  const DetailScreenPage({Key? key, required this.imageData}) : super(key: key);

  final Map<String, dynamic> imageData;

  @override
  State<DetailScreenPage> createState() => _DetailScreenPage();
}

class _DetailScreenPage extends State<DetailScreenPage> {
  _favoritedCheck() {
    if (widget.imageData['favorited']) {
      return 'Yes';
    } else {
      return 'No';
    }
  }

  _sharedCheck() {
    if (widget.imageData['shared']) {
      return 'Yes';
    } else {
      return 'No';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text((widget.imageData['name'] as String).capitalize()),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.black,
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.symmetric(vertical: 50.0),
                constrained: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: Image.network(
                    widget.imageData['imageURL'],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Uploaded by: ' + widget.imageData['user'],
                          style: const TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Uploaded at: ' + widget.imageData['dateUploaded'],
                          style: const TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'File Size: ' +
                              (widget.imageData['size'] / 1000).toString() +
                              ' KB',
                          style: const TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Favorited: ' + _favoritedCheck(),
                          style: const TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Shared: ' + _sharedCheck(),
                          style: const TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
