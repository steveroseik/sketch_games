import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch_games/appObjects.dart';
import 'package:sketch_games/configuration.dart';


class PushNotificationService {
  Future<void> setupInteractedMessage() async {
    await enableIOSNotifications();
    await registerNotificationListeners();
    // await FirebaseMessaging.instance.subscribeToTopic('ADMINOTIF');
  }
  Future<void> registerNotificationListeners() async {
    final AndroidNotificationChannel channel = androidNotificationChannel();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@drawable/ic_launcher');
    const DarwinInitializationSettings iOSSettings =
    DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings, iOS: iOSSettings);
    flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
// We're receiving the payload as string that looks like this
// {buttontext: Button Text, subtitle: Subtitle, imageurl: , typevalue: 14, type: course_details}
// So the code below is used to convert string to map and read whatever property you want
        if (kDebugMode) print('#Notification: ${details.payload!}');
      },
    );
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) print('Token: $token');

    // Initialize deviceToken
    final prefs = await SharedPreferences.getInstance();
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) async{
      if (kDebugMode) print('accessRefresh');
      try{
        if (prefs.containsKey('loginSession')){
          TeamObject team = teamObjectFromJson(prefs.getString('loginSession')!);
          final deviceId = await getDeviceId();

          final data = await FirebaseFirestore.instance.doc(team.id).get();
          team = teamObjectFromShot(data.data()!,data.reference.path);
          int i = team.devices.indexWhere((e) => e.deviceId == deviceId);
          if (i != -1){
            WriteBatch batch = FirebaseFirestore.instance.batch();
            batch.update(FirebaseFirestore.instance.doc(team.id), {
              'devices': FieldValue.arrayRemove([team.devices[i].toJson()])
            });
            final newData = Map.from(team.devices[i].toJson());
            newData['token'] = newToken;
            batch.update(FirebaseFirestore.instance.doc(team.id), {
              'devices': FieldValue.arrayUnion([newData])
            });
            await batch.commit();
          }
        }
      }catch (e){
        if (kDebugMode) print(e);
      }
    });

    // transfered to main
// onMessage is called when the app is in foreground and a notification is received
//     FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
//       print('$message = firebase_message');
//       print(message?.data);
//       print(message?.messageId);
//       final RemoteNotification? notification = message!.notification;
//       final AndroidNotification? android = message.notification?.android;
// // If `onMessage` is triggered with a notification, construct our own
// // local notification to show to users using the created channel.
//       if (notification != null && android != null) {
//         print('local notif');
//         flutterLocalNotificationsPlugin.show(
//           notification.hashCode,
//           notification.title,
//           notification.body,
//           NotificationDetails(
//             android: AndroidNotificationDetails(
//               channel.id,
//               channel.name,
//               channelDescription: channel.description,
//               icon: android.smallIcon,
//             ),
//           ),
//           payload: message.data.toString(),
//         );
//       }
//     });
  }
  Future<void> enableIOSNotifications() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
  }
  AndroidNotificationChannel androidNotificationChannel() =>
      const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description:
        'This channel is used for important notifications.', // description
        importance: Importance.max,
      );
}