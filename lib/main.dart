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








Future _pickImage() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

  File file = File(image!.path);

  await firebase_storage.FirebaseStorage.instance
      .ref('images/file-to-upload.png')
      .putFile(file);
}

/*
Future<void> downloadURLExample() async {
  String downloadURL = await firebase_storage.FirebaseStorage.instance
      .ref('images/file-to-upload.png')
      .getDownloadURL();

  // Within your widgets:
  // Image.network(downloadURL);
}
*/





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



  Future<String> downloadURLExample() async {
    String downloadURL = await firebase_storage.FirebaseStorage.instance
        .ref('images/file-to-upload.png')
        .getDownloadURL();

    // Within your widgets:
    // Image.network(downloadURL);
    return downloadURL.toString();
  }

  List<ImageObject> items = [];

  _onPressed() {
    items.clear();
    FirebaseFirestore.instance.collection('images').get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        ImageObject item = ImageObject(result.data()['id'], result.data()['name'], result.data()['imageName'], result.data()['imageURL']);
        items.add(item);
        print(item.id);
        print(item.name);
        print(item.imageName);
        print(item.imageURL);
      });
    });
  }









  CollectionReference images = FirebaseFirestore.instance.collection('images');

  Future<void> uploadImage(String name) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String filePath = '${appDocDir.absolute}/$name.png';
    // ...
    // e.g. await uploadFile(filePath);
    File file = File(filePath);

    try {
      await firebase_storage.FirebaseStorage.instance
          .ref('images/$name.png')
          .putFile(file);
    } catch (e) {
      // e.g, e.code == 'canceled'
    }
  }

  Future pickImage(String name) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    File file = File(image!.path);

    await firebase_storage.FirebaseStorage.instance
        .ref('images/$name.png')
        .putFile(file);
  }

  Future<String> downloadImageURL(String name) async {
    String downloadURL = await firebase_storage.FirebaseStorage.instance
        .ref('images/$name.png')
        .getDownloadURL();

    // Within your widgets:
    // Image.network(downloadURL);
    return downloadURL.toString();
  }

  Future<void> addImage(id, name, imageName) async {
    await pickImage(imageName);
    String imageURL = await downloadImageURL(imageName);
    bool favorited = false;

    // Call the user's CollectionReference to add a new user
    return images
        .add({
      'id': id, // John Doe
      'name': name, // Stokes and Sons
      'imageName': imageName,
      'imageURL': imageURL,
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
              onPressed: () async {await addImage(1, 'second', 'hello');},
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
              onPressed: () async {
                _onPressed();
              },
            ),
          ]
        ),

        body: _isGridView ?
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridViewCount,
          ),

          itemCount: items.length,
          // Provide a builder function. This is where the magic happens.
          // Convert each item into a widget based on the type of item it is.
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              margin: const EdgeInsets.all(5),
              color: Theme.of(context).colorScheme.primary,
              child: Stack(
                children: [
                  Image(
                    image: NetworkImage(
                      item.imageURL
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
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {},
                    ),
                  ),
                ]
              )
            );
          },
        ) :
        ListView.builder(
          // Let the ListView know how many items it needs to build.
          itemCount: items.length,
          // Provide a builder function. This is where the magic happens.
          // Convert each item into a widget based on the type of item it is.
          itemBuilder: (context, index) {
            final item = items[index];

            return ListTile(
              title: Text(item.name.toString()),
              subtitle: Text(item.name.toString()),
            );
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
                Column(
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
                Column(
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

  TextEditingController nameEditingController = TextEditingController();
  TextEditingController imageNameEditingController = TextEditingController();
  TextEditingController idEditingController = TextEditingController();



  CollectionReference images = FirebaseFirestore.instance.collection('images');

  Future<void> uploadImage(String name) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String filePath = '${appDocDir.absolute}/$name.png';
    // ...
    // e.g. await uploadFile(filePath);
    File file = File(filePath);

    try {
      await firebase_storage.FirebaseStorage.instance
          .ref('images/$name.png')
          .putFile(file);
    } catch (e) {
      // e.g, e.code == 'canceled'
    }
  }

  Future pickImage(String name) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    File file = File(image!.path);

    await firebase_storage.FirebaseStorage.instance
        .ref('images/$name.png')
        .putFile(file);
  }

  Future<String> downloadImageURL(String name) async {
    String downloadURL = await firebase_storage.FirebaseStorage.instance
        .ref('images/$name.png')
        .getDownloadURL();

    // Within your widgets:
    // Image.network(downloadURL);
    return downloadURL.toString();
  }

  Future<void> addImage(id, name, imageName) async {
    await pickImage(imageName);
    String imageURL = await downloadImageURL(imageName);
    bool favorited = false;

    // Call the user's CollectionReference to add a new user
    return images
        .add({
      'id': id, // John Doe
      'name': name, // Stokes and Sons
      'imageName': imageName,
      'imageURL': imageURL,
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
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () {},
          ),
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.grid_view_outlined),
              tooltip: 'Grid Display',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.sort_outlined),
              tooltip: 'List Display',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: 'Lock',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
              onPressed: () {},
            ),
          ]
        ),

        body: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: nameEditingController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: imageNameEditingController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: idEditingController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Validate will return true if the form is valid, or false if
                        // the form is invalid.
                        if (_formKey.currentState!.validate()) {
                          // Process data.
                          int test = int.parse(idEditingController.text);
                          await addImage(test, nameEditingController.text, imageNameEditingController.text);
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
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
  String imageName;
  String imageURL;
  bool favorited = false;

  ImageObject(this.id, this.name, this.imageName, this.imageURL);
}




// https://stackoverflow.com/questions/58986473/i-have-this-problem-in-flutter-when-i-called-a-function-futurestring-cant
// https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
// https://stackoverflow.com/questions/59587409/how-to-put-json-data-from-server-with-gridview-flutter
// https://firebase.flutter.dev/docs/firestore/usage/



