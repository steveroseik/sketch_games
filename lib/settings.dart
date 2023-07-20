import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'appObjects.dart';

class SettingsPage extends StatefulWidget {
  final FirstGame game;
  const SettingsPage({super.key, required this.game});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SETTINGS',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700
              ),),
              SizedBox(height: 3.h),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.sp)
                ),
                tileColor: CupertinoColors.extraLightBackgroundGray,
                title: Text('Confetti animations'),
                trailing:  Switch.adaptive(
                  value: widget.game.confetti,
                  onChanged: (newValue) async{
                    await FirebaseFirestore.instance.doc('gamesListeners/firstGame').update(
                        {
                          'confetti': newValue
                        });
                    setState(() => widget.game.confetti = newValue);
                  },
                ),
              ),
              SizedBox(height: 1.h),
              ListTile(
                onTap: (){
                  Navigator.of(context).pushNamed('/nfc');
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.sp)
                ),
                tileColor: CupertinoColors.extraLightBackgroundGray,
                title:  const Text('NFC Manager'),
                trailing: const FittedBox(
                  child: Row(
                    children: [
                      // Icon(Icons.nfc_rounded),
                      Icon(Icons.arrow_forward_ios_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
