import 'dart:core';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterfire_ui/auth.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "main_page.dart";





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
      home: const AuthGate(),
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
          return const SignInScreen(
            providerConfigs: [
              EmailProviderConfiguration(),
            ],
          );
        }
        // Render your application if authenticated
        return MyHomePage(title: 'Gallery App');
      },
    );
  }
}
// https://www.youtube.com/watch?v=1xPMbwOFa9I

Future signout() async {
  await FirebaseAuth.instance.signOut();
}

Future<void> userSetup() async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  FirebaseAuth auth = FirebaseAuth.instance;
  String uid = (auth.currentUser as User).uid;
  users.add({'uid': uid});
  return;
}









// https://stackoverflow.com/questions/58986473/i-have-this-problem-in-flutter-when-i-called-a-function-futurestring-cant
// https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
// https://stackoverflow.com/questions/59587409/how-to-put-json-data-from-server-with-gridview-flutter
// https://firebase.flutter.dev/docs/firestore/usage/

// https://www.youtube.com/watch?v=vYBc7Le5G6s
