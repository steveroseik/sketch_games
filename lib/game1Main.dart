
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:sketch_games/notifiers.dart';
import 'package:sketch_games/pinput_theme.dart';
import 'package:vibration/vibration.dart';
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
  late BlackBox box;


  bool deadTime = false;
  bool isGameStreamActive = false;
  bool mobileConnectivity = false;
  bool gameOff = false;
  bool gameStarted = false;
  bool gamePaused = true;
  bool notifyUser = false;
  bool confettiEnabled = false;
  bool isFirstAttempt = true;
  bool jackpot = false;
  bool sequenceMission = false;
  bool teamCached = true;
  bool isQueueing = false;
  bool typingFinished = true;

  String notificationMessage = '';
  String prevNotification = '';
  String restOfMessage = '';
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

  TextEditingController pinCodeField = TextEditingController();
  FocusNode firstPin = FocusNode();
  List<int> sequenceCodes = [];
  int atSequence = 0;

  String days = '00';
  String hours = '00';
  String seconds = '00';
  String minutes = '00';
  String initialText = '';
  String? deviceId;
  String playerName = '';

  late TeamObject theTeam;

  final confettiController = ConfettiController(duration: const Duration(seconds: 1 ));


  final player = AudioPlayer();
  final player2 = AudioPlayer();// Create a player

  @override
  void initState() {
    theTeam = widget.team;
    initialize();
    initConnectivityListener();
    player.setAsset('assets/typing.mp3');
    player.setLoopMode(LoopMode.one);
    player2.setAsset('assets/notification.mp3');
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

  initialize() async{
    await initListener();
    initGameTimer();
    final newToken = await FirebaseMessaging.instance.getToken();
    final deviceId = await getDeviceId();
    try{
      final data = await FirebaseFirestore.instance.doc(theTeam.id).get();
      final team = teamObjectFromShot(data.data()!,data.reference.path);
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
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('loginSession', jsonEncode(team.toJson()));
      if(kDebugMode) print('here is ...');
    }catch (e){
      if (kDebugMode) print(e);
    }

  }
  initGameTimer(){
    FirebaseMessaging.instance.subscribeToTopic('general');
    FirebaseMessaging.instance.subscribeToTopic(theTeam.username);
    final appStartTime = DateTime.now();
    currentTime = DateTime.now();
    gameTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      currentTime = currentTime.add(const Duration(milliseconds: 1000));
      // kill bill
      if (teamEndTime.isBefore(currentTime)){
        if (!deadTime) {
          setState(() {
            setRemText(0);
            remainingPercent = 0;
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
              setRemText(0);
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
      deviceId ??= await getDeviceId();

      if (event.data() == null){
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('loginSession');
        if (gameTimer != null && gameTimer!.isActive) gameTimer?.cancel();
        FirebaseMessaging.instance.unsubscribeFromTopic('general');
        FirebaseMessaging.instance.unsubscribeFromTopic(theTeam.username);
        Navigator.of(context).popAndPushNamed('/');

      }else{
        if (mounted){
          final prefs = await SharedPreferences.getInstance();
          if (kDebugMode) print('new update');
          final newTeam = teamObjectFromShot(event.data()!, event.reference.path);
          final i = newTeam.devices.indexWhere((e) => e.deviceId == deviceId);
          if (newTeam.devices.isEmpty || deviceId == null || i == -1){
              prefs.remove('loginSession');
              if (gameTimer != null && gameTimer!.isActive) gameTimer?.cancel();
              FirebaseMessaging.instance.unsubscribeFromTopic('general');
              FirebaseMessaging.instance.unsubscribeFromTopic(theTeam.username);
              Navigator.of(context).popAndPushNamed('/');
              return;
          }else{
            playerName = newTeam.devices[i].name;
          }

          if (!isFirstAttempt && !jackpot){
            if (newTeam.bonusSeconds > theTeam.bonusSeconds) {
              showDurationNotification(newTeam.bonusSeconds - theTeam.bonusSeconds);
              if (confettiEnabled) confettiController.play();
            }else if (newTeam.bonusSeconds < theTeam.bonusSeconds){
              showDurationNotification(theTeam.bonusSeconds - newTeam.bonusSeconds, penalty: true);
            }

            if (newTeam.minusSeconds > theTeam.minusSeconds){
              showDurationNotification(newTeam.minusSeconds - theTeam.minusSeconds, penalty: true);
            }else if (newTeam.minusSeconds < theTeam.minusSeconds){
              showDurationNotification(theTeam.minusSeconds - newTeam.minusSeconds);
              if (confettiEnabled) confettiController.play();
            }
          }else{
            isFirstAttempt = false;
            jackpot = false;
          }
          setState(() {
            teamCached = false;
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
    bool confetti = doc.data()!['confetti'];
    DateTime? startT = doc.data()!['startTime']?.toDate();
    DateTime endT = doc.data()!['endTime'].toDate();

    if (kDebugMode) print('accessed');


    setState(() {
      gamePaused = paused;
      confettiEnabled = confetti;
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
    days = tDays > 99 ? '99+' : formatNumber(tDays);
    hours = formatNumber(tHours);
    minutes = formatNumber(tMinutes);
    tSeconds = tSeconds < 0 ? 0 : tSeconds;
    seconds = formatNumber(tSeconds);


    return ('$tDays D : $tHours H  $tMinutes M : $tSeconds S');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async{
    switch (state) {
      case AppLifecycleState.resumed:
        if (kDebugMode) print("app in resumed");
        break;
      case AppLifecycleState.inactive:
        if (kDebugMode) print("app in inactive");
        break;
      case AppLifecycleState.paused:
        if(!teamCached) {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('loginSession', jsonEncode(theTeam.toJson()));
          teamCached = true;
        }
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
        if (seconds == 77009900880011){
          //jackpot
          jackpot = true;
          await FirebaseFirestore.instance.doc(theTeam.id).update({
            'bonusSeconds': theTeam.bonusSeconds + 21600
          });
          box.addMessage(NotifObject(message: "Congratulations you won!!"));
          if (confettiEnabled) confettiController.play();
          await FirebaseFirestore.instance.doc('gamesListeners/firstGame')
              .update({
            'paused': true
          });
        }else{
          await FirebaseFirestore.instance.doc(theTeam.id).update({
            'bonusSeconds': theTeam.bonusSeconds + seconds!
          });
        }


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
    player.dispose();
    player2.dispose();
    firstPin.dispose();
    pinCodeField.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  sendQueueNotifications() async{
    if (isQueueing) {
      return;
    }
    isQueueing = true;
    while(box.hasQueue){
      while(!typingFinished){
        await Future.delayed(const Duration(milliseconds: 100));
      }
      setState(() {
        typingFinished = false;
        notifyUser = false;
      });
      final message = box.removeNotification();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted){
        if(message.data != null && message.data!['sequenceCodes'] != null){
          sequenceCodes = List<int>.from(jsonDecode(message.data!['sequenceCodes']).map((x) => x));
          sequenceMission = true;
          atSequence = 0;
          sendGameNotification(message: 'Welcome campers, reaching this mission means you have survived. Great Job!!\n'
              'You are asked to solve phases 1,3 and 4 of the document you will receive from the admin.\n\n'
              'Good luck', color: Colors.orangeAccent, vibrate: true);
          firstPin.requestFocus();
        }else if (message.title != null || message.message != null){
          await sendGameNotification(message: '${message.title?? ''} '
              '${message.message?? ''}', color: message.color?? Colors.green, vibrate: message.vibrate?? false);
        }
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    setState(() {
      isQueueing = false;
    });
    box.notify();


  }

  @override
  Widget build(BuildContext context) {
    box = BlackNotifier.of(context);
    if (box.hasQueue && !isQueueing) {
      sendQueueNotifications();
    }
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                    SizedBox(height: 6.h,),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80.w,
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
                            animatedTexts: restOfMessage.isEmpty ? [
                              TypewriterAnimatedText(
                                  notificationMessage,
                                  cursor: "\$",
                                  speed: const Duration(milliseconds: 100))
                            ] : [
                              TypewriterAnimatedText(
                                  notificationMessage,
                                  cursor: "\$",
                                  speed: const Duration(milliseconds: 100)),
                              TypewriterAnimatedText(
                                  restOfMessage,
                                  cursor: "\$",
                                  speed: const Duration(milliseconds: 100)),
                            ],
                            onFinished: () async{
                              if (player.playing) await player.pause();
                              setState(() {
                                typingFinished = true;
                              });
                              Future.delayed(const Duration(seconds: 5)).then((value) async{
                                if (typingFinished){
                                  setState(() {
                                    notifyUser = false;
                                  });
                                }
                              });
                            },
                          ),
                        ) :
                        AnimatedTextKit(
                          key: const Key('TITLEKEY'),
                          pause: const Duration(seconds: 0),
                          animatedTexts: [
                            FadeAnimatedText(
                                theTeam.teamName,
                                duration: const Duration(milliseconds: 3000),
                            textStyle:
                            TextStyle(
                                fontSize: 35.sp,
                                fontFamily: 'digital',
                                color: Colors.green,
                            )
                            ),

                            FadeAnimatedText(
                                playerName,
                                duration: const Duration(milliseconds: 2000),
                                textStyle:
                                TextStyle(
                                  fontSize: 25.sp,
                                  fontFamily: 'digital',
                                  color: Colors.green.shade900,
                                )
                            ),
                          ],
                          isRepeatingAnimation: true,
                          repeatForever: true,
                        ),
                      )
                    ).animate().slideY(),
                    SizedBox(height: 2.h,),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1000),
                      transitionBuilder: (child, animation){
                        return ScaleTransition(scale: animation, child: child);
                      },
                    child: sequenceMission ? AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80.w,
                      height: 15.h,
                      child: Center(
                        child: Column(
                          children: [
                            Text(key: const Key('codePinReq1212321'),
                                'Enter ${atSequence == 0 ? 'first' : atSequence == 1 ? 'second' : 'third'} code sequence',
                                style: TextStyle(
                                    fontSize: 15.sp, fontFamily: 'digital', color: Colors.red)),
                            OnlyBottomCursor(controller: pinCodeField, node: firstPin,
                            onCompleted: (value) async{
                              pinCodeField.clear();
                              final code = int.tryParse(value);
                              if (code != null && code == sequenceCodes[atSequence]){
                                if (atSequence == 2){
                                  try{
                                    sequenceMission = false;
                                    jackpot = true;
                                    await FirebaseFirestore.instance.doc(theTeam.id).update({
                                      'bonusSeconds': theTeam.bonusSeconds + 420
                                    });
                                    if(confettiEnabled) confettiController.play();
                                    box.addMessage(NotifObject(message: 'Great job campers. You will now receive a reward of 7 minutes.\n\n'
                                        'Take the document and leave.\n\n'
                                        'Good luck with your next mission.'));
                                  }catch (e){
                                    if (kDebugMode) print(e);
                                  }

                                }else{
                                  atSequence++;
                                   box.addMessage(
                                       NotifObject(message: 'SEQUENCE APPROVED! \n\n${3-atSequence} SEQUENCE${3-atSequence == 1 ? '' : 'S'} LEFT...'));
                                  firstPin.requestFocus();
                                }
                              }else{
                                try{
                                  jackpot = true;
                                  await FirebaseFirestore.instance.doc(theTeam.id).update({
                                    'minusSeconds': theTeam.minusSeconds + 120
                                  });
                                  box.addMessage(NotifObject(message: 'Oops!! \n \n'
                                      'YOU LOST TWO MINUTES..', color: Colors.red));
                                  firstPin.requestFocus();
                                }catch (e){
                                  if (kDebugMode) print(e);
                                }
                              }
                            },
                            ),
                          ],
                        ),
                      ),
                    ) :  Container()),
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
                                width: 50.w,
                                child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        FittedBox(
                                          child: Text(days,
                                            style:  TextStyle(fontFamily: 'digital', color: counterColor, fontWeight: FontWeight.w700,
                                                fontSize: 25.sp),
                                            textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,),
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
                          final prefs = await SharedPreferences.getInstance();
                          prefs.remove('loginSession');
                          if (gameTimer != null && gameTimer!.isActive) gameTimer?.cancel();
                          FirebaseMessaging.instance.unsubscribeFromTopic('general');
                          FirebaseMessaging.instance.unsubscribeFromTopic(theTeam.username);
                          Navigator.of(context).popAndPushNamed('/');
                        }, child: Icon(Icons.power_settings_new_rounded, color: Colors.green,)),
                      )
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child,),
                  child: gameStarted && !gamePaused && !gameOff ? Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(1.sp), bottomRight: Radius.circular(1.sp)),
                          ),
                          side: BorderSide(width: 1, color: Colors.green)
                      ),
                      onPressed: (){

                        if (gameStarted && !gamePaused) _listenForNFCEvents();
                      },
                      icon: Icon(Icons.nfc_sharp), label: Text('SCAN',
                      style:  TextStyle(
                          fontSize: 20.sp,
                          fontFamily: 'digital'),),
                    ),
                  ) : Container(),
                ),
              ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                  child: ConfettiWidget(
                      confettiController: confettiController,
                      blastDirection: -pi / 2,
                      emissionFrequency: 0.5,
                      numberOfParticles: 20,
                      maxBlastForce: 20,
                      minBlastForce: 10,
                      gravity: 0.1,
                      ),
                  ),
                )
            ],
          ),
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


  sendGameNotification({String? message, Color? color, bool vibrate=true}) async{
    notificationMessage = message?? notificationMessage;
    if (notificationMessage.length > 120){
      final splitter = splitStringIntoParts(notificationMessage, 0.6);
      notificationMessage = splitter[0];
      restOfMessage = splitter[1];
    }else{
      restOfMessage = '';
    }
    notificationColor = color?? Colors.green;
    if (vibrate) Vibration.vibrate(duration: 1000);
    await player.seek(const Duration(seconds: 0));
    player.play();
    setState(() {
      notifyUser = true;
    });
  }

  showDurationNotification(int seconds, {bool? penalty}) async{

    final parts = extractListOfDuration(seconds);
    notificationMessage =
        'You ${(penalty?? false) ? 'Lost' : 'Gained'} Time\n\n'
        "${parts[0] != 0 ? '${parts[0]} Days${parts[1] == 0 ? '' : ', '}' : ''}"
        "${parts[1] != 0 ? '${parts[1]} Hours${parts[2] == 0 ? '' : ', '}' : ''}"
        "${parts[2] != 0 ? '${parts[2]} Minutes${parts[3] == 0 ? '' : ', '}' : ''}${parts[3] != 0 ? '${parts[3]} Seconds ' : ''}";
    box.addMessage(NotifObject(
        message: 'You ${(penalty?? false) ? 'Lost' : 'Gained'} Time\n\n'
            "${parts[0] != 0 ? '${parts[0]} Days${parts[1] == 0 ? '' : ', '}' : ''}"
            "${parts[1] != 0 ? '${parts[1]} Hours${parts[2] == 0 ? '' : ', '}' : ''}"
            "${parts[2] != 0 ? '${parts[2]} Minutes${parts[3] == 0 ? '' : ', '}' : ''}${parts[3] != 0 ? '${parts[3]} Seconds ' : ''}",
        color: penalty?? false ? Colors.red : Colors.green));
  }
}
