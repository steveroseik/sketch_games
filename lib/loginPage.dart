import 'dart:convert';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exif/exif.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:sketch_games/appObjects.dart';
import 'package:sketch_games/configuration.dart';
import 'package:vibration/vibration.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final usernameField = TextEditingController();
  final passField= TextEditingController();

  bool userError = false;
  bool passError = false;
  bool loading = true;
  bool viewPass = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => checkSession());
    super.initState();
  }




  checkSession() async{

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getKeys().contains('loginSession')){
      TeamObject team = teamObjectFromJson(prefs.getString('loginSession')!);

      // final dataCheck = await FirebaseFirestore.instance.collectionGroup('teams')
      //     .where('username', isEqualTo: team.username).where('password', isEqualTo: team.password).get();
      // if (dataCheck.docs.isNotEmpty && dataCheck.docs.first.data()['loggedIn'] > 0){
      //   team = teamObjectFromShot(dataCheck.docs.first.data(), team.id);
      //   prefs.setString('loginSession', jsonEncode(team.toJson()));
      if (mounted) Navigator.of(context).popAndPushNamed('/gameOne', arguments: team);
    }else{
      prefs.remove('loginSession');
      setState(() {
        loading = false;
      });
    }


    // }else{
    //   setState(() {
    //     loading = false;
    //   });
    // }


  }

  @override
  void dispose() {
    super.dispose();

  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Stack(
              children: [
                Column(
                  children: [
                    Text('SKETCH GAMES',
                    style: TextStyle(
                      fontFamily: 'Quartzo',
                      fontSize: 40.sp
                    ),
                    textAlign: TextAlign.center,),
                    SizedBox(height: 10.h,),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: usernameField,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.h),
                              errorStyle: const TextStyle(height: 2),
                              label: Text('Username'),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.sp)
                                )
                            ),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (text){
                              if (text != null && text.isNotEmpty) {
                                userError = false;
                                return null;
                              }
                              userError = true;
                              return 'input username';
                            },
                          ),
                          SizedBox(height: 2.h,),
                          TextFormField(
                            controller: passField,
                            obscureText: !viewPass,
                            decoration: InputDecoration(
                                suffixIcon: InkWell(
                                    onTap: (){
                                      setState(() {
                                        viewPass = !viewPass;
                                      });
                                    },
                                    child: Icon(viewPass ? CupertinoIcons.eye_slash : CupertinoIcons.eye_solid)),
                                contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.h),
                                label: Text('Password'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.sp)
                              )
                            ),
                            onFieldSubmitted: (_) {
                              if (!loading) login();
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (text){
                              if (text != null && text.isNotEmpty) {
                                userError = false;
                                return null;
                              }
                              userError = true;
                              return 'input a password';
                            },
                          ),
                          SizedBox(height: 2.h,),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.sp),
                                )
                              ),
                              onPressed: loading ? null : login,
                                child: const Text('LOGIN',
                                  style: TextStyle(
                                    fontFamily: 'Quartzo',
                                ),),),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    DefaultTextStyle(
                      key: Key('khasdhjkadshjk'),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.sp,
                          fontFamily: 'Quartzo',
                          color: Colors.black
                      ),

                      child: AnimatedTextKit(
                        pause: const Duration(milliseconds: 500),
                        isRepeatingAnimation: true,
                        repeatForever: true,
                        animatedTexts: [
                          RotateAnimatedText("DEVELOPED BY"),
                          RotateAnimatedText("STEVE ROSEIK"),
                        ],
                        onTap: (){

                        },
                      ),
                    ),
                  ],
                ),
                loading ? loadingWidget(loading, opacity: 0.3) : Container()
              ],
            ),
          ),
        ),
      ),
    );
  }

  login() async{
    final formValid = _formKey.currentState?.validate();

    if (formValid?? false){
      setState(() {
        loading = true;
      });


      try{
        if (validateEmail(usernameField.text)){
          final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: usernameField.text, password: passField.text);
          if (cred.user != null) Navigator.of(context).popAndPushNamed('/admin');
        }else{


          final data = await FirebaseFirestore.instance.collectionGroup('teams')
              .where('username', isEqualTo: usernameField.text)
              .where('password', isEqualTo: passField.text).get();
          if (data.docs.isNotEmpty){
            print('goood');
            final prefs = await SharedPreferences.getInstance();
            prefs.remove('loginSession');
            final team = teamObjectFromShot(data.docs.first.data(), data.docs.first.reference.path);
            print('teamID: ${team.id}');
            if (team.devices.length >= 3){
             print(data.docs.first.data());
              showNotification(context, 'This team has reached maximum login sessions, Contact your admin!', error: true);
            }else{
              final deviceId = await getDeviceId();
              if ((deviceId.isNotEmpty)){
                if (team.devices.indexWhere((e) => e.deviceId == deviceId) != -1){
                  // old team member
                  prefs.setString('loginSession', jsonEncode(team.toJson()));

                  Navigator.of(context).popAndPushNamed('/gameOne', arguments: team);
                }else{
                  // new team member
                  Navigator.of(context).pushNamed('/completeMember', arguments: team).then((value) {
                    usernameField.clear();
                    passField.clear();
                  });
                }
              }else{
                showNotification(context, 'You need to allow notifications to continue!', error: true);
              }
            }
          }else{
            showNotification(context, 'Incorrect team credentials.', error: true);
          }
        }
      }on FirebaseException catch (e){
        showNotification(context, e.message?? 'An error occured', error: true);
      }
      setState(() {
        loading = false;
      });
    }
  }
}
