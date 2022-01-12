import 'dart:core';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "string_extension.dart";
import "main.dart";
import "details_page.dart";
import "add_image_page.dart";

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final SettingValues settingValues = SettingValues(false, false, false);

  @override
  State<MyHomePage> createState() => _MainPageState();
}

class _MainPageState extends State<MyHomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference images = FirebaseFirestore.instance.collection('images');

  TextEditingController nameSearchingController = TextEditingController();
  final TextEditingController _textFieldController = TextEditingController();

  final scrollController = ScrollController();

  bool _sharedPage = false;
  bool _searchVisible = false;
  bool _isLocked = false;
  bool _isGridView = true;
  int _gridViewCount = 3;
  int _index = 0;

  void _gridViewOff() {
    setState(() {
      _isGridView = false;
    });
  }

  void _gridViewOn() {
    if (_isGridView) {
      if (_gridViewCount == 5) {
        setState(() {
          _gridViewCount = 3;
        });
      } else {
        setState(() {
          _gridViewCount = 5;
        });
      }
    } else {
      setState(() {
        // _gridViewCount = 3;
        _isGridView = true;
      });
    }
  }

  void _lockSwitch() {
    setState(() {
      _isLocked = !_isLocked;
    });
  }

  void showSearchBar() {
    setState(() {
      _searchVisible = !_searchVisible;
    });
  }

  void _showSharedPage() {
    if (!_sharedPage) {
      setState(() {
        _sharedPage = true;
      });
    }
  }

  void _showMainPage() {
    if (_sharedPage) {
      setState(() {
        _sharedPage = false;
      });
    }
  }

  Future<void> favouriteImage(var docId, bool currentFav) {
    return images
        .doc(docId)
        .update({'favorited': !currentFav})
        .then((value) => print("Image Updated"))
        .catchError((error) => print("Failed to update: $error"));
  }

  Future<void> shareImage(var docId, bool currentSha) {
    return images
        .doc(docId)
        .update({'shared': !currentSha})
        .then((value) => print("Image Updated"))
        .catchError((error) => print("Failed to update: $error"));
  }

  Future<void> deleteImage(var docId, var imageData) {
    return images
        .doc(docId)
        .delete()
        .then((value) =>
            FirebaseStorage.instance.refFromURL(imageData['imageURL']).delete())
        .catchError((error) => print("Failed to delete Image: $error"));
  }

  Future<void> editImage(var docId, String name) {
    return images
        .doc(docId)
        .update({'name': name.toLowerCase()})
        .then((value) => print("Image Updated"))
        .catchError((error) => print("Failed to update: $error"));
  }

  Future<void> _searchNameInputDialog(
      BuildContext context, var docId, String currentName) async {
    _textFieldController.text = '';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Image'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: currentName.capitalize()),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                editImage(docId, _textFieldController.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _imageSelectedItem(
      BuildContext context, item, var docId, var imageData) {
    if (!_isLocked) {
      switch (item) {
        case 0:
          shareImage(docId, imageData['shared']);
          break;
        case 1:
          _searchNameInputDialog(context, docId, imageData['name']);
          break;
        case 2:
          deleteImage(docId, imageData);
          break;
      }
    }
  }

  Future<void> _menuSelectedItem(BuildContext context, item) async {
    switch (item) {
      case 0:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(
                title: 'Settings', settingValues: widget.settingValues),
          ),
        );
        setState(() {
          getImages();
        });
        break;
      case 1:
        showSearchBar();
        break;
      case 2:
        signout();
        break;
    }
  }

  late Stream<QuerySnapshot> _imageStream;

  getImages() {
    String currentUid = (auth.currentUser as User).uid;
    String _searchInput = nameSearchingController.text.toLowerCase();

    bool favSwitch = widget.settingValues._favSwitch;
    bool orderSwitch = widget.settingValues._orderSwitch;
    bool ascDesc = widget.settingValues._ascDesc;

    if (_sharedPage) {
      // Is Shared
      if (orderSwitch) {
        // Is Ordered By Date
        if (nameSearchingController.text != '') {
          // Is Using Search Bar
          _imageStream = FirebaseFirestore.instance
              .collection('images')
              .where('shared', isEqualTo: true)
              .where('name', isGreaterThanOrEqualTo: _searchInput)
              .where('name', isLessThan: _searchInput + 'z')
              .orderBy('dateUploaded', descending: ascDesc)
              .snapshots(includeMetadataChanges: true);
        } else {
          // Is NOT Using Search Bar
          _imageStream = FirebaseFirestore.instance
              .collection('images')
              .where('shared', isEqualTo: true)
              .orderBy('dateUploaded', descending: ascDesc)
              .snapshots(includeMetadataChanges: true);
        }
      } else {
        // Is NOT Ordered By Date
        if (nameSearchingController.text != '') {
          // Is Using Search Bar
          _imageStream = FirebaseFirestore.instance
              .collection('images')
              .where('shared', isEqualTo: true)
              .where('name', isGreaterThanOrEqualTo: _searchInput)
              .where('name', isLessThan: _searchInput + 'z')
              .orderBy('name', descending: ascDesc)
              .snapshots(includeMetadataChanges: true);
        } else {
          // Is NOT Using Search Bar
          _imageStream = FirebaseFirestore.instance
              .collection('images')
              .where('shared', isEqualTo: true)
              .orderBy('name', descending: ascDesc)
              .snapshots(includeMetadataChanges: true);
        }
      }
    } else {
      // Is NOT Shared
      if (favSwitch) {
        // Is Favorited
        if (orderSwitch) {
          // Is Ordered By Date
          if (nameSearchingController.text != '') {
            // Is Using Search Bar
            _imageStream = FirebaseFirestore.instance
                .collection('images')
                .where('user', isEqualTo: currentUid)
                .where('favorited', isEqualTo: true)
                .where('name', isGreaterThanOrEqualTo: _searchInput)
                .where('name', isLessThan: _searchInput + 'z')
                .orderBy('dateUploaded', descending: ascDesc)
                .snapshots(includeMetadataChanges: true);
          } else {
            // Is NOT Using Search Bar
            _imageStream = FirebaseFirestore.instance
                .collection('images')
                .where('user', isEqualTo: currentUid)
                .where('favorited', isEqualTo: true)
                .orderBy('dateUploaded', descending: ascDesc)
                .snapshots(includeMetadataChanges: true);
          }
        } else {
          // Is NOT Ordered By Date
          if (nameSearchingController.text != '') {
            // Is Using Search Bar
            _imageStream = FirebaseFirestore.instance
                .collection('images')
                .where('user', isEqualTo: currentUid)
                .where('favorited', isEqualTo: true)
                .where('name', isGreaterThanOrEqualTo: _searchInput)
                .where('name', isLessThan: _searchInput + 'z')
                .orderBy('name', descending: ascDesc)
                .snapshots(includeMetadataChanges: true);
          } else {
            // Is NOT Using Search Bar
            _imageStream = FirebaseFirestore.instance
                .collection('images')
                .where('user', isEqualTo: currentUid)
                .where('favorited', isEqualTo: true)
                .orderBy('name', descending: ascDesc)
                .snapshots(includeMetadataChanges: true);
          }
        }
      } else {
        // Is NOT Favorited
        if (orderSwitch) {
          // Is Ordered By Date
          if (nameSearchingController.text != '') {
            // Is Using Search Bar
            _imageStream = FirebaseFirestore.instance
                .collection('images')
                .where('user', isEqualTo: currentUid)
                .where('name', isGreaterThanOrEqualTo: _searchInput)
                .where('name', isLessThan: _searchInput + 'z')
                .orderBy('dateUploaded', descending: ascDesc)
                .snapshots(includeMetadataChanges: true);
          } else {
            // Is NOT Using Search Bar
            _imageStream = FirebaseFirestore.instance
                .collection('images')
                .where('user', isEqualTo: currentUid)
                .orderBy('dateUploaded', descending: ascDesc)
                .snapshots(includeMetadataChanges: true);
          }
        } else {
          // Is NOT Ordered By Date
          if (nameSearchingController.text != '') {
            // Is Using Search Bar
            _imageStream = FirebaseFirestore.instance
                .collection('images')
                .where('user', isEqualTo: currentUid)
                .where('name', isGreaterThanOrEqualTo: _searchInput)
                .where('name', isLessThan: _searchInput + 'z')
                .orderBy('name', descending: ascDesc)
                .snapshots(includeMetadataChanges: true);
          } else {
            // Is NOT Using Search Bar
            _imageStream = FirebaseFirestore.instance
                .collection('images')
                .where('user', isEqualTo: currentUid)
                .orderBy('name', descending: ascDesc)
                .snapshots(includeMetadataChanges: true);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentUid = (auth.currentUser as User).uid;

    setState(() {
      getImages();
    });

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey[900],
          leading: PopupMenuButton<int>(
            icon: const Icon(Icons.menu),
            //don't specify icon if you want 3 dot menu
            color: Colors.blueGrey,
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 0,
                child: Text(
                  "Settings",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Text(
                  "Search",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<int>(
                  value: 2,
                  child: Row(
                    children: const [
                      Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 7,
                      ),
                      Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )),
            ],
            onSelected: (item) => {_menuSelectedItem(context, item)},
          ),
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.grid_view_outlined),
              tooltip: 'Grid Display',
              onPressed: () {
                if (!_isLocked) {
                  _gridViewOn();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.sort_outlined),
              tooltip: 'List Display',
              onPressed: () {
                if (!_isLocked) {
                  _gridViewOff();
                }
              },
            ),
            IconButton(
              icon: _isLocked
                  ? const Icon(Icons.lock)
                  : const Icon(Icons.lock_open),
              tooltip: 'Lock',
              onPressed: _lockSwitch,
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Visibility(
              visible: _searchVisible,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TextFormField(
                  controller: nameSearchingController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: "Search",
                    hintText: "Search",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _imageStream,
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Linear progress indicator',
                            ),
                          ),
                        ),
                      );
                    }
                    if (_isGridView) {
                      return GridView(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridViewCount,
                        ),
                        children: snapshot.data!.docs.map(
                          (DocumentSnapshot document) {
                            Map<String, dynamic> data =
                                document.data()! as Map<String, dynamic>;

                            var docId = document.reference.id;

                            return Container(
                              margin: const EdgeInsets.all(5),
                              color: Colors.blueGrey[900],
                              child: Stack(
                                children: [
                                  Container(
                                    constraints: const BoxConstraints.expand(),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (!_isLocked) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailScreenPage(
                                                      imageData: data),
                                            ),
                                          );
                                        }
                                      },
                                      child: Image.network(
                                        data['imageURL'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  !_sharedPage || currentUid == data['user']
                                      ? Positioned(
                                          top: -5,
                                          right: -5,
                                          child: PopupMenuButton(
                                            icon: const Icon(
                                                Icons.more_vert_outlined),
                                            //don't specify icon if you want 3 dot menu
                                            color: Colors.blueGrey,
                                            itemBuilder: (context) => [
                                              PopupMenuItem<int>(
                                                value: 0,
                                                child: Text(
                                                  data['shared']
                                                      ? 'Shared'
                                                      : 'Share...',
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                              const PopupMenuItem<int>(
                                                value: 1,
                                                child: Text(
                                                  "Rename",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                              const PopupMenuItem<int>(
                                                value: 2,
                                                child: Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                            onSelected: (item) => {
                                              _imageSelectedItem(
                                                  context, item, docId, data)
                                            },
                                          ),
                                        )
                                      : Container(),
                                  !_sharedPage || currentUid == data['user']
                                      ? Positioned(
                                          bottom: -5,
                                          right: -5,
                                          child: IconButton(
                                            tooltip: 'Favourite',
                                            icon: data['favorited']
                                                ? const Icon(Icons.favorite)
                                                : const Icon(
                                                    Icons.favorite_border),
                                            onPressed: () async {
                                              if (!_isLocked) {
                                                favouriteImage(
                                                    docId, data['favorited']);
                                              }
                                            },
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            );
                          },
                        ).toList(),
                      );
                    } else {
                      return ListView(
                        children: snapshot.data!.docs
                            .map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data()! as Map<String, dynamic>;

                          var docId = document.reference.id;

                          _index = _index + 1;

                          return Container(
                            color: (_index % 2 == 0)
                                ? Colors.blueGrey[100]
                                : Colors.blueGrey[200],
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (!_isLocked) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailScreenPage(imageData: data),
                                        ),
                                      );
                                    }
                                  },
                                  child: ListTile(
                                    title: Text(
                                        (data['name'] as String).capitalize()),
                                    subtitle: Text(data['user']),
                                  ),
                                ),
                                !_sharedPage || currentUid == data['user']
                                    ? Positioned(
                                        top: -5,
                                        right: -5,
                                        child: PopupMenuButton(
                                          icon: const Icon(
                                              Icons.more_vert_outlined),
                                          //don't specify icon if you want 3 dot menu
                                          color: Colors.blueGrey,
                                          itemBuilder: (context) => [
                                            PopupMenuItem<int>(
                                              value: 0,
                                              child: Text(
                                                data['shared']
                                                    ? 'Shared'
                                                    : 'Share...',
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            const PopupMenuItem<int>(
                                              value: 1,
                                              child: Text(
                                                "Rename",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            const PopupMenuItem<int>(
                                              value: 2,
                                              child: Text(
                                                "Delete",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                          onSelected: (item) => {
                                            _imageSelectedItem(
                                                context, item, docId, data)
                                          },
                                        ),
                                      )
                                    : Container(),
                                !_sharedPage || currentUid == data['user']
                                    ? Positioned(
                                        bottom: -5,
                                        right: -5,
                                        child: IconButton(
                                          tooltip: 'Favourite',
                                          icon: data['favorited']
                                              ? const Icon(Icons.favorite)
                                              : const Icon(
                                                  Icons.favorite_border),
                                          onPressed: () async {
                                            if (!_isLocked) {
                                              favouriteImage(
                                                  docId, data['favorited']);
                                            }
                                          },
                                        ),
                                      )
                                    : Container(),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blueGrey[900],
          tooltip: 'Add Photo',
          onPressed: () {
            if (!_isLocked) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddImagePage(title: 'Add Image'),
                ),
              );
            }
          },
          child: const Icon(Icons.add_a_photo_outlined),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          color: Colors.blueGrey[900],
          child: IconTheme(
            data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      iconSize: 30,
                      padding: const EdgeInsets.only(bottom: 1),
                      constraints: const BoxConstraints(),
                      color: Colors.white,
                      tooltip: 'Home',
                      icon: const Icon(Icons.home_outlined),
                      onPressed: _showMainPage,
                    ),
                    const Text(
                      'HOME',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ]),
                ),
                const Spacer(),
                const Spacer(),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 30,
                        padding: const EdgeInsets.only(bottom: 1),
                        constraints: const BoxConstraints(),
                        color: Colors.white,
                        tooltip: 'Shared',
                        icon: const Icon(Icons.people_outlined),
                        onPressed: _showSharedPage,
                      ),
                      const Text(
                        'SHARED',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage(
      {Key? key, required this.title, required this.settingValues})
      : super(key: key);

  final SettingValues settingValues;
  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  void _onOrderSwitchChanged(bool value) {
    setState(() {
      widget.settingValues.setOrderSwitch(value);
    });
  }

  void _onAscDescChanged(bool value) {
    setState(() {
      widget.settingValues.setAscDesc(value);
    });
  }

  void _onFavSwitchChanged(bool value) {
    setState(() {
      widget.settingValues.setFavSwitch(value);
    });
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
              Navigator.pop(context);
            },
          ),
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.grid_view_outlined),
              tooltip: 'Grid Display',
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(5),
          children: <Widget>[
            SwitchListTile(
              title: const Text('Order by, Name / Upload Date:'),
              value: widget.settingValues._orderSwitch,
              onChanged: _onOrderSwitchChanged,
            ),
            SwitchListTile(
              title: const Text('Order by, Ascending / Descending:'),
              value: widget.settingValues._ascDesc,
              onChanged: _onAscDescChanged,
            ),
            SwitchListTile(
              title: const Text('Only Show Favourites:'),
              value: widget.settingValues._favSwitch,
              onChanged: _onFavSwitchChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingValues {
  SettingValues(this._orderSwitch, this._ascDesc, this._favSwitch);

  bool _orderSwitch;
  bool _ascDesc;
  bool _favSwitch;

  setOrderSwitch(bool orderSwitch) {
    _orderSwitch = orderSwitch;
  }

  setAscDesc(bool ascDesc) {
    _ascDesc = ascDesc;
  }

  setFavSwitch(bool favSwitch) {
    _favSwitch = favSwitch;
  }
}
