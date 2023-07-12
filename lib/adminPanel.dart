import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';
import 'package:sketch_games/appObjects.dart';
import 'package:sketch_games/configuration.dart';

import 'customWidgets.dart';


class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {

  late FirstGame game;
  ValueNotifier<bool> gameLoaded = ValueNotifier(false);
  ValueNotifier<bool> refreshTeam = ValueNotifier<bool>(false);
  List<TeamObject> teams = <TeamObject>[];

  late StreamSubscription teamSub;
  bool loading = false;
  late DateTime pauseTime;
  late Timer timer;
  bool gameStarted = false;

  List<bool> timeSelected = [false, false, true];
  bool sortAsc = true;


  @override
  void initState() {
    generateGame();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async{
      if (game.startTime != null && !game.startTime!.isAfter(DateTime.now())){
        if (!gameStarted){
          setState(() {
            gameStarted = true;
          });
        }

      }
    });
    super.initState();
  }

  generateGame() async{
    try{
      final data = await FirebaseFirestore.instance.collection('gamesListeners').where(FieldPath.documentId, isEqualTo: 'firstGame').get();
      if (data.docs.isNotEmpty) {
        game = FirstGame.fromShot(data.docs.first.data());
        initListeners();
        if (!gameLoaded.value) gameLoaded.value = true;
        // update some info:
        if (game.startTime != null && !game.startTime!.isAfter(DateTime.now())){
          gameStarted = true;
        }else{
          gameStarted = false;
        }
        setState(() {});
      }else{
        print('no game');
      }
    }catch (e){
      print('game initialization error: $e');
    }
  }

  initListeners(){

    teamSub = FirebaseFirestore.instance.collection('gamesListeners/firstGame/teams').snapshots().listen((event) {

      for (var e in event.docChanges){
        if (e.type == DocumentChangeType.removed){
          teams.removeWhere((team) => team.id == e.doc.reference.path);
        }else if (e.type == DocumentChangeType.added){
          teams.add(teamObjectFromShot(e.doc.data()!, e.doc.reference.path));
        }else{

          int i = teams.indexWhere((element) => element.id == e.doc.reference.path);
          if (i != -1){
            teams[i] = teamObjectFromShot(e.doc.data()!, e.doc.reference.path);
          }else{
            teams.add(teamObjectFromShot(e.doc.data()!, e.doc.reference.path));
          }
        }
      }
      print('updated teams');
      updateTeamsInfo();

      refreshTeam.value = !refreshTeam.value;
    });

  }

  updateTeamsInfo(){
    for (var team in teams){
      team.relativeEndTime = game.endTime.add(Duration(seconds: team.bonusSeconds))
          .subtract(Duration(seconds: team.minusSeconds));
    }
    sortAsc ? teams.sort((a, b) => a.compareTo(b)) : teams.sort((a, b) => b.compareTo(a));

    refreshTeam.value = !refreshTeam.value;
  }

  @override
  void dispose() {
    teamSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed('/nfc');
                      },
                      child: const Icon(Icons.nfc))),
              const Center(child: Text("ADMIN PANEL")),
              Align(
                alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      FirebaseAuth.instance.signOut();
                    },
                      child: const Icon(Icons.logout_rounded)))
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: SizedBox(
          width: double.infinity,
          child: ValueListenableBuilder(valueListenable: gameLoaded,
            builder: (context, value, widget){

            return Stack(
              children: [
                value ? SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 3.h,),
                      SizedBox(
                        width: double.infinity,
                        child: Text('FIRST GAME',
                          style: TextStyle(
                              fontFamily: 'Quartzo',
                              fontSize: 30.sp
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().slideY(delay: const Duration(milliseconds: 0),).fadeIn(),
                      SizedBox(height: 3.h,),
                      Text('Start Time', style: TextStyle(fontWeight: FontWeight.w800))
                      .animate().slideY(delay: const Duration(milliseconds: 100),).fadeIn(),
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(10.sp)
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            game.startTime != null ? timeWidget(game.startTime!) :
                            Center(
                              child: AnimatedContainer(
                                height: 9.w,
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(15.sp)
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 15.sp, vertical: 7.sp),
                                child: FittedBox(
                                  child: Text(
                                    'NO TIME SET YET',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                    textAlign: TextAlign.center,),
                                ),
                              ),
                            ),
                            SizedBox(height: 1.h,),
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: ()async{
                                      final newDate = await pickDate(game.startTime);
                                      if (newDate != null){
                                        setState(() {
                                          loading = true;
                                        });
                                       try{
                                         await FirebaseFirestore.instance.doc('gamesListeners/firstGame')
                                             .update({
                                           'startTime': Timestamp.fromMillisecondsSinceEpoch(newDate.millisecondsSinceEpoch)
                                         });
                                         showNotification(context, 'Start Time Updated!');
                                         game.startTime = newDate;
                                       }catch (e){
                                         showNotification(context, 'Failed: $e', error: true);
                                       }
                                      }
                                      setState(() {
                                        loading = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.sp),
                                        ),
                                        backgroundColor: Colors.blue.shade800,
                                        foregroundColor: Colors.white
                                    ),
                                    child: Text('Update')))
                          ],
                        ),
                      )
                      .animate().slideY(delay: const Duration(milliseconds: 200),).fadeIn(),
                      SizedBox(height: 4.h),
                      Text('End Time', style: TextStyle(fontWeight: FontWeight.w800),)
                      .animate().slideY(delay: const Duration(milliseconds: 300),).fadeIn(),
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(10.sp)
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 9.w,
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(15.sp)
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 15.sp, vertical: 7.sp),
                                  child: FittedBox(
                                    child: Text(
                                      '${game.endTime.year}-${game.endTime.month}-${game.endTime.day}',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                      textAlign: TextAlign.center,),
                                  ),
                                ),
                                SizedBox(width: 1.w,),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 7.w,
                                  height: 7.w,
                                  padding: EdgeInsets.all(4),
                                  child: FittedBox(
                                    child: Text('AT',
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                                      textAlign: TextAlign.center,),
                                  ),
                                ),
                                SizedBox(width: 1.w,),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 7.w,
                                  height: 7.w,
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(4.sp)
                                  ),
                                  padding: EdgeInsets.all(4),
                                  child: FittedBox(
                                    child: Text('${(game.endTime.hour.toString().length < 2 ? '0': '')}'
                                        '${game.endTime.hour.toString()}',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                      textAlign: TextAlign.center,),
                                  ),
                                ),
                                Text(':'),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 7.w,
                                  height: 7.w,
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(4.sp)
                                  ),
                                  padding: EdgeInsets.all(4),
                                  child: FittedBox(
                                    child: Text('${(game.endTime.minute.toString().length < 2 ? '0': '')}'
                                        '${game.endTime.minute}',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                      textAlign: TextAlign.center,),
                                  ),
                                ),
                                Text(':'),
                                AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 7.w,
                                    height: 7.w,
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(4.sp)
                                    ),
                                    padding: EdgeInsets.all(4),
                                    child: FittedBox(
                                      child: Text('${(game.endTime.second.toString().length < 2 ? '0': '')}'
                                          '${game.endTime.second}',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700,),
                                        textAlign: TextAlign.center,),
                                    )
                                )
                              ],
                            ),
                            SizedBox(height: 1.h),
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: () async{
                                      final newDate = await pickDate(game.endTime);
                                      if (newDate != null){
                                        setState(() {
                                          loading = true;
                                        });
                                        try{
                                          await FirebaseFirestore.instance.doc('gamesListeners/firstGame')
                                              .update({
                                            'endTime': Timestamp.fromMillisecondsSinceEpoch(newDate.millisecondsSinceEpoch)
                                          });
                                          showNotification(context, 'End Time Updated!');
                                          game.endTime = newDate;
                                        }catch (e){
                                          showNotification(context, 'Failed: $e', error: true);
                                        }
                                      }
                                      setState(() {
                                        loading = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.sp),
                                        ),
                                        backgroundColor: Colors.blue.shade800,
                                        foregroundColor: Colors.white
                                    ),
                                    child: Text('Update'))),
                          ],
                        ),
                      )
                          .animate().slideY(delay: const Duration(milliseconds: 400),).fadeIn(),
                      SizedBox(height: 5.h,),
                      Text("GAME CONTROLS",
                        style: TextStyle(fontFamily: 'Quartzo', fontSize: 17.sp),)
                          .animate().slideY(delay: const Duration(milliseconds: 500),).fadeIn(),
                      SizedBox(height: 1.h,),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () async{
                              setState(() {
                                loading = true;
                              });
                              try{
                                final now = DateTime.now();
                                await FirebaseFirestore.instance
                                    .doc('gamesListeners/firstGame').update(
                                    (gameStarted) ? {
                                      'startTime': null,
                                      'paused': false
                                    } : {
                                      'startTime': Timestamp.fromDate(now),
                                    });
                                game.startTime = gameStarted ? null : now;
                                gameStarted = !gameStarted;

                                if (!gameStarted && game.paused) game.paused = !game.paused;
                              }catch (e){
                                print(e);
                              }
                              setState(() {
                                loading = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.sp),
                                ),
                                backgroundColor: gameStarted ? Colors.red : Colors.green,
                              foregroundColor: gameStarted ? Colors.black : Colors.white,
                            ),
                            child: Text(gameStarted ? "END GAME" : 'START GAME',
                              style: TextStyle(fontFamily: 'Quartzo', fontSize: 17.sp),))
                            .animate().slideY(delay: const Duration(milliseconds: 600),).fadeIn(),
                      ),
                      SizedBox(height: 1.h,),
                      AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation){
                            return ScaleTransition(scale: animation, child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ));
                        },
                        child: (gameStarted) ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () async{
                                setState(() {
                                  loading = true;
                                });
                                if (!game.paused){
                                  pauseTime = DateTime.now();
                                }
                                try{
                                  if (game.paused){
                                    final pauseDuration = DateTime.now().difference(pauseTime);
                                    print(pauseDuration);
                                    await FirebaseFirestore.instance
                                        .doc('gamesListeners/firstGame').update(
                                        {
                                          'paused': !game.paused,
                                          'endTime': Timestamp
                                              .fromMillisecondsSinceEpoch(game
                                              .endTime.add(pauseDuration).millisecondsSinceEpoch)
                                        });
                                    game.endTime = game.endTime.add(pauseDuration);
                                  }else{
                                    pauseTime = DateTime.now();
                                    await FirebaseFirestore.instance
                                        .doc('gamesListeners/firstGame').update(
                                        {
                                          'paused': !game.paused,
                                        });
                                  }
                                  game.paused = !game.paused;
                                }catch (e){
                                  print(e);
                                }
                                setState(() {
                                  loading = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.sp),
                                  ),
                                  backgroundColor: game.paused ? Colors.green : Colors.orange,
                                  foregroundColor: game.paused ? Colors.white : Colors.black
                              ),
                              child: Text(game.paused ? "RESUME" : 'PAUSE',
                                  style: TextStyle(fontFamily: 'Quartzo', fontSize: 17.sp))),
                        ) : Container(),
                      ).animate().slideY(delay: const Duration(milliseconds: 700),).fadeIn(),
                      SizedBox(height: 5.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('teams',
                            style: TextStyle(
                                fontFamily: 'Quartzo',
                                fontSize: 20.sp
                            ),
                            textAlign: TextAlign.center,
                          ).animate().slideY(delay: const Duration(milliseconds: 800),).fadeIn(),
                          ElevatedButton.icon(
                              onPressed: (){
                                Navigator.of(context).pushNamed('/manageTeams', arguments: teams);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.sp),
                                ),
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white
                              ),
                              icon: Icon(Icons.settings, size: 15.sp,),
                              label: Text('MANAGE TEAMS', style: TextStyle(fontSize: 9.sp),))
                              .animate().slideY(delay: const Duration(milliseconds: 800),).fadeIn(),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Text('Sort in'),
                          Spacer(),
                          IconButton(onPressed: (){
                            sortAsc = true;
                            updateTeamsInfo();
                            setState(() {});
                          },
                              style: IconButton.styleFrom(
                                backgroundColor: sortAsc ? Colors.black : Colors.grey.shade300,
                                foregroundColor: sortAsc ? Colors.white : Colors.black,
                              ),
                              icon: Icon(CupertinoIcons.up_arrow, size: 14.sp)),
                          IconButton(onPressed: (){
                            sortAsc = false;
                            updateTeamsInfo();
                            setState(() {});
                          },
                              style: IconButton.styleFrom(
                                  backgroundColor: !sortAsc ? Colors.black : Colors.grey.shade300,
                                  foregroundColor: !sortAsc ? Colors.white : Colors.black,
                              ),
                              icon: Icon(CupertinoIcons.down_arrow, size: 14.sp,))
                        ],
                      ),
                      SizedBox(height: 1.h),
                      SizedBox(
                        height: 4.h,
                        child: Row(
                          children: [
                            const Text('Time Displayed in'),
                            Spacer(),
                            ToggleButtons(
                              isSelected: timeSelected,
                              onPressed: (index) {
                                setState(() {
                                  timeSelected = [false, false, false];
                                  timeSelected[index] = true;
                                });
                              },
                              selectedColor: Colors.white,
                              fillColor: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                                  child: const Text('Hours'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                                  child: const Text('Minutes'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                                  child: const Text('Seconds'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      ValueListenableBuilder<bool>(
                          valueListenable: refreshTeam,
                          builder: (context, val, widget){
                        return teams.isEmpty ?
                        Container(
                          width: double.infinity,
                            padding: EdgeInsets.all(2.w),
                            margin: EdgeInsets.all(2.w)
                            ,
                            decoration: BoxDecoration(
                                color: CupertinoColors.extraLightBackgroundGray,
                              borderRadius: BorderRadius.circular(10.sp)
                            ),
                            child: Text('NO TEAMS',
                              style: TextStyle(color: Colors.blueGrey.shade600),
                              textAlign: TextAlign.center,))
                            : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.all(2.w),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: teams.length,
                            itemBuilder: (context, index){
                              final bTime = genTime(teams[index].bonusSeconds);
                              final mTime = genTime(teams[index].minusSeconds);
                              return Container(
                                padding: EdgeInsets.all(2.w),
                                margin: EdgeInsets.all(1.w),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.sp),
                                    border: Border.all(width: 2, color: teams[index].loggedIn > 0 ?
                                    Colors.green : CupertinoColors.systemGrey3)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      child: Stack(
                                        children: [
                                          InkWell(
                                            onTap:(){
                                              teamNameBtn(index);
                                            },
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(teams[index].teamName,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15.sp),),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: InkWell(
                                              onTap: teams[index].loggedIn > 0 ? () async{
                                                final response = await showAlertDialog(context, title: "SIGN OUT TEAM",
                                                    message: "You will Sign '${teams[index].teamName}' Out of all devices.");
                                                if (response){
                                                  try{
                                                    await FirebaseFirestore.instance.doc(teams[index].id).update({
                                                      'loggedIn': 0
                                                    });
                                                    showNotification(context, '${teams[index].teamName} was sign out successfully.');
                                                  }catch (e){
                                                    print(e);
                                                  }
                                                }
                                              }: null,
                                              child: Icon(teams[index].loggedIn > 0 ? CupertinoIcons.person_crop_circle_badge_checkmark :
                                              CupertinoIcons.person_crop_circle_badge_xmark,
                                                  color: teams[index].loggedIn > 0 ? Colors.green : Colors.red),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 2.h,),
                                    timeWidget(game.endTime
                                        .add(Duration(seconds: teams[index].bonusSeconds))
                                        .subtract(Duration(seconds: teams[index].minusSeconds))),
                                    SizedBox(height: 2.w,),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => bonusActionBtn(index),
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5.sp),
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(5.sp),
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(5.sp),
                                                    color: Colors.green
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(CupertinoIcons.plus_app),
                                                    Spacer(),
                                                    Text('$bTime'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => minusActionBtn(index),
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5.sp),
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(5.sp),
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(5.sp),
                                                    color: Colors.red
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(CupertinoIcons.minus_square),
                                                    Spacer(),
                                                    Text('$mTime'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.w,),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                          onPressed: (){},
                                          style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5.sp),
                                              ),
                                              backgroundColor: Colors.black,
                                              foregroundColor: Colors.red.shade900
                                          ),
                                          child: Text('DISQUALIFY')),
                                    ),
                                  ],
                                ),
                              )
                                  .animate().slideY(delay: Duration(milliseconds: 900+(100*index)),).fadeIn();
                            });
                      }),
                      SizedBox(height: 2.h,),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () async{
                              final c = await showAlertDialog(context, title: "RESET GAME", message: "The game will reset to ALL players!");
                              print(c);
                            },
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.sp),
                                ),
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.black
                            ),
                            child: Text('RESET GAME')),
                      ),
                      SizedBox(height: 5.h,),
                    ],
                  ),
                ) : Container(),
                (!value || loading) ?Center(child: loadingWidget(true, opacity: loading? 0.0 : null)) : Container()
              ],
            );
              }
            ),
        ),
      ),
    );
  }

  Future<Duration?> pickDuration() async{
    final duration = await showDurationPicker(
      context: context,
      initialTime: Duration(minutes: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.sp),
        color: Colors.white
      )
    );
    return duration;
  }

  Future<DateTime?> pickDate(DateTime? initialDate) async{
    DateTime? pickedDate;
    await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext builder) {
          return Container(
            margin: EdgeInsets.all(5.sp),
            padding: EdgeInsets.all(10.sp),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.sp),
                color: Colors.white
            ),
            height: MediaQuery
                .of(context)
                .copyWith()
                .size
                .height * 0.35,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: (){
                        Navigator.of(context).pop(false);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0))
                      ),
                      child: Text('Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),),
                    ),
                    ElevatedButton(
                      onPressed: (){
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0))
                      ),
                      child: Text('Done',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontSize: 10.sp,
                        ),),
                    ),
                  ],
                ),
                Flexible(
                  flex: 2,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    onDateTimeChanged: (value) {
                      setState(() {
                        if (value != pickedDate) {
                          pickedDate = value;
                        }
                      });
                    },
                    initialDateTime: initialDate?? DateTime.now(),
                    minimumYear: DateTime.now().year,
                  ),
                ),
              ],
            ),
          );
        }).then((value) {
          if (value != null && value){
            return pickedDate;
          }
          return null;
    });

    return pickedDate;
  }

  bonusActionBtn(int i){
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Choose Options'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: const Text('Add Time'),
            onPressed: () async{
              Navigator.of(context).pop();
              final duration = await pickDuration();
              if (duration != null){
                try{
                  await FirebaseFirestore.instance
                      .doc(teams[i].id).update(
                      {'bonusSeconds': teams[i].bonusSeconds + duration.inSeconds});
                }catch (e){
                  print(e);
                }
              }
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Reset', style: TextStyle(color: Colors.red),),
            onPressed: () async{
              Navigator.of(context).pop();
              try{
                await FirebaseFirestore.instance
                    .doc(teams[i].id).update(
                    {'bonusSeconds': 0});
              }catch (e){
                print(e);
              }
            },
          ),
        ],
      ),
    );
  }

  minusActionBtn(int i){
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Choose Options'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: const Text('Subtract Time'),
            onPressed: () async{
              Navigator.of(context).pop();
              final duration = await pickDuration();
                        if (duration != null){
                          try{
                            await FirebaseFirestore.instance
                                .doc(teams[i].id).update(
                                {'minusSeconds': teams[i].minusSeconds + duration.inSeconds});
                          }catch (e){
                            print(e);
                          }
                        }
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Reset', style: TextStyle(color: Colors.red),),
            onPressed: () async{
              Navigator.of(context).pop();
              try{
                await FirebaseFirestore.instance
                    .doc(teams[i].id).update(
                    {'minusSeconds': 0});
              }catch (e){
                print(e);
              }
            },
          ),
        ],
      ),
    );
  }

  teamNameBtn(int i){

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Choose Options'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: const Text('Change team name'),
            onPressed: () async{
              Navigator.of(context).pop();
              final newName = await showTextDialog(context, textLabel: 'Name', title: "Change '${teams[i].teamName}' Name");
              if (newName != null){
                try{
                  await FirebaseFirestore.instance.doc(teams[i].id).update(
                      {
                        'teamName': newName
                      });

                }catch (e){
                  print(e);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String genTime(int seconds){
    if (timeSelected[0]){
      return '${(seconds / (60*60)).toStringAsFixed(2)} hours';
    }else if (timeSelected[1]){
      return '${(seconds / 60).toStringAsFixed(2)} minutes';
    }
    return '${seconds.toString()} seconds';
  }

  }
