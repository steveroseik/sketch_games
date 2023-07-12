
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:confetti/confetti.dart';
import 'appObjects.dart';
import 'configuration.dart';
import 'package:overlay_support/overlay_support.dart';

class Game1MainScreen extends StatefulWidget {
  const Game1MainScreen({super.key, required this.team});

  final TeamObject team;

  @override
  State<Game1MainScreen> createState() => _Game1MainScreenState();
}

class _Game1MainScreenState extends State<Game1MainScreen> with TickerProviderStateMixin, WidgetsBindingObserver{

  DateTime? startTime;
  DateTime? endTime;
  late DateTime currentTime;

  DateTime get teamEndTime => endTime!
      .add(Duration(seconds: theTeam.bonusSeconds)).subtract(Duration(seconds: theTeam.minusSeconds));

  double remainingPercent = 0.0;

  Duration? timeUntilEnd;
  ConnectivityResult connection = ConnectivityResult.none;

  Timer? gameTimer;
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> gameUpdatesSubscription;
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> teamQ;
  late StreamSubscription<ConnectivityResult> connectivitySubscription;

  bool deadTime = false;
  bool isGameStreamActive = false;
  bool mobileConnectivity = false;
  bool gameOff = false;
  bool gameStarted = false;
  bool gamePaused = true;
  bool notifyUser = false;

  String notificationMessage = '';
  Color notificationColor = Colors.white;

  Color counterColor = Colors.red;
  Color progressColor = Colors.green;
  Color box2Color = Colors.black;
  Color box3Color = Colors.black;
  Color box4Color = Colors.black;



  late Animation<Color?> animation1;
  late AnimationController controller1;
  late Animation<Color?> animation2;
  late AnimationController controller2;

  String days = '00';
  String hours = '00';
  String seconds = '00';
  String minutes = '00';
  String initialText = '';

  late TeamObject theTeam;

  final confettiController = ConfettiController(duration: const Duration(seconds: 3));


  final player = AudioPlayer();                   // Create a player

  @override
  void initState() {
    theTeam = widget.team;
    initGameTimer();
    initListener();
    initConnectivityListener();
    player.setAsset('assets/typing.mp3');
    controller1 = AnimationController(duration: const Duration(milliseconds: 750), vsync: this);
    animation1 = ColorTween(begin: Colors.black, end: Colors.red).animate(controller1);
    controller2 = AnimationController(duration: const Duration(milliseconds: 750), vsync: this);
    animation2 = ColorTween(begin: Colors.red, end: Colors.black).animate(controller2);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  initConnectivityListener(){
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        connection = result;
        if (connection == ConnectivityResult.none){
          mobileConnectivity = false;
        }else{
          mobileConnectivity = true;
        }
      });
    });
  }
  initGameTimer(){
    final appStartTime = DateTime.now();
    currentTime = DateTime.now();
    gameTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      currentTime = currentTime.add(const Duration(milliseconds: 1000));
      // kill bill
      if (teamEndTime.isBefore(currentTime)){
        if (!deadTime) {
          setState(() {
            deadTime = true;
          });
        }
      }else{
        if (deadTime) {
          setState(() {
          deadTime = false;
        });
        }

      }


      if (startTime != null && !deadTime){
        if (gameOff) gameOff = false;
        if (startTime!.isAfter(currentTime)){
          if (counterColor != Colors.red || progressColor != Colors.red ) {
            progressColor = Colors.red;
            counterColor = Colors.red;
          }
          if (gameStarted) gameStarted = false;
          setState(() {
            remainingPercent = startTime!.difference(currentTime).inSeconds / startTime!.difference(appStartTime).inSeconds;
            setRemText(startTime!.difference(currentTime).inSeconds);
          });
        }else{
          if (gamePaused){
            //wait here;
            if (!gameStarted) {
              gameStarted = true;
              timeUntilEnd = teamEndTime.difference(currentTime);
              double tPerc = (timeUntilEnd!.inSeconds / teamEndTime.difference(startTime!).inSeconds.abs());
              remainingPercent =  tPerc > 1 ? 1 : tPerc < 0 ? 0 : tPerc;
              setRemText(teamEndTime.difference(currentTime).inSeconds);
            }
            if (counterColor != Colors.orangeAccent || progressColor != Colors.orangeAccent ) {
              setState(() {
              progressColor = Colors.orangeAccent;
              counterColor = Colors.orangeAccent;
            });

            }
          }else{
            if (counterColor != Colors.green) {
              progressColor = Colors.green;
              counterColor = Colors.green;
            }
            setState(() {
              if (!gameStarted) gameStarted = true;
              timeUntilEnd = teamEndTime.difference(currentTime);
              double tPerc = (timeUntilEnd!.inSeconds / teamEndTime.difference(startTime!).inSeconds.abs());
              remainingPercent =  tPerc > 1 ? 1 : tPerc < 0 ? 0 : tPerc;
              setRemText(teamEndTime.difference(currentTime).inSeconds);
            });
          }
        }
      }else{
        if (startTime == null){
          if (!gameOff) {
            setState(() {
              gameOff = true;
              progressColor = Colors.red;
              counterColor = Colors.red;
            });
          }
        }else{
          if (counterColor != Colors.red || progressColor != Colors.red){
            setState(() {
              progressColor = Colors.red;
              counterColor = Colors.red;
            });
          }
        }

      }

    });
  }

  initListener() async{

    final query = FirebaseFirestore.instance.collection('gamesListeners')
        .doc('firstGame');

    gameUpdatesSubscription = query.snapshots().listen(
          (event) {
        updateChanges(event);
      },
      onError: (error) {
        if (kDebugMode) print("Listen failed: $error");
      },
      onDone: () {
        setState(() {
          isGameStreamActive = false;
        });
      },
    );


    teamQ = FirebaseFirestore.instance.doc(widget.team.id).snapshots().listen((event) async{
      if (event.data() == null){
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('loginSession');
        if (gameTimer != null && gameTimer!.isActive) gameTimer?.cancel();
        Navigator.of(context).popAndPushNamed('/');
      }else{
        if (mounted){
          if (kDebugMode) print('new update');
          final newTeam = teamObjectFromShot(event.data()!, event.reference.path);
          if (newTeam.loggedIn == 0){
            final prefs = await SharedPreferences.getInstance();
            prefs.remove('loginSession');
            if (gameTimer != null && gameTimer!.isActive) gameTimer?.cancel();
            Navigator.of(context).popAndPushNamed('/');
            return;
          }
          if (newTeam.bonusSeconds > theTeam.bonusSeconds) {
            showDurationNotification(newTeam.bonusSeconds - theTeam.bonusSeconds);
            if (gameStarted) confettiController.play();
          }else if (newTeam.bonusSeconds < theTeam.bonusSeconds){
            showDurationNotification(theTeam.bonusSeconds - newTeam.bonusSeconds, penalty: true);
          }

          if (newTeam.minusSeconds > theTeam.minusSeconds){
            showDurationNotification(newTeam.minusSeconds - theTeam.minusSeconds, penalty: true);
          }else if (newTeam.minusSeconds < theTeam.minusSeconds){
            showDurationNotification(theTeam.minusSeconds - newTeam.minusSeconds);
          }
          setState(() {
            theTeam = newTeam;
          });
        }
      }
    });
    setState(() {
      isGameStreamActive = true;
    });
  }

  updateChanges(DocumentSnapshot<Map<String, dynamic>> doc){
    // bool started = doc.data()!['started'];
    bool paused = doc.data()!['paused'];
    DateTime? startT = doc.data()!['startTime']?.toDate();
    DateTime endT = doc.data()!['endTime'].toDate();

    if (kDebugMode) print('accessed');


    setState(() {
      gamePaused = paused;
    });


    if (endTime == null || endTime!.difference(endT).inSeconds.abs() > 0){
      endTime = endT;
    }
    if (startT != null){
      if (startTime == null || startTime!.difference(startT).inSeconds.abs() > 0){
        startTime = startT;
      }
    }else{
      startTime = null;
    }

  }


  animateEndTimer(){

    setState(() {
      deadTime = true;
    });
    int count = 0;
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      count++;
      setState(() {
        if (count % 5 == 0){
          controller1.forward().then((value) => controller2.forward()
              .then((value) => controller1.reverse().then((value) => controller2.reverse())));
        }
      });
      switch(count % 2){

        case 0: {
          counterColor = Colors.red;
          box2Color = Colors.red;
          box3Color = Colors.red;
          box4Color = Colors.red;
        }
        break;
        case 1: {
          counterColor = Colors.black;
          box2Color = Colors.black;
          box3Color = Colors.black;
          box4Color = Colors.black;
        }
        break;
      }
      if (count > 200) {
        setState(() {
          deadTime = false;
        });
        timer.cancel();
      }
    });
  }

  String formatNumber(int x){
    if (x.toString().length == 1){
      return '0${x.toString()}';
    }
    return x.toString();
  }

  setRemText(int timeInSec){
    int tTime = timeInSec;
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
    days = formatNumber(tDays);
    hours = formatNumber(tHours);
    minutes = formatNumber(tMinutes);
    tSeconds = tSeconds < 0 ? 0 : tSeconds;
    seconds = formatNumber(tSeconds);


    return ('$tDays D : $tHours H  $tMinutes M : $tSeconds S');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (kDebugMode) print("app in resumed");
        break;
      case AppLifecycleState.inactive:
        if (kDebugMode) print("app in inactive");
        break;
      case AppLifecycleState.paused:
        if (kDebugMode) print("app in paused");
        break;
      case AppLifecycleState.detached:
        if (kDebugMode) print("app in detached");
        break;
    }
  }

  updateTeamEndTime(String? tag) async{
    if (tag == null) return;
    await Future.delayed(const Duration(seconds: 3));
    try{
      final sign = tag.substring(0, 1);
      final seconds = int.tryParse(tag.substring(1, tag.length));
      if (sign == '+'){
        await FirebaseFirestore.instance.doc(theTeam.id).update({
          'bonusSeconds': theTeam.bonusSeconds + seconds!
        });
        setState(() {
          theTeam.bonusSeconds+= seconds;
        });
        confettiController.play();
      }else{
        await FirebaseFirestore.instance.doc(theTeam.id).update({
          'minusSeconds': theTeam.minusSeconds + seconds!
        });
      }
    }catch (e){
      showNotification(context, 'Failed: $e', error: true);
    }
  }

  @override
  void dispose(){
    gameTimer?.cancel();
    gameUpdatesSubscription.cancel();
    connectivitySubscription.cancel();
    teamQ.cancel();
    controller1.dispose();
    controller2.dispose();
    confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.98),
      appBar: AppBar(

        backgroundColor: Colors.black,

        title: Text('SKETCH GAMES', style: TextStyle(color: Colors.white, fontFamily: 'digital', fontSize: 25.sp),),
      ),
      body: Center(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 10.h,),
                  SizedBox(
                    width: 70.w,
                    height: 15.h,
                    child: Align(
                      alignment: notifyUser ? Alignment.centerLeft : Alignment.center,
                      child: notifyUser ? DefaultTextStyle(
                        key: Key('MessengerKey'),
                        style: TextStyle(
                          fontFamily: 'digital',
                          color: notificationColor,
                          fontSize: 17.sp,),

                        child: AnimatedTextKit(
                          pause: const Duration(seconds: 0),
                          isRepeatingAnimation: false,
                          animatedTexts: [
                            TypewriterAnimatedText(
                                notificationMessage,
                                cursor: "\$",
                                speed: const Duration(milliseconds: 50)),
                          ],
                          onFinished: () async{
                            await player.pause();
                            Future.delayed(const Duration(seconds: 5)).then((value) async{
                              await player.seek(const Duration(seconds: 0));
                              player.play();
                              setState(() {
                                notifyUser = false;
                              });
                            });
                          },
                        ),
                      ) :
                      DefaultTextStyle(
                        key: Key('TITLEKEY'),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 35.sp,
                            fontFamily: 'digital',
                            color: Colors.white
                        ),

                        child: AnimatedTextKit(
                          pause: const Duration(seconds: 0),
                          isRepeatingAnimation: false,
                          animatedTexts: [
                            TyperAnimatedText(theTeam.teamName, speed: const Duration(milliseconds: 50)),
                          ],
                          onFinished: (){
                            player.pause();
                          },
                        ),
                      ),
                    )
                  ).animate().slideY(),
                  Spacer(),
                  Center(
                    child: AnimatedSwitcher(duration: const Duration(milliseconds: 1000),
                      transitionBuilder: (child, animation){
                        return SlideTransition(
                          position: Tween<Offset>(begin: Offset(0, -10), end: Offset(0, 0)).animate(animation),
                          child: ScaleTransition(scale: animation, child: child),);
                      },
                      child: gameOff ?
                      Text(key: Key('7821h3'),'GAME IS SHUT DOWN',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 20.sp, fontFamily: 'digital', color: Colors.red),
                        textAlign: TextAlign.center,)
                          : deadTime ? Text(key: Key('t13142'),'YOU RAN OUT OF TIME!',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 20.sp, fontFamily: 'digital', color: Colors.red),
                        textAlign: TextAlign.center,) : gameStarted ? gamePaused ?
                      Text(key: Key('jsd3303*'),'GAME PAUSED',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 20.sp, fontFamily: 'digital', color: Colors.orangeAccent),
                        textAlign: TextAlign.center,) :
                      Text(key: Key('t23322'),'GAME STARTED',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 20.sp, fontFamily: 'digital', color: Colors.green),
                        textAlign: TextAlign.center,) :
                      Text(key: Key('t399087'),'GAME STARTS IN',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 20.sp, fontFamily: 'digital', color: Colors.red),
                        textAlign: TextAlign.center,)
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: CircleAvatar(
                        backgroundColor: gameStarted ? gamePaused ? Colors.black.withOpacity(0.98) : Colors.black.withOpacity(0.98) : Colors.red.withOpacity(0.2),
                        radius: 30.w,
                        child: CircularPercentIndicator(
                          // linearGradient: circleGradient,
                            progressColor: progressColor,
                            radius: 30.w,
                            circularStrokeCap: CircularStrokeCap.square,
                            animation: true,
                            animateFromLastPercent: true,
                            animationDuration: 1000,
                            lineWidth: 3.sp,
                            percent: remainingPercent,
                            backgroundColor: Colors.green.withOpacity(0.1),
                            center: SizedBox(
                              width: 45.w,
                              child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FittedBox(
                                        child: Text(days,
                                          style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                                              fontSize: 25.sp),
                                          textAlign: TextAlign.center,),
                                      ).animate().slideX().fade(),
                                      Text(':', style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                                          fontSize: 25.sp),).animate().slideX(delay: const Duration(milliseconds: 100)).fade(),
                                      FittedBox(
                                        child: Text(hours,
                                          style: TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                                          fontSize: 25.sp),
                                          textAlign: TextAlign.center,),
                                      ).animate().slideX(delay: const Duration(milliseconds: 200)).fade(),
                                      Text(':', style: TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                                          fontSize: 25.sp),).animate().slideX(delay: const Duration(milliseconds: 300)).fade(),
                                      FittedBox(
                                        child: Text(minutes,
                                          style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                                              fontSize: 25.sp),
                                          textAlign: TextAlign.center,),
                                      ).animate().slideX(delay: const Duration(milliseconds: 400)).fade(),
                                      Text(':', style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                                          fontSize: 25.sp),).animate().slideX(delay: const Duration(milliseconds: 500)).fade(),
                                      FittedBox(
                                        child: Text(seconds,
                                          style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                                              fontSize: 25.sp),
                                          textAlign: TextAlign.center,),
                                      ).animate().slideX(delay: const Duration(milliseconds: 600)).fade()

                                    ],
                                  )
                              ),
                            ),

                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 13.h),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(10.sp),
                child: Row(
                  children: [
                    SizedBox(width: 3.w),
                    InkWell(
                      onTap: isGameStreamActive ? null : (){
                        initListener();
                      },
                      child: Icon(Icons.stream, size: 17.sp, color: isGameStreamActive ? Colors.green : Colors.red,),
                    ),
                    SizedBox(width: 5.w),
                    Icon(connection == ConnectivityResult.wifi ? Icons.wifi :
                    connection == ConnectivityResult.mobile ? Icons.cell_tower: Icons.airplanemode_active_rounded, size: 17.sp,
                    color: mobileConnectivity ? Colors.green : Colors.red,),
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: 3.w),
                      child: InkWell(onTap: () async{
                        try{
                          await FirebaseFirestore.instance.doc(theTeam.id).update({'loggedIn': FieldValue.increment(-1)});
                          final prefs = await SharedPreferences.getInstance();
                          prefs.remove('loginSession');
                          gameTimer?.cancel();
                          Navigator.of(context).popAndPushNamed('/');
                        }catch (e){
                          if (kDebugMode) print(e);
                        }


                      }, child: Icon(Icons.logout, color: Colors.green,)),
                    )
                  ],
                ),
              ),
            ),
            gameStarted && !gamePaused ? SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(1.sp), bottomRight: Radius.circular(1.sp))
                    )
                  ),
                    onPressed: (){

                      // showDurationNotification(306540, penalty: false);

                      if (gameStarted && !gamePaused) _listenForNFCEvents();
                    },
                    icon: Icon(Icons.nfc_sharp), label: Text('SCAN',
                style:  TextStyle(
                    fontSize: 20.sp,
                    fontFamily: 'digital'),),
                ),
              ),
            ) : Container(),
              Align(
              child:
              ConfettiWidget(
                  confettiController: confettiController,
                  blastDirection: -pi / 2,
                  emissionFrequency: 0.5,
                  numberOfParticles: 20,
                  maxBlastForce: 20,
                  minBlastForce: 10,
                  gravity: 0.1,
                  ),
              )
          ],
        ),
      ),
    );
  }
  Future<String?> _listenForNFCEvents({bool? write, String? content}) async {
    //Always run this for ios but only once for android
    bool listenerRunning = false;
    if (Platform.isAndroid && listenerRunning == false || Platform.isIOS) {
      //Android supports reading nfc in the background, starting it one time is all we need
      if (Platform.isAndroid) {
        if (kDebugMode) print('NFC listener running in background now, approach tag(s)',);
        setState(() {
          listenerRunning = true;
        });
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          //Try to convert the raw tag data to NDEF
          final ndefTag = Ndef.from(tag);
          //If the data could be converted we will get an object
          if (ndefTag != null) {
            // If we want to write the current counter vlaue we will replace the current content on the tag
            if (write?? false) {

              //Create a 1Well known tag with en as language code and 0x02 encoding for UTF8
              final ndefRecord = NdefRecord.createText(content?? 'null');
              //Create a new ndef message with a single record
              final ndefMessage = NdefMessage([ndefRecord]);
              //Write it to the tag, tag must still be "connected" to the device
              try {
                //Any existing content will be overrwirten
                await ndefTag.write(ndefMessage);
                showNotification(context, 'Content written on tag successfully.');
              } catch (e) {
                if (kDebugMode) print("Writting failed: $e");
              }
            }
            else {

              var ndefMessage = ndefTag.cachedMessage!;
              //Each NDEF message can have multiple records, we will use the first one in our example
              if (ndefMessage.records.isNotEmpty &&
                  ndefMessage.records.first.typeNameFormat ==
                      NdefTypeNameFormat.nfcWellknown) {
                //If the first record exists as 1:Well-Known we consider this tag as having a value for us
                final wellKnownRecord = ndefMessage.records.first;

                ///Payload for a 1:Well Known text has the following format:
                ///[Encoding flag 0x02 is UTF8][ISO language code like en][content]
                if (wellKnownRecord.payload.first == 0x02) {
                  //Now we know the encoding is UTF8 and we can skip the first byte
                  final languageCodeAndContentBytes =
                  wellKnownRecord.payload.skip(1).toList();
                  //Note that the language code can be encoded in ASCI, if you need it be carfully with the endoding
                  final languageCodeAndContentText =
                  utf8.decode(languageCodeAndContentBytes);
                  //Cutting of the language code
                  final payload = languageCodeAndContentText.substring(2);
                  //Parsing the content to int
                  updateTeamEndTime(payload);
                }
              }
            }
          }
          //Due to the way ios handles nfc we need to stop after each tag
          if (Platform.isIOS) {
            NfcManager.instance.stopSession();
          }
        },
        // Required for iOS to define what type of tags should be noticed
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
      ).then((value) {
        if (kDebugMode) print('finished');
      });
    }
    return null;
  }

  showDurationNotification(int seconds, {bool? penalty}) async{
    final parts = extractListOfDuration(seconds);
    notificationColor = penalty?? false ? Colors.red.shade300 : Colors.green.shade300;
    notificationMessage =
        'You ${(penalty?? false) ? 'Lost' : 'Gained'} Time\n\n'
        "${parts[0] != 0 ? '${parts[0]} Days${parts[1] == 0 ? '' : ', '}' : ''}"
        "${parts[1] != 0 ? '${parts[1]} Hours${parts[2] == 0 ? '' : ', '}' : ''}"
        "${parts[2] != 0 ? '${parts[2]} Minutes${parts[3] == 0 ? '' : ', '}' : ''}${parts[3] != 0 ? '${parts[3]} Seconds ' : ''}";

    await player.seek(const Duration(seconds: 0));
    player.play();
    setState(() {
      notifyUser = true;
    });

    // showOverlayNotification(
    //     duration: const Duration(seconds: 10),
    //         (context) {
    //           return SafeArea(
    //             child: SizedBox(
    //               width: 90.w,
    //               child: Column(
    //                 children: [
    //                   SizedBox(height: 15.h),
    //                   Container(
    //                     padding: EdgeInsets.all(5.w),
    //                     decoration: BoxDecoration(
    //                         color: (penalty?? false) ? Colors.red : Colors.green,
    //                         borderRadius: BorderRadius.circular(1.sp)
    //                     ),
    //                     child: Center(
    //                         child: Column(
    //                           children: [
    //                             Row(
    //                               mainAxisAlignment: MainAxisAlignment.start,
    //                               children: [
    //                                 const Icon(CupertinoIcons.timer, color: Colors.white),
    //                                 SizedBox(width: 3.w),
    //                                 Flexible(
    //                                   child: RichText(
    //                                       textAlign: TextAlign.left,
    //                                       maxLines: 6,
    //                                       overflow: TextOverflow.ellipsis,
    //                                       text: TextSpan(
    //                                           style: TextStyle(
    //                                             fontFamily: 'digital',
    //                                             color: Colors.white,
    //                                             fontSize: 15.sp,),
    //                                           children: [
    //                                             TextSpan(text: 'You ${(penalty?? false) ? 'Lost' : 'Gained'} Time\n\n',
    //                                                 style: TextStyle(fontWeight: FontWeight.w600)),
    //                                             TextSpan(text: "${parts[0] != 0 ? 'DAYS:    ${parts[0]}' : ''}"),
    //                                             TextSpan(text: "${parts[1] != 0 ? '\nHOURS:   ${parts[1]}' : ''}"),
    //                                             TextSpan(text: "${parts[2] != 0 ? '\nMINUTES: ${parts[2]}' : ''}"),
    //                                             TextSpan(text: "${parts[3] != 0 ? '\nSECONDS: ${parts[3]} ' : ''}"),
    //                                             // TextSpan(text: sentence,style: TextStyle(fontSize: 17.sp))
    //                                           ]
    //                                       )),
    //                                 )
    //                               ],
    //                             ),
    //                           ],
    //                         )
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           );
    //         }
    // );
  }
}
