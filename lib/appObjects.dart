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
  String password;
  int minusSeconds;
  int loggedIn;
  int bonusSeconds;
  String username;
  String gameType;
  List<Device> devices;
  String teamName;
  DateTime? relativeEndTime;
  List<String>? remTimes;

  TeamObject({
    required this.password,
    required this.minusSeconds,
    required this.loggedIn,
    required this.bonusSeconds,
    required this.username,
    required this.gameType,
    required this.devices,
    required this.teamName,
    required this.id,
    this.relativeEndTime
  });

  factory TeamObject.fromJson(Map<String, dynamic> json) => TeamObject(
    id: json['id'],
    password: json["password"],
    minusSeconds: json["minusSeconds"],
    loggedIn: json["loggedIn"],
    bonusSeconds: json["bonusSeconds"],
    username: json["username"],
    gameType: json["gameType"],
    devices: List<Device>.from(json["devices"].map((x) => Device.fromJson(x))),
    teamName: json["teamName"],
    relativeEndTime: json['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(json['endTime']) : null,
  );

  factory TeamObject.fromShot(Map<String, dynamic> json, String id) => TeamObject(
      id: id,
      username: json["username"],
      password: json["password"],
      bonusSeconds: json["bonusSeconds"],
      teamName: json["teamName"],
      minusSeconds: json['minusSeconds'],
      loggedIn: json['loggedIn'],
      gameType: json["gameType"],
      devices: List<Device>.from(json["devices"].map((x) => Device.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    "password": password,
    "minusSeconds": minusSeconds,
    "loggedIn": loggedIn,
    "bonusSeconds": bonusSeconds,
    "username": username,
    "gameType": gameType,
    "devices": List<dynamic>.from(devices.map((x) => x.toJson())),
    "teamName": teamName,
    "endTime": relativeEndTime?.millisecondsSinceEpoch
  };

  int getRemTime(DateTime now, FirstGame game){
    if (relativeEndTime == null){
      return 0;
    }else{
      if (game.startTime != null){
        if (game.startTime!.isBefore(now)){
          return relativeEndTime!.difference(now).inSeconds;
        }else{
          return game.startTime!.difference(now).inSeconds;
        }
      }
      return 0;
    }
  }

  int compareTo(TeamObject other){
    
    if (relativeEndTime!.isBefore(other.relativeEndTime!)) {

      return 1;
    }else if (relativeEndTime!.isAfter(other.relativeEndTime!)){

      return -1;
    }
    return compareNumbers(other);
  }

  int compareNumbers(TeamObject other){
    int? a = int.tryParse(username.substring(4, username.length));
    int? b = int.tryParse(other.username.substring(4, other.username.length));

    if (b == null) return 1;
    if (a == null) return -1;

    if ( a > b) return 1;

    if ( a ==  b) return 0;

    return -1;
  }
}

class Device {
  String name;
  String token;
  String deviceId;

  Device({
    required this.name,
    required this.token,
    required this.deviceId
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    name: json["name"],
    token: json["token"],
    deviceId: json["deviceId"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "token": token,
    'deviceId': deviceId
  };
}


FirstGame firstGameFromJson(String str) => FirstGame.fromJson(json.decode(str));

String firstGameToJson(FirstGame data) => json.encode(data.toJson());

class FirstGame {
  DateTime? startTime;
  DateTime endTime;
  bool paused;
  bool started;
  bool confetti;

  FirstGame({
    this.startTime,
    required this.endTime,
    required this.paused,
    required this.started,
    required this.confetti
  });

  factory FirstGame.fromJson(Map<String, dynamic> json) => FirstGame(
    startTime: json["startTime"],
    endTime: json["endTime"],
    paused: json["paused"],
    started: json["started"],
    confetti: json["confetti"],
  );
  factory FirstGame.fromShot(Map<String, dynamic> json) => FirstGame(
    startTime: json["startTime"]?.toDate(),
    endTime: json["endTime"].toDate(),
    paused: json["paused"],
    started: json["started"],
    confetti: json["confetti"],
  );

  Map<String, dynamic> toJson() => {
    "startTime": startTime,
    "endTime": endTime,
    "paused": paused,
    "started": started,
    "confetti": confetti
  };
  Map<String, dynamic> toShot() => {
    "startTime": startTime != null ? Timestamp.fromMillisecondsSinceEpoch(startTime!.millisecondsSinceEpoch) : null,
    "endTime": Timestamp.fromMillisecondsSinceEpoch(endTime.millisecondsSinceEpoch),
    "paused": paused,
    "started": started,
    "confetti": confetti
  };
}
