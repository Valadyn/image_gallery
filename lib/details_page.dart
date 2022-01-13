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
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();

  bool _overlayOn = false;

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

  late OverlayState? _overlayState;
  late OverlayEntry _overlayEntry;

  _showOverlay() {
    _overlayState = _overlayKey.currentState;
    _overlayEntry = OverlayEntry(builder: (context) {
      return Stack(
        children: [
          Opacity(
            opacity: 0.85,
            child: Container(
              color: Colors.grey[900],
            ),
          ),
          Container(
            constraints: const BoxConstraints.expand(),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(50.0),
              constrained: true,
              child: Image.network(
                widget.imageData['imageURL'],
              ),
            ),
          ),
        ],
      );
    });
    _overlayState?.insert(_overlayEntry);
    _overlayOn = true;
  }

  _backButton() {
    if (_overlayOn) {
      _overlayEntry.remove();
      _overlayOn = false;
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey[900],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              _backButton();
            },
          ),
          title: Text((widget.imageData['name'] as String).capitalize()),
        ),
        body: Stack(
          children: [
            ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: Container(
                    constraints: const BoxConstraints.expand(),
                    child: GestureDetector(
                      onTap: () {
                        /*
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PictureScreenPage(imageData: widget.imageData),
                      ),
                    );
                     */
                        _showOverlay();
                      },
                      child: Image.network(
                        widget.imageData['imageURL'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Uploaded by: ' + widget.imageData['user'],
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Uploaded at: ' +
                            widget.imageData['dateUploaded']
                                .toDate()
                                .toString(),
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'File Size: ' +
                            (widget.imageData['size'] / 1000).toString() +
                            ' KB',
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Favorited: ' + _favoritedCheck(),
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Shared: ' + _sharedCheck(),
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              child: Overlay(
                key: _overlayKey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
