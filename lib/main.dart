import 'dart:io';
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  // https://firebase.flutter.dev/docs/ui/auth
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is not signed in
        if (!snapshot.hasData) {
          return SignInScreen(
            providerConfigs: [
              EmailProviderConfiguration(),
            ],
          );
        }
        // Render your application if authenticated
        return const MyHomePage(title: 'Gallery App');
      },
    );
  }
}
// https://www.youtube.com/watch?v=1xPMbwOFa9I

Future _signOut() async {
  await FirebaseAuth.instance.signOut();
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MainPageState();
}

class _MainPageState extends State<MyHomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference images = FirebaseFirestore.instance.collection('images');

  TextEditingController nameEditingController = TextEditingController();

  bool _sharedPage = false;
  bool _searchVisible = false;
  bool _isLocked = false;
  bool _isGridView = true;
  int _gridViewCount = 3;

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

  void ImageSelectedItem(BuildContext context, item, var docId, var imageData) {
    if (!_isLocked) {
      switch (item) {
        case 0:
          /*
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => UserSharingPage(title: 'Sharing')),
          );
           */
          shareImage(docId, imageData['shared']);
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    EditImagePage(imageData: imageData, docId: docId)),
          );
          break;
        case 2:
          deleteImage(docId, imageData);
          break;
      }
    }
  }

  void MenuSelectedItem(BuildContext context, item) {
    switch (item) {
      case 0:
        break;
      case 1:
        showSearchBar();
        break;
      case 2:
        _signOut();
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    String userId = (auth.currentUser as User).uid;
    Stream<QuerySnapshot> _imageStream;

    if (nameEditingController.text != '') {
      _imageStream = FirebaseFirestore.instance
          .collection('images')
          .where('user', isEqualTo: userId)
          .where('name', isGreaterThanOrEqualTo: nameEditingController.text)
          .where('name', isLessThan: nameEditingController.text + 'z')
          .snapshots(includeMetadataChanges: true);
    } else if (nameEditingController.text != '' && _sharedPage) {
      _imageStream = FirebaseFirestore.instance
          .collection('images')
          .where('shared', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: nameEditingController.text)
          .where('name', isLessThan: nameEditingController.text + 'z')
          .snapshots(includeMetadataChanges: true);
    } else if (_sharedPage) {
      _imageStream = FirebaseFirestore.instance
          .collection('images')
          .where('shared', isEqualTo: true)
          .snapshots(includeMetadataChanges: true);
    } else {
      _imageStream = FirebaseFirestore.instance
          .collection('images')
          .where('user', isEqualTo: userId)
          .snapshots(includeMetadataChanges: true);
    }

    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
          leading: PopupMenuButton<int>(
            icon: const Icon(Icons.menu),
            //don't specify icon if you want 3 dot menu
            color: Colors.grey,
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
            onSelected: (item) => {MenuSelectedItem(context, item)},
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
          ]),
      body: Column(children: <Widget>[
        Visibility(
          visible: _searchVisible,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TextFormField(
              controller: nameEditingController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                  labelText: "Search",
                  hintText: "Search",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)))),
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
                  return const Text("Loading");
                }

                if (_isGridView) {
                  return GridView(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridViewCount,
                    ),
                    children:
                        snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data =
                          document.data()! as Map<String, dynamic>;

                      var docId = document.reference.id;

                      return Container(
                          margin: const EdgeInsets.all(5),
                          color: Theme.of(context).colorScheme.primary,
                          child: Stack(children: [
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
                                                  imageData: data)),
                                    );
                                  }
                                },
                                child: Image.network(
                                  data['imageURL'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -5,
                              right: -5,
                              child: PopupMenuButton(
                                icon: const Icon(Icons.more_vert_outlined),
                                //don't specify icon if you want 3 dot menu
                                color: Colors.grey,
                                itemBuilder: (context) => [
                                  PopupMenuItem<int>(
                                    value: 0,
                                    child: Text(
                                      data['shared'] ? 'Shared' : 'Share...',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 1,
                                    child: Text(
                                      "Rename",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 2,
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                                onSelected: (item) => {
                                  ImageSelectedItem(context, item, docId, data)
                                },
                              ),
                            ),
                            Positioned(
                              bottom: -5,
                              right: -5,
                              child: IconButton(
                                tooltip: 'Favourite',
                                icon: data['favorited']
                                    ? Icon(Icons.favorite)
                                    : Icon(Icons.favorite_border),
                                onPressed: () async {
                                  if (!_isLocked) {
                                    favouriteImage(docId, data['favorited']);
                                  }
                                },
                              ),
                            ),
                          ]));
                    }).toList(),
                  );
                } else {
                  return ListView(
                    children:
                        snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data =
                          document.data()! as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['name']),
                        subtitle: Text(data['user']),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ),
        ),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Photo',
        onPressed: () {
          if (!_isLocked) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddImagePage(title: 'Add Image')),
            );
          }
        },
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.blue,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    iconSize: 30,
                    padding: EdgeInsets.only(bottom: 1),
                    constraints: BoxConstraints(),
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
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    iconSize: 30,
                    padding: EdgeInsets.only(bottom: 1),
                    constraints: BoxConstraints(),
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
                  )
                ]),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    ));
  }
}

class AddImagePage extends StatefulWidget {
  const AddImagePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<AddImagePage> createState() => _AddImagePageState();
}

class _AddImagePageState extends State<AddImagePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth auth = FirebaseAuth.instance;

  CollectionReference images = FirebaseFirestore.instance.collection('images');

  TextEditingController nameEditingController = TextEditingController();

  var _newImage;

  Future pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    File file = File(image!.path);

    setState(() {
      _newImage = file;
    });
  }

  Future uploadImage(String name) async {
    final User user = auth.currentUser as User;
    final uid = user.uid;

    await firebase_storage.FirebaseStorage.instance
        .ref('images/$uid/$name.png')
        .putFile(_newImage);
  }

  Future<String> downloadImageURL(String name) async {
    final User user = auth.currentUser as User;
    final uid = user.uid;

    String downloadURL = await firebase_storage.FirebaseStorage.instance
        .ref('images/$uid/$name.png')
        .getDownloadURL();

    // Within your widgets:
    // Image.network(downloadURL);
    return downloadURL.toString();
  }

  // Dylan you should research this method more
  Future<void> addImage(name) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEE d-M-y ss:mm:hh aaa').format(now);
    String tempName = name + ' ' + formattedDate;

    await uploadImage(tempName);
    String imageURL = await downloadImageURL(tempName);
    bool favorited = false;
    bool shared = false;

    final User user = auth.currentUser as User;
    final uid = user.uid;

    String currentUser = uid;

    // Call the user's CollectionReference to add a new user
    return images
        .add({
          'name': name,
          'imageName': tempName,
          'imageURL': imageURL,
          'user': currentUser,
          'dateUploaded': formattedDate,
          'favorited': favorited,
          'Shared': shared,
        })
        .then((value) => print("image Added"))
        .catchError((error) => print("Failed to add image: $error"));
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
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      controller: nameEditingController,
                      decoration: const InputDecoration(
                        hintText: 'Enter name',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        pickImage();
                      },
                      child: Row(children: [
                        Container(
                          width: 55,
                          height: 55,
                          color: Colors.grey,
                          child: _newImage == null
                              ? Text('No Image Selected')
                              : Image.file(
                                  _newImage,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const Spacer(),
                        const Text('Select Image'),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Validate will return true if the form is valid, or false if
                        // the form is invalid.
                        if (_formKey.currentState!.validate()) {
                          // Process data.
                          await addImage(
                            nameEditingController.text,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ));
  }
}

class EditImagePage extends StatefulWidget {
  const EditImagePage({Key? key, required this.imageData, required this.docId})
      : super(key: key);

  final Map<String, dynamic> imageData;
  final String docId;

  @override
  State<EditImagePage> createState() => _EditImagePageState();
}

class _EditImagePageState extends State<EditImagePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  CollectionReference images = FirebaseFirestore.instance.collection('images');

  TextEditingController nameEditingController = TextEditingController();

  Future<void> editImage(var docId, String name) {
    return images
        .doc(docId)
        .update({'name': name})
        .then((value) => print("Image Updated"))
        .catchError((error) => print("Failed to update: $error"));
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
        title: Text('Rename Image: ' + widget.imageData['name']),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextFormField(
                      controller: nameEditingController,
                      decoration: const InputDecoration(
                        hintText: 'Enter name',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Validate will return true if the form is valid, or false if
                        // the form is invalid.
                        if (_formKey.currentState!.validate()) {
                          // Process data.
                          await editImage(
                            widget.docId,
                            nameEditingController.text,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ));
  }
}

class DetailScreenPage extends StatefulWidget {
  DetailScreenPage({Key? key, required this.imageData}) : super(key: key);

  final Map<String, dynamic> imageData;

  @override
  State<DetailScreenPage> createState() => _DetailScreenPage();
}

class _DetailScreenPage extends State<DetailScreenPage> {
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
              title: Text(widget.imageData['name']),
            ),
            body: SingleChildScrollView(
                child: Column(children: [
              Center(
                child: Image.network(
                  widget.imageData['imageURL'],
                ),
              ),
              Text(widget.imageData['user'])
            ]))));
  }
}

class UserSharingPage extends StatefulWidget {
  UserSharingPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<UserSharingPage> createState() => _UserSharingPage();
}

class _UserSharingPage extends State<UserSharingPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    String userId = (auth.currentUser as User).uid;
    Stream<QuerySnapshot> _userStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots(includeMetadataChanges: true);

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
          title: Text(widget.title),
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: _userStream,
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Text('Something went wrong');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Loading");
              }

              return ListView(
                children: snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data =
                      document.data()! as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['identifier']),
                    subtitle: Text(data['user']),
                  );
                }).toList(),
              );
            }),
      ),
    );
  }
}

// https://stackoverflow.com/questions/58986473/i-have-this-problem-in-flutter-when-i-called-a-function-futurestring-cant
// https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
// https://stackoverflow.com/questions/59587409/how-to-put-json-data-from-server-with-gridview-flutter
// https://firebase.flutter.dev/docs/firestore/usage/

// https://www.youtube.com/watch?v=vYBc7Le5G6s
