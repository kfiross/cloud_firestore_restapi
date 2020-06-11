import 'package:cloud_firestore_restapi/cloud_firestore_restapi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() {
  Firestore.initializeApp(
    projectId: 'catch-my-match',
    webKey: 'AIzaSyCbp_ROK6QyqUoTDZEziFBkDmezdLPQj5I',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget{
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();


    // not using firebase auth
    var authResults = await Firestore.instance.signInOrSignUp(
      email: "dana@gmail.com",
      password: "123456",
      action: AuthAction.signInWithPassword
    );

    // Firebase authflutter
    var user =  await FirebaseAuth.instance.currentUser();
    var tokenResults = await user.getIdToken();
    var token = tokenResults.token;
    await Firestore.instance.config.setToken(token);



    var collection = Firestore.instance.collection("users");
    var snapshot = await collection.document("some_id").get();
    if(snapshot.exists){
      print('key =${snapshot.key}');
      print(snapshot.data);
    }
    else{
      print('doc not exists!');
    }
    print('\n');

    var snapshot2 = await collection.document("0X3TSmf9m2emshH61mgKppuA6Tb2").get(authResults['idToken']);
    if(snapshot2.exists){
      print('key =${snapshot2.key}');
      print(snapshot2.data);
    }
    else{
      print('doc not exists!');
    }
    print('\n');

   //  snapshot.data;

    var collectionSnapshots = await collection.snapshots();
    collectionSnapshots.forEach((snapshot) {
      Map map = snapshot.data;
      String key = snapshot.key;
      print(map);
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
    );
  }
}