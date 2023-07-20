import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:sketch_games/appObjects.dart';
import 'package:sketch_games/configuration.dart';

class CompleteTeam extends StatefulWidget {
  final TeamObject team;
  const CompleteTeam({super.key, required this.team});

  @override
  State<CompleteTeam> createState() => _CompleteTeamState();
}

class _CompleteTeamState extends State<CompleteTeam> {

  TextEditingController firstName = TextEditingController();
  TextEditingController lastName  = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: GestureDetector(
          onTap: () =>FocusScope.of(context).requestFocus(FocusNode()),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 15.h),
                  Text("What's Your Name",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp)),
                  SizedBox(height: 3.h,),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: firstName,
                          decoration: InputDecoration(
                              filled: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 2.h),
                              errorStyle: const TextStyle(height: 2),
                              fillColor: CupertinoColors.extraLightBackgroundGray,

                              label: const Text('First Name'),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.sp),
                                  borderSide: const BorderSide(color: CupertinoColors.activeBlue, width: 1)
                              ),
                              errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.sp),
                                  borderSide: const BorderSide(color: Colors.red, width: 1)
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.sp),
                                  borderSide: const BorderSide(color: Colors.red, width: 1)
                              ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.sp),
                                  borderSide: const BorderSide(color: CupertinoColors.systemGrey4, width: 1)
                              )
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (text){
                            if (text != null && text.length > 2) {
                              return null;
                            }
                            return 'Invalid first name';
                          },
                        ),
                        SizedBox(height: 1.h),
                        TextFormField(
                          controller: lastName,
                          decoration: InputDecoration(
                              filled: true,
                              contentPadding: EdgeInsets.symmetric( horizontal: 2.h),
                              errorStyle: const TextStyle(height: 2),
                              fillColor: CupertinoColors.extraLightBackgroundGray,

                              label: const Text('Last Name'),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.sp),
                                  borderSide: const BorderSide(color: CupertinoColors.activeBlue, width: 1)
                              ),
                              errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.sp),
                                  borderSide: const BorderSide(color: Colors.red, width: 1)
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.sp),
                                  borderSide: const BorderSide(color: Colors.red, width: 1)
                              ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.sp),
                                  borderSide: const BorderSide(color: CupertinoColors.systemGrey4, width: 1)
                              )
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (text){
                            if (text != null && text.isNotEmpty) {
                              return null;
                            }
                            return 'Enter last name';
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: CupertinoColors.extraLightBackgroundGray,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.sp)
                              )
                          ),
                          onPressed:  () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text('Logout', style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                 SizedBox(width: 4.w),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.sp)
                              )
                          ),
                          onPressed:  () {
                            final valid = formKey.currentState?.validate();
                            if (valid != null && valid){
                              completeLogin();
                            }else{
                              showNotification(context, 'Complete your first and last name fields!', error: true);
                            }
                          },
                          child: FittedBox(child: Text('Confirm', style: const TextStyle(color: Colors.white))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  completeLogin() async{

    if (firstName.text.length > 2 && lastName.text.isNotEmpty){
      final token = await FirebaseMessaging.instance.getToken();
      final deviceId = await getDeviceId();

      final devJson = {
        'name': '${firstName.text.capitalize()} ${lastName.text.capitalize()}',
        'token': token,
        'deviceId': deviceId
      };
      print('we are here');
      await FirebaseFirestore.instance.doc(widget.team.id).update({
        'devices': FieldValue.arrayUnion([devJson])
      });
      print('bravooo');
      // prefs.setString('loginSession', jsonEncode(widget.team.toJson()));
      // widget.team.devices.add(Device.fromJson(devJson));
      Navigator.of(context).pushNamedAndRemoveUntil('/gameOne', (route) => false, arguments: widget.team);
    }else{
      showNotification(context, 'Complete your first and last name fields!', error: true);
    }
  }
}
