import 'dart:core';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

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
  var _fileSize;

  Future pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    File file = File(image!.path);
    var size = await file.length();

    setState(() {
      _fileSize = size;
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
    name = name.toLowerCase();
    DateTime now = DateTime.now();
    String tempName = name + ' ' + now.toString();

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
          'dateUploaded': now,
          'favorited': favorited,
          'shared': shared,
          'size': _fileSize,
        })
        .then((value) => print("image Added"))
        .catchError((error) => print("Failed to add image: $error"));
  }

  loader() async {
    await addImage(
      nameEditingController.text,
    );
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
                            color: Colors.blueGrey,
                            child: _newImage == null
                                ? const Text('No Image Selected')
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
                            loader();
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
