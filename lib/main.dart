import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:sketch_games/adminNAv.dart';
import 'package:sketch_games/adminPanel.dart';
import 'package:sketch_games/appObjects.dart';
import 'package:sketch_games/loginPage.dart';
import 'package:sketch_games/notifiers.dart';
import 'package:sketch_games/routesGen.dart';
import 'firebase_options.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'notifications.dart';



void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Allow only portrait orientation
  ]);

  final BlackBox box = BlackBox();
  PushNotificationService().setupInteractedMessage();
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    if (kDebugMode) print('App received a notification when it was killed');
    box.addNotification(initialMessage);
  }
  FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) async{
          box.addNotification(message);
    },
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage? message) async{
    box.addNotification(message);
  }
  );

  runApp(MyApp(box: box));
}

class MyApp extends StatelessWidget {
  final BlackBox box;
  MyApp({super.key, required this.box});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlackNotifier(
      blackBox: box,
      child: Sizer(
        builder: (BuildContext context, Orientation orientation, DeviceType deviceType) {
          return OverlaySupport.global(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.userChanges(),
                  builder: (context, snapshot){
                  if (snapshot.hasData){
                    return const AdminNav();
                  }else{
                    return MaterialApp(
                      theme: ThemeData(
                        brightness: Brightness.light,
                        useMaterial3: true,
                      ),
                      initialRoute: '/',
                      onGenerateRoute: RouteGenerator.gen,
                    );
                  }

                  }),
            ),
          );
        },
      ),
    );
  }

}
