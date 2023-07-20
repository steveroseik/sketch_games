
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:sizer/sizer.dart';

import 'appObjects.dart';

class MyCustomRoute<T> extends MaterialPageRoute<T> {
  MyCustomRoute({ required WidgetBuilder builder, RouteSettings? settings })
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return ScaleTransition(scale: animation, child:
    SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.5,0), end: const Offset(0,0)).animate(animation),
      child: child,
    ));
  }
}

bool validateEmail(String email) {
  // Regular expression pattern for email validation
  String pattern =
      r'^[\w-]+(\.[\w-]+)*@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,7}$';

  RegExp regExp = RegExp(pattern);
  return regExp.hasMatch(email);
}

void showNotification(BuildContext context, String message, {bool? error}) {
  final snackBar = SnackBar(content: Text(message),
      backgroundColor: error?? false ? Colors.red : Colors.green);

  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Future<bool> showAlertDialog(BuildContext context, {required String title, required String message}) async{

  bool confirm = false;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.sp)
        ),
        title: Text(title, style: TextStyle(fontSize: 13.sp)),
        content: Text(message,
          style: TextStyle(fontSize: 10.sp),),
        actions: [
          FilledButton(
            child: Text("Cancel", style: TextStyle(color: Colors.white)),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red
            ),
            onPressed:  () {
              Navigator.of(context).pop(false);
            },
          ),
          FilledButton(
            child: Text("Confirm"),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black
            ),
            onPressed:  () {
              Navigator.of(context).pop(true);
            },
          )
        ],
      );
    },
  ).then((value) {
    confirm = value;
  });
  return confirm;
}

Future<String?> showTextDialog(BuildContext context, {required String textLabel, required String title}) async{

  bool confirm = false;
  TextEditingController ctrl = TextEditingController();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.sp)
        ),
        title: Text(title, style: TextStyle(fontSize: 13.sp)),
        content: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.h),
              label: Text(textLabel),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.sp)
              )
          ),
        ),
        actions: [
          FilledButton(
            child: Text("Cancel", style: TextStyle(color: Colors.white)),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red
            ),
            onPressed:  () {
              Navigator.of(context).pop(false);
            },
          ),
          FilledButton(
            child: Text("Confirm"),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black
            ),
            onPressed:  () {
              Navigator.of(context).pop(true);
            },
          )
        ],
      );
    },
  ).then((value) {
    confirm = value;
  });
  return confirm ? ctrl.text : null;
}

Future<int> showNumberPicker(context) async{

  int number = 0;
  await showDialog(
    context: context,
    builder: (context){
      return AlertDialog(
        title: Text('Total Number of Teams'),
        content: SizedBox(
          height: 30.h,
          child: CupertinoPicker(
            magnification: 1.2,
            backgroundColor: Colors.transparent,
            itemExtent: 50, //height of each item
            looping: true,
            children:
            List<String>.generate(30, (i) => (i+1).toString()).map((e) => Center(
                child: Text(e,
                  style: TextStyle(fontSize: 15.sp),))).toList(),
            onSelectedItemChanged: (index) {
              number = index+1;
            },
          ),
        ),
        actions: [
          FilledButton(
            child: Text("Cancel", style: TextStyle(color: Colors.white)),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red
            ),
            onPressed:  () {
              Navigator.of(context).pop(false);
            },
          ),
          FilledButton(
            child: Text("Confirm"),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black
            ),
            onPressed:  () {
              Navigator.of(context).pop(true);
            },
          )
        ],
      );
    }
  ).then((value) {
    if (value?? false) {
      if (number == 0) number = 1;
    }else{
      number = 0;
    }
  });

  return number;
}

class TeamObjectBox extends StatefulWidget {
  final TeamObject team;
  final ValueNotifier<bool> refresher;
  const TeamObjectBox({super.key, required this.team, required this.refresher});

  @override
  State<TeamObjectBox> createState() => _TeamObjectBoxState();
}

class _TeamObjectBoxState extends State<TeamObjectBox> {

  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(10.sp)
        ),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.team.teamName,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.sp),),
                Spacer(),
                InkWell(
                  onTap: () async{
                    try{
                      final resp = await showAlertDialog(
                          context, title: 'Delete Team', message: '${widget.team.teamName} will be DELETED Forever.');
                      if (!resp) return;
                      await FirebaseFirestore.instance
                          .doc(widget.team.id).delete();
                      widget.refresher.value = !widget.refresher.value;
                    }catch (e){
                      print(e);
                    }

                  },
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.sp),
                        border: Border.all(color: Colors.red, width: 1),
                        color: Colors.red
                    ),
                    child: Icon(CupertinoIcons.xmark, color: Colors.black, size: 10.sp,),
                  ),
                )
              ],
            ),
            SizedBox(height: 2.h,),
            RichText(
                text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    text: 'Username: ',
                    children: [
                      TextSpan(text: widget.team.username,
                          style: const TextStyle(fontWeight: FontWeight.w800))
                    ]
                )),
            SizedBox(height: 1.h,),
            Row(
              children: [
                RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      text: 'Password: ',
                      children: [
                        TextSpan(text: obscure ? "********" : widget.team.password,
                            style: const TextStyle(fontWeight: FontWeight.w800))
                      ]
                    )),
                Spacer(),
                InkWell(
                  onTap: (){
                    setState(() {
                      obscure = !obscure;
                    });
                  },
                  child: Icon(!obscure ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye),
                )
              ],
            ),
            widget.team.devices.isEmpty ? Container() :
            Center(
              child: ElevatedButton(
                  onPressed: (){
                    Navigator.of(context).pushNamed('/teamMembers', arguments: widget.team);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CupertinoColors.extraLightBackgroundGray,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.sp))
                  ),
                  child: Text('${widget.team.devices.length} Registered Member'
                      '${widget.team.devices.length == 1 ? '' : 's'}')),
            )
          ],
        )
    );
  }
}


List<int> extractListOfDuration(int seconds){
  int tTime = seconds;
  int tDays = 0;
  int tHours = 0;
  int tMinutes= 0;
  int tSeconds= 0;
  if (tTime >= (60*60*24)){
    tDays = tTime ~/ (60*60*24);
    tTime = tTime % (60*60*24);
  }
  if (tTime >= (60*60)) {
    tHours = tTime ~/ (60*60);
    tTime = tTime % (60*60);
  }
  if (tTime >= 60){
    tMinutes = tTime ~/ 60;
    tTime = tTime % 60;

  }
  tSeconds = tTime;

  return [tDays, tHours, tMinutes, tSeconds];
}


bool isSameDay(DateTime dateTime1, DateTime dateTime2) {
  return dateTime1.year == dateTime2.year &&
      dateTime1.month == dateTime2.month &&
      dateTime1.day == dateTime2.day;
}


extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  String capitalizeAllWords() {
    final words = split(' ');
    final capitalizedWords = words.map((word) => word.capitalize());
    return capitalizedWords.join(' ');
  }
}



String formatNumber(int x){
  if (x.toString().length == 1){
    return '0${x.toString()}';
  }
  return x.toString();
}

Widget timeCounter(List<String> times, {Color counterColor = Colors.black}){
  return  Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(times[0],
              style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                  fontSize: 25.sp),
              textAlign: TextAlign.center,),
          ),
          Text(':', style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
              fontSize: 25.sp),),
          FittedBox(
            child: Text(times[1],
              style: TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                  fontSize: 25.sp),
              textAlign: TextAlign.center,),
          ),
          Text(':', style: TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
              fontSize: 25.sp),),
          FittedBox(
            child: Text(times[2],
              style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                  fontSize: 25.sp),
              textAlign: TextAlign.center,),
          ),
          Text(':', style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
              fontSize: 25.sp),),
          FittedBox(
            child: Text(times[3],
              style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                  fontSize: 25.sp),
              textAlign: TextAlign.center,),
          )

        ],
      )
  );
}

Future<String> getDeviceId() async{
  String deviceId = '';
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    await deviceInfoPlugin.androidInfo.then((AndroidDeviceInfo androidInfo) {
      deviceId = androidInfo.androidId;
    });
  } else if (Platform.isIOS) {
    await deviceInfoPlugin.iosInfo.then((IosDeviceInfo iosInfo) {
      deviceId = iosInfo.identifierForVendor;
    });
  }
  return deviceId;
}

List<String> splitStringIntoParts(String input, double ratio) {
  List<String> words = input.split(' ');
  int wordCount = words.length;

  int firstPartCount = (wordCount * ratio).ceil();

  List<String> firstPart = words.sublist(0, firstPartCount);
  List<String> secondPart = words.sublist(firstPartCount);

  return [firstPart.join(' '), secondPart.join(' ')];
}

