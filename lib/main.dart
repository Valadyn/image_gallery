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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.

        primarySwatch: Colors.blue,
      ),
      home: AuthGate(),
      // home: const MyHomePage(title: 'Gallery App'),
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
        // return ImageObject(1, 'first', 'test');
      },
    );
  }
}

Future _signOut() async {
  await FirebaseAuth.instance.signOut();
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MainPageState();
}



class AddImagePage extends StatefulWidget {
  const AddImagePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<AddImagePage> createState() => _AddImagePageState();
}



class _MainPageState extends State<MyHomePage> {

  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance.collection('images').snapshots();

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



  CollectionReference images = FirebaseFirestore.instance.collection('images');

  Future<void> favouriteImage(var docId, bool currentFav) {
    return images
        .doc(docId)
        .update({'favorited': !currentFav})
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to update user: $error"));
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () async {_signOut();},
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
              icon: const Icon(Icons.lock_outline),
              tooltip: 'Lock',
              onPressed: () {},
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
                  print(document.reference.id);
                  var docId = document.reference.id;
                  print(data['favorited']);
                  return Container(
                      margin: const EdgeInsets.all(5),
                      color: Theme.of(context).colorScheme.primary,
                      child: Stack(
                          children: [
                            Container (
                              constraints: BoxConstraints.expand(),
                              child: Image.network(
                                data['imageURL'],
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -5,
                              right: -5,
                              child: IconButton(
                                tooltip: 'More',
                                icon: const Icon(Icons.more_vert_outlined),
                                onPressed: () {},
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



class _AddImagePageState extends State<AddImagePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth auth = FirebaseAuth.instance;

  CollectionReference images = FirebaseFirestore.instance.collection('images');

  TextEditingController nameEditingController = TextEditingController();
  TextEditingController idEditingController = TextEditingController();

  var newImage;



  Future pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    File file = File(image!.path);

    setState(() {
      newImage = file;
    });
  }

  Future uploadImage(String name) async {
    await firebase_storage.FirebaseStorage.instance
        .ref('images/$name.png')
        .putFile(newImage);
  }

  Future<String> downloadImageURL(String name) async {
    String downloadURL = await firebase_storage.FirebaseStorage.instance
        .ref('images/$name.png')
        .getDownloadURL();

    // Within your widgets:
    // Image.network(downloadURL);
    return downloadURL.toString();
  }

  // Dylan you should research this method more
  Future<void> addImage(id, name) async {
    await uploadImage(name);
    String imageURL = await downloadImageURL(name);
    bool favorited = false;

    final User user = auth.currentUser as User;
    final uid = user.uid;

    String currentUser = uid;

    // Call the user's CollectionReference to add a new user
    return images
      .add({
        'id': id, // John Doe
        'name': name, // Stokes and Sons
        'imageURL': imageURL,
        'user': currentUser,
        'favorited': favorited // 42
      })
      .then((value) => print("image Added"))
      .catchError((error) => print("Failed to add image: $error"));
  }



  exitPage() {
    newImage.clear();
    Navigator.pop(context);
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
                      child: TextFormField(
                        controller: idEditingController,
                        decoration: const InputDecoration(
                          hintText: 'Enter id',
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
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: ElevatedButton(
                        onPressed: () async {pickImage();},
                        child: Row(
                            children: [
                              Container (
                                width: 55,
                                height: 55,
                                color: Colors.amber,
                                child: newImage == null ?
                                Text('No Image Selected') :
                                Image.file(
                                  newImage,
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
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validate will return true if the form is valid, or false if
                          // the form is invalid.
                          if (_formKey.currentState!.validate()) {
                            // Process data.
                            int tempInt = int.parse(idEditingController.text);
                            await addImage(tempInt, nameEditingController.text,);
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



class ImageObject{
  int id;
  String name;
  String imageURL;
  // String user;
  // String size;
  bool favorited = false;

  ImageObject(this.id, this.name, this.imageURL);
}




// https://stackoverflow.com/questions/58986473/i-have-this-problem-in-flutter-when-i-called-a-function-futurestring-cant
// https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
// https://stackoverflow.com/questions/59587409/how-to-put-json-data-from-server-with-gridview-flutter
// https://firebase.flutter.dev/docs/firestore/usage/



