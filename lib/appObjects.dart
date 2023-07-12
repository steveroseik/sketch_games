import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

Widget loadingWidget(bool loading, {double? opacity}){
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
    child: loading ? Scaffold(
      backgroundColor: Colors.white.withOpacity(opacity?? 0.5),
      body: const Center(
        child: SpinKitFadingCube(
          color: Colors.black,
          size: 30,
        ),
      ),
    ) : Container(),
  );
}

TeamObject teamObjectFromJson(String str) => TeamObject.fromJson(jsonDecode(str));
TeamObject teamObjectFromShot(Map<String, dynamic> data, String id) => TeamObject.fromShot(data, id);
String teamObjectToJson(TeamObject data) => json.encode(data.toJson());

List<TeamObject> teamObjectListFromShot(List<QueryDocumentSnapshot<Map<String, dynamic>>> list) => list.map((e) => TeamObject.fromShot(e.data(), e.reference.path)).toList();

class TeamObject {
  String id;
  String username;
  String password;
  int bonusSeconds;
  int minusSeconds;
  String teamName;
  int loggedIn;
  DateTime? relativeEndTime;


  TeamObject({
    required this.id,
    required this.username,
    required this.password,
    required this.bonusSeconds,
    required this.teamName,
    required this.minusSeconds,
    required this.loggedIn
  });

  factory TeamObject.fromJson(Map<String, dynamic> json) => TeamObject(
    id: json["id"],
    username: json["username"],
    password: json["password"],
    bonusSeconds: json["bonusSeconds"],
    teamName: json["teamName"],
    minusSeconds: json['minusSeconds'],
    loggedIn: json['loggedIn']
  );

  factory TeamObject.fromShot(Map<String, dynamic> json, String id) => TeamObject(
      id: id,
      username: json["username"],
      password: json["password"],
      bonusSeconds: json["bonusSeconds"],
      teamName: json["teamName"],
      minusSeconds: json['minusSeconds'],
      loggedIn: json['loggedIn']
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
    "password": password,
    "bonusSeconds": bonusSeconds,
    "teamName": teamName,
    "minusSeconds": minusSeconds,
    "loggedIn": loggedIn
  };

  int compareTo(TeamObject other){
    if (relativeEndTime!.isBefore(other.relativeEndTime!)) {
      return 1;
    }else if (relativeEndTime!.isAtSameMomentAs(other.relativeEndTime!)){
      return 0;
    }
    return -1;
  }
}

FirstGame firstGameFromJson(String str) => FirstGame.fromJson(json.decode(str));

String firstGameToJson(FirstGame data) => json.encode(data.toJson());

class FirstGame {
  DateTime? startTime;
  DateTime endTime;
  bool paused;
  bool started;

  FirstGame({
    this.startTime,
    required this.endTime,
    required this.paused,
    required this.started,
  });

  factory FirstGame.fromJson(Map<String, dynamic> json) => FirstGame(
    startTime: json["startTime"],
    endTime: json["endTime"],
    paused: json["paused"],
    started: json["started"],
  );
  factory FirstGame.fromShot(Map<String, dynamic> json) => FirstGame(
    startTime: json["startTime"]?.toDate(),
    endTime: json["endTime"].toDate(),
    paused: json["paused"],
    started: json["started"],
  );

  Map<String, dynamic> toJson() => {
    "startTime": startTime,
    "endTime": endTime,
    "paused": paused,
    "started": started,
  };
  Map<String, dynamic> toShot() => {
    "startTime": startTime != null ? Timestamp.fromMillisecondsSinceEpoch(startTime!.millisecondsSinceEpoch) : null,
    "endTime": Timestamp.fromMillisecondsSinceEpoch(endTime.millisecondsSinceEpoch),
    "paused": paused,
    "started": started,
  };
}
