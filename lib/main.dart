import 'dart:io';
import 'dart:async';

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





class AuthGate extends StatelessWidget { // https://firebase.flutter.dev/docs/ui/auth
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

  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance.collection('images').snapshots();

  final FirebaseAuth auth = FirebaseAuth.instance;

  bool _isLocked = false;
  bool _isGridView = true;
  int _gridViewCount = 3;



  void _gridViewOff() {
    if (_isLocked){
      return;
    }
    setState(() {
      _isGridView = false;
    });
  }

  void _gridViewOn() {
    if (_isLocked){
      return;
    }
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



  CollectionReference images = FirebaseFirestore.instance.collection('images');

  Future<void> favouriteImage(var docId, bool currentFav) {
    if (_isLocked){
      currentFav = currentFav;
    } else {
      currentFav = !currentFav;
    }
    return images
        .doc(docId)
        .update({'favorited': currentFav})
        .then((value) => print("Image Updated"))
        .catchError((error) => print("Failed to update: $error"));
  }

  Future<void> deleteImage(var docId) {
    return images
        .doc(docId)
        .delete()
        .then((value) => print("Image Deleted"))
        .catchError((error) => print("Failed to delete Image: $error"));
  }

  void ImageSelectedItem(BuildContext context, item, var docId) {
    switch (item) {
      case 0:
        print(item);
        break;
      case 1:
        print(item);
        break;
      case 2:
        if (_isLocked){
          break;
        } else {
          deleteImage(docId);
        }
        break;
    }
  }

  void MenuSelectedItem(BuildContext context, item) {
    switch (item) {
      case 0:
        print(item);
        break;
      case 1:
        print(item);
        break;
      case 2:
        _signOut();
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: PopupMenuButton<int>(
              icon: const Icon(Icons.menu),  //don't specify icon if you want 3 dot menu
              color: Colors.grey,
              itemBuilder: (context) => [
                const PopupMenuItem<int>(
                  value: 0,
                  child: Text(
                    "Settings",
                    style: TextStyle(
                        color: Colors.white
                    ),
                  ),
                ),
                const PopupMenuItem<int>(
                  value: 1,
                  child: Text(
                    "Search",
                    style: TextStyle(
                        color: Colors.white
                    ),
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
                          style: TextStyle(
                              color: Colors.white
                          ),
                        ),
                      ],
                    )
                ),
              ],
              onSelected: (item) => {MenuSelectedItem(context, item)},
            ),
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.grid_view_outlined),
              tooltip: 'Grid Display',
              onPressed: _gridViewOn,
            ),
            IconButton(
              icon: const Icon(Icons.sort_outlined),
              tooltip: 'List Display',
              onPressed: _gridViewOff,
            ),
            IconButton(
              icon: _isLocked ?
              const Icon(Icons.lock):
              const Icon(Icons.lock_open),
              tooltip: 'Lock',
              onPressed: _lockSwitch,
            ),
          ]
        ),



        body: StreamBuilder<QuerySnapshot>(
          stream: _usersStream,
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading");
            }

            if (_isGridView){
              return GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridViewCount,
                ),

                children: snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

                  var docId = document.reference.id;

                  final User user = auth.currentUser as User;
                  final uid = user.uid;

                  if (uid == data['user']){

                  }

                  return Container(
                      margin: const EdgeInsets.all(5),
                      color: Theme.of(context).colorScheme.primary,
                      child: Stack(
                          children: [
                            Container (
                              constraints: const BoxConstraints.expand(),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => DetailScreenPage(data: data)),
                                  );
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
                                icon: const Icon(Icons.more_vert_outlined),  //don't specify icon if you want 3 dot menu
                                color: Colors.grey,
                                itemBuilder: (context) => [
                                  const PopupMenuItem<int>(
                                    value: 0,
                                    child: Text(
                                      "Share...",
                                      style: TextStyle(
                                          color: Colors.white
                                      ),
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 1,
                                    child: Text(
                                      "Rename",
                                      style: TextStyle(
                                          color: Colors.white
                                      ),
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 2,
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(
                                          color: Colors.white
                                      ),
                                    ),
                                  ),
                                ],
                                onSelected: (item) => {ImageSelectedItem(context, item, docId)},
                              ),
                            ),
                            Positioned(
                              bottom: -5,
                              right: -5,
                              child: IconButton(
                                tooltip: 'Favourite',
                                icon: data['favorited'] ?
                                Icon(Icons.favorite):
                                Icon(Icons.favorite_border),
                                onPressed: () async {favouriteImage(docId, data['favorited']);},
                              ),
                            ),
                          ]
                      )
                  );
                }).toList(),
              );
            } else {
              return ListView(
                children: snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['name']),
                    subtitle: Text(data['user']),
                  );
                }).toList(),
              );
            }
          },
        ),



        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add Photo',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddImagePage(title: 'Add Image')),
            );
          },
          child: const Icon(Icons.add_a_photo_outlined),
        ),



        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          color: Colors.blue,
          child: IconTheme(
            data: IconThemeData(color: Theme
              .of(context)
              .colorScheme
              .onPrimary
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.only(bottom: 5),
                          constraints: BoxConstraints(),
                          color: Colors.white,
                          tooltip: 'Home',
                          icon: const Icon(Icons.home_outlined),
                          onPressed: () {},
                        ),
                        const Text (
                          'HOME',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ]
                  ),
                ),
                const Spacer(),
                const Spacer(),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.only(bottom: 5),
                          constraints: BoxConstraints(),
                          color: Colors.white,
                          tooltip: 'Shared',
                          icon: const Icon(Icons.people_outlined),
                          onPressed: () {},
                        ),
                        const Text (
                          'SHARED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ]
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      )
    );
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
    await uploadImage(name);
    String imageURL = await downloadImageURL(name);
    bool favorited = false;

    final User user = auth.currentUser as User;
    final uid = user.uid;

    String currentUser = uid;

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('kk:mm:ss-EEE-d/MMM/y').format(now);

    // Call the user's CollectionReference to add a new user
    return images
      .add({
        'name': name, // Stokes and Sons
        'imageURL': imageURL,
        'user': currentUser,
        'dateUploaded': formattedDate,
        'favorited': favorited // 42
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
                        onPressed: () async {pickImage();},
                        child: Row(
                            children: [
                              Container (
                                width: 55,
                                height: 55,
                                color: Colors.grey,
                                child: _newImage == null ?
                                Text('No Image Selected') :
                                Image.file(
                                  _newImage,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const Spacer(),
                              const Text('Select Image'),
                            ]
                        ),
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
                            await addImage(nameEditingController.text,);
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
      )
    );
  }
}





class DetailScreenPage extends StatefulWidget {
  DetailScreenPage({Key? key, required this.data}) : super(key: key);

  final Map<String, dynamic> data;

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
          title: Text(widget.data['name']),
        ),

        body: SingleChildScrollView (
          child: Column(
            children: [
              Center(
                child: Image.network(
                  widget.data['imageURL'],
                ),
              ),
              Text(
                widget.data['user']
              )
            ]
          )
        )
      )
    );
  }
}




// https://stackoverflow.com/questions/58986473/i-have-this-problem-in-flutter-when-i-called-a-function-futurestring-cant
// https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
// https://stackoverflow.com/questions/59587409/how-to-put-json-data-from-server-with-gridview-flutter
// https://firebase.flutter.dev/docs/firestore/usage/


// https://www.youtube.com/watch?v=vYBc7Le5G6s


