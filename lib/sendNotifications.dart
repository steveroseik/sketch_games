import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:sketch_games/configuration.dart';
import 'package:sketch_games/notifiers.dart';
import 'appObjects.dart';

class NotificationsPage extends StatefulWidget {
  final List<TeamObject> teams;
  const NotificationsPage({super.key, required this.teams});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {


  TextEditingController title = TextEditingController();
  TextEditingController message = TextEditingController();

  List<String> images = [
  'https://iili.io/HL0Z1kX.png',
  'https://iili.io/HLlDav1.md.png',
  'https://iili.io/HLlDcyF.md.png',
  'https://iili.io/HLlNElV.png',
  'https://iili.io/HLlNVHP.png',
  'https://iili.io/HLlNGUB.png',
  'https://iili.io/HLlD1ja.md.png'
  ];
  List<ImageItem> items = [];
  List<int> selectedSequence = [];
  String? token;

  bool challenge = false;
  @override
  void initState() {
    items = List<ImageItem>.generate(images.length, (index) => ImageItem(isSelected: false, url: images[index]));
    widget.teams.sort((a, b) => a.compareNumbers(b));
    getToken();
    super.initState();
  }

  getToken() async{
    token = await FirebaseMessaging.instance.getToken();
  }

  @override
  void dispose() {
    title.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BlackBox box = BlackNotifier.of(context);
    final teams = box.teams;
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusScopeNode()),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: Text('Notifications Center'),),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: 2.h),
                TextFormField(
                  controller: title,
                  decoration: InputDecoration(
                      filled: true,
                      contentPadding: EdgeInsets.symmetric( horizontal: 2.h),
                      errorStyle: const TextStyle(height: 2),
                      fillColor: CupertinoColors.white,

                      label: const Text('Notification Title'),
                      labelStyle: TextStyle(color: Colors.grey.shade700),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.sp),
                          borderSide: const BorderSide(color: CupertinoColors.activeBlue, width: 1)
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.sp),
                          borderSide: const BorderSide(color: CupertinoColors.systemGrey4, width: 1)
                      )
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: message,
                  decoration: InputDecoration(
                      filled: true,
                      contentPadding: EdgeInsets.symmetric( horizontal: 2.h),
                      errorStyle: const TextStyle(height: 2),
                      fillColor: CupertinoColors.white,

                      label: const Text('Message'),
                      labelStyle: TextStyle(color: Colors.grey.shade700),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.sp),
                          borderSide: const BorderSide(color: CupertinoColors.activeBlue, width: 1)
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.sp),
                          borderSide: const BorderSide(color: CupertinoColors.systemGrey4, width: 1)
                      )
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Challenges',
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600
                    ),),
                ),
                SizedBox(height: 1.h),
                ListTile(
                  onTap: () {
                    Navigator.of(context).pushNamed('/selectSequence').then((value) {
                      if (value != null && value is List<int>){
                        selectedSequence = value;
                        if (!challenge) challenge = true;
                        setState(() {});
                      }
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.sp)
                  ),
                  tileColor: CupertinoColors.extraLightBackgroundGray,
                  leading: Icon(Icons.attractions_outlined),
                  title: Text('Attach Sequence Challenge', style: TextStyle(fontSize: 10.sp),),
                  trailing:  Switch.adaptive(
                    value: challenge,
                    onChanged: (newValue) async{
                      if (newValue){
                        Navigator.of(context).pushNamed('/selectSequence').then((value) {
                          if (value != null && value is List<int>){
                            selectedSequence = value;
                            setState(() => challenge = newValue);
                          }
                        });
                      }else{
                        setState(() => challenge = newValue);
                      }

                    },
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Image Notification',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600
                    ),),
                ),
                Builder(
                  builder: (context) {
                    return Container(height: 7.h,
                    margin: EdgeInsets.symmetric(vertical: 2.h),
                    child: ListView.separated(
                        itemCount: items.length,
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (context, index){
                          return SizedBox(width: 3.w);
                        },
                        itemBuilder: (context, index){
                          return InkWell(
                            borderRadius: BorderRadius.circular(10.sp),
                            onTap: (){
                              if (items[index].isSelected){
                                items[index].isSelected = false;
                              }else{
                                for (var e in items){
                                  e.isSelected = false;
                                }
                                items[index].isSelected = true;
                              }
                              setState(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.sp),
                                  border: Border.all(color: items[index].isSelected ? Colors.blueAccent.shade700 :
                                  CupertinoColors.extraLightBackgroundGray)
                              ),
                              padding: EdgeInsets.all(2.w),
                              child: Image.network(items[index].url),
                            ),
                          );
                        }),
                    );
                  }
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async{
                      if (token == null || token!.isEmpty){
                        showNotification(context, 'You did not enable notifications on this device', error: true);
                      }else{
                        sendNotification(token!);
                      }

                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: CupertinoColors.extraLightBackgroundGray,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.sp))
                    ),
                    icon: Icon(CupertinoIcons.lab_flask),
                    label: Text('Test Notification',
                      style: TextStyle(
                        fontSize: 10.sp,
                      ),),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async{

                      sendNotification('/topics/general');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.sp))
                    ),
                    icon: Icon(Icons.send_outlined, color: Colors.white),
                    label: Text('Send to all',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                      ),),
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Registered Players',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600
                    ),),
                ),
                SizedBox(height: 1.h),
                ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: teams.length,
                    itemBuilder: (context, index){
                      final team = teams[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 1.h),
                        padding: EdgeInsets.all(1.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.sp),
                          border: Border.all(color: Colors.blueAccent.shade700)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: Text(team.teamName,
                            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Quartzo',
                            fontSize: 15.sp),)),
                            team.devices.isEmpty ? const Center(child: Text('No registered members!')) :
                            ListView.builder(
                                itemCount: team.devices.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, jindex){
                                  return ElevatedButton.icon(
                                      onPressed: (){
                                        sendNotification(team.devices[jindex].token);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.sp)
                                        )
                                      ),
                                      icon: const Icon(Icons.send_outlined),
                                      label: Text('Send to ${team.devices[jindex].name}'));
                                }),
                            SizedBox(height: 0.5.h),
                            team.devices.isEmpty ? Container() : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                  onPressed: (){
                                    sendNotification('/topics/${team.username}');
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.sp)
                                      )
                                  ),
                                  icon: Icon(Icons.send_outlined),
                                  label: Text('Send to all ${team.teamName} members')),
                            )
                          ],
                        ),
                      );
                })
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendNotification(
      String to) async {

    FocusScope.of(context).requestFocus(FocusNode());
    if (title.text.isEmpty && message.text.isEmpty){
      showNotification(context, "You need to add title OR message in order to send notifications!", error: true);
      return;
    }
    final data = challenge ?
    {
      "sequenceCodes": selectedSequence
    } :
    {
      'type': 'quest'
    };
    final imgChosen = items.firstWhere((e) => e.isSelected, orElse: () => ImageItem(isSelected: false, url: ''));

    const String apiKey = 'AAAAApfnhD8:APA91bFWL6YCbIfHB_mAdiQIQCNrapZ0q-Ssm_QkvuK47xKUIOIidct5r-64XuuYyA4jq6jyEWnEQcG7Fv5lo0gdl3Q1p44r-J0IXOZNcmCXieXwB4rFKcdaO6BdmxXbxFOsCZ-PRzaR';
    const String url = 'https://fcm.googleapis.com/fcm/send';

    final Map<String, dynamic> body = {
      'to': to,
      'notification': {
        'title': title.text,
        'body': message.text,
        'image': imgChosen.url,
      },
      'data': data,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$apiKey',
    };

    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      showNotification(context, 'Notification sent successfully');
    } else {
      // Error occurred while sending notification
      showNotification(context, 'Error sending notification: ${response.statusCode}', error: true);
    }
  }
}


class ImageItem{
  String url;
  bool isSelected = false;

  ImageItem({
    required this.isSelected,
    required this.url
});
}

