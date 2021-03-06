import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splash_screen_view/SplashScreenView.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
      home: SplashScreenView(
    home: MyApp(),text: "Beaconer",
    textStyle: TextStyle(fontSize: 25),
    textType: TextType.TyperAnimatedText,
    imageSrc: "assets/logo.png",
    imageSize: 400,
    duration: 4000,)));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _beaconResult = "Not Scanned Yet";
  int _nrMessaggesReceived = 0;
  var isRunning = false;

  final StreamController<String> beaconEventsController =
  StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    beaconEventsController.close();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (Platform.isAndroid) {
      //Prominent disclosure
      await BeaconsPlugin.setDisclosureDialogMessage(
          title: "Need Location Permission",
          message: "This app collects location data to work with beacons.");

      //Only in case, you want the dialog to be shown again. By Default, dialog will never be shown if permissions are granted.
      //await BeaconsPlugin.clearDisclosureDialogShowFlag(false);
    }

    BeaconsPlugin.listenToBeacons(beaconEventsController);

    await BeaconsPlugin.addRegion(
        "BeaconType1", "909c3cf9-fc5c-4841-b695-380958a51a5a");
    await BeaconsPlugin.addRegion(
        "BeaconType2", "6a84c716-0f2a-1ce9-f210-6a63bd873dd9");

    beaconEventsController.stream.listen(
            (data) {
          if (data.isNotEmpty) {
            setState(() {
              _beaconResult = data;
              _nrMessaggesReceived++;
            });
            print("Beacons DataReceived: " + data);
            BeaconsPlugin.stopMonitoring;
          }
        },
        onDone: () {},
        onError: (error) {
          print("Error: $error");
        });

    //Send 'true' to run in background
    await BeaconsPlugin.runInBackground(true);

    if (Platform.isAndroid) {
      BeaconsPlugin.channel.setMethodCallHandler((call) async {
        if (call.method == 'scannerReady') {
          await BeaconsPlugin.startMonitoring;
          setState(() {
            isRunning = true;
          });
        }
      });
    } else if (Platform.isIOS) {
      await BeaconsPlugin.startMonitoring;
      setState(() {
        isRunning = true;
      });
    }

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Monitoring Beacons'),
          backgroundColor: Colors.brown,
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              
              Image.asset("assets/logonew.png", height: 300, width: 300,),
              
              if(_beaconResult!="Not Scanned Yet")
              FutureBuilder(
                future: FirebaseFirestore.instance.collection("Messages").doc(jsonDecode(_beaconResult)['uuid']).get(),
                builder: (context, snapshot){
                  if(snapshot.connectionState == ConnectionState.done && snapshot.hasData){
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(snapshot.data['val'], style: TextStyle(fontSize: 20),),
                    );
                  }
                  return Center(child: Container(width: 50, height: 50, child: CircularProgressIndicator(),),);
                },
              ),
              if(_beaconResult=="Not Scanned Yet")  Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_beaconResult, style: TextStyle(fontSize: 20),),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
              ),
              SizedBox(
                height: 20.0,
              ),

              SizedBox(
                height: 20.0,
              ),
              Visibility(
                child: RaisedButton(
                  color: Colors.brown,
                  onPressed: () async {
                    initPlatformState();
                    await BeaconsPlugin.startMonitoring;
                    setState(() {
                      isRunning = true;
                    });

                  },
                  padding: EdgeInsets.all(12),
                  child: Text('Start Scanning', style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              )
            ],
          ),
        ),

    );
  }
}