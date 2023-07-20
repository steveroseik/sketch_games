

import 'dart:collection';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:sketch_games/appObjects.dart';

class BlackNotifier extends InheritedNotifier<BlackBox>{

  const BlackNotifier({
    Key? key,
    required BlackBox blackBox,
    required Widget child}) : super (key: key, notifier: blackBox, child: child);

  static of(BuildContext context){
    return context.dependOnInheritedWidgetOfExactType<BlackNotifier>()!.notifier;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return oldWidget != this;
  }
}

class BlackBox extends ChangeNotifier{
  Queue<NotifObject> missedNotifications = Queue<NotifObject>();
  List<TeamObject> teams = [];

  get hasQueue => missedNotifications.isNotEmpty;

  addNotification(RemoteMessage? message){
    if (message != null){
      final notif = NotifObject(title: message.notification?.title, message: message.notification?.body,
          data: message.data);
      missedNotifications.add(notif);
      notifyListeners();
    }
  }

  addMessage(NotifObject message){
    missedNotifications.add(message);
    notifyListeners();
  }

  NotifObject removeNotification(){
    return missedNotifications.removeFirst();
  }

  notify(){
    notifyListeners();
  }
}

class NotifObject {
  String? title;
  String? message;
  Map<String, dynamic>? data;
  Color? color;
  bool? vibrate;

  NotifObject({this.title, this.message, this.data, this.color, this.vibrate});
}