import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/home.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool pageInitialised = false;

  final googleSignIn = GoogleSignIn();

  final firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    checkIfUserLoggedIn();
    super.initState();
  }

  checkIfUserLoggedIn() async {
//    await googleSignIn.signOut();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//    sharedPreferences.setString("id", '');
    bool userLoggedIn = (sharedPreferences.getString('id') ?? '').isNotEmpty;

    if (userLoggedIn) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => Home()));
    } else {
      setState(() {
        pageInitialised = true;
      });
    }
  }

  handleSignIn() async {
    final res = await googleSignIn.signIn();

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    final auth = await res.authentication;

    final credentials = GoogleAuthProvider.getCredential(
        idToken: auth.idToken, accessToken: auth.accessToken);

    final firebaseUser =
        (await firebaseAuth.signInWithCredential(credentials)).user;

    if (firebaseUser != null) {
      final result = (await Firestore.instance
              .collection('users')
              .where('id', isEqualTo: firebaseUser.uid)
              .getDocuments())
          .documents;

      if (result.length == 0) {
        ///new user

        Firestore.instance
            .collection('users')
            .document(firebaseUser.uid)
            .setData({
          "id": firebaseUser.uid,
          "name": firebaseUser.displayName,
          "profile_pic": firebaseUser.photoUrl,
          "created_at": DateTime.now().millisecondsSinceEpoch,
        });

        sharedPreferences.setString("id", firebaseUser.uid);
        sharedPreferences.setString("name", firebaseUser.displayName);
        sharedPreferences.setString("profile_pic", firebaseUser.photoUrl);

        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => Home()));
      } else {
        ///Old user

        sharedPreferences.setString("id", result[0]["id"]);
        sharedPreferences.setString("name", result[0]["name"]);
        sharedPreferences.setString("profile_pic", result[0]["profile_pic"]);

        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => Home()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (pageInitialised)
          ? Center(
              child: RaisedButton(
                child: Text('Sign in'),
                onPressed: handleSignIn,
              ),
            )
          : Center(
              child: SizedBox(
                height: 36,
                width: 36,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
    );
  }
}
