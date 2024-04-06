import 'dart:async';
import 'dart:convert';
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
import 'notifiers.dart';


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
  late StreamSubscription gameSub;
  bool loading = false;
  late DateTime pauseTime;
  late Timer gameTimer;
  late Timer clock;
  late DateTime currentTime;
  bool gameStarted = false;

  late BlackBox box;

  List<bool> timeSelected = [false, false, true];
  bool sortAsc = true;


  @override
  void initState() {
    currentTime = DateTime.now();
    initClock();
    generateGame();
    super.initState();
  }

  initClock(){
    clock = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentTime = DateTime.now();
      refreshTeam.value = !refreshTeam.value;
    });
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
        gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) async{
          if (game.startTime != null && !game.startTime!.isAfter(DateTime.now())){
            if (!gameStarted){
              setState(() {
                gameStarted = true;
              });
            }
          }else{
            if (gameStarted){
              setState(() {
                gameStarted = false;
              });
            }
          }
        });
      }else{
        gameTimer.cancel();
        print('no game');
      }
    }catch (e){
      print('game initialization error: $e');
    }
  }

  initListeners(){

    gameSub = FirebaseFirestore.instance.doc('gamesListeners/firstGame').snapshots().listen((event){


      if (event.data() != null){
        game = firstGameFromShot(event.data()!);
        if (event.data()!['paused'] != game.paused){
          setState(() => game.paused = !game.paused);
        }
      }
    });

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
      updateTeamsInfo();

      // refreshTeam.value = !refreshTeam.value;
    });

  }

  updateTeamsInfo(){
    for (var team in teams){
      team.relativeEndTime = game.endTime.add(Duration(seconds: team.bonusSeconds))
          .subtract(Duration(seconds: team.minusSeconds));
    }
    sortAsc ? teams.sort((a, b) => a.compareTo(b)) : teams.sort((a, b) => b.compareTo(a));

    // refreshTeam.value = !refreshTeam.value;
  }

  @override
  void dispose() {
    teamSub.cancel();
    gameSub.cancel();
    clock.cancel();
    gameTimer.cancel();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    box = BlackNotifier.of(context);
    box.teams = teams;
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                      onTap: () async{
                        Navigator.of(context).pushNamed('/settings', arguments: game);
                      },
                      child: const Icon(CupertinoIcons.gear_solid))),
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
                        width: 80.w,
                        child: ElevatedButton.icon(
                          onPressed: () async{
                            Navigator.of(context).pushNamed('/notif', arguments: teams);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.sp))
                          ),
                          icon: Icon(Icons.notifications_active, color: Colors.white),
                          label: Text('Notifications Center',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                            ),),
                        ),
                      ),
                      SizedBox(height: 3.h,),
                      Text('Start Time', style: TextStyle(fontWeight: FontWeight.w800))
                      .animate().slideY(delay: const Duration(milliseconds: 100),).fadeIn(),
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            color: CupertinoColors.extraLightBackgroundGray,
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
                                    color: Colors.blueGrey.shade600,
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
                              height: 5.h,
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: ()async{
                                            if (game.startTime == null){
                                              showNotification(context, 'Start Time already removed!', error: true);
                                              return;
                                            }
                                            try{
                                              await FirebaseFirestore.instance.doc('gamesListeners/firstGame')
                                                  .update({
                                                'startTime': null
                                              });
                                              showNotification(context, 'Start Time Removed!');
                                              game.startTime = null;
                                              setState(() {});
                                            }catch (e){
                                              showNotification(context, 'Failed: $e', error: true);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10.sp),
                                              ),
                                              backgroundColor: Colors.red.shade100,
                                              foregroundColor: Colors.black
                                          ),
                                          child: Text('Remove'))
                                  ),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: ()async{
                                            updateStartTime();
                                          },
                                          style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10.sp),
                                              ),
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black
                                          ),
                                          child: Text('Set Date'))),
                                ],
                              ),
                            )
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
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            color: CupertinoColors.extraLightBackgroundGray,
                            borderRadius: BorderRadius.circular(10.sp)
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            timeWidget(game.endTime),
                            SizedBox(height: 1.h),
                            SizedBox(
                                height: 5.h,
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: ElevatedButton(
                                            onPressed: ()async{
                                              if (game.startTime == null){
                                                showNotification(context, 'You have to set start time first!', error: true);
                                                return;
                                              }
                                              final duration = await myDurationPicker(context);
                                              if (duration == null) return;
                                              try{
                                                await FirebaseFirestore.instance.doc('gamesListeners/firstGame')
                                                    .update({
                                                  'endTime': Timestamp.fromDate(game.startTime!.add(duration))
                                                });
                                                showNotification(context, 'End Time Updated!');
                                                game.endTime = game.startTime!.add(duration);
                                                setState(() {});
                                              }catch (e){
                                                showNotification(context, 'Failed: $e', error: true);
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10.sp),
                                                ),
                                                backgroundColor: Colors.blue.shade100,
                                                foregroundColor: Colors.black
                                            ),
                                            child: Text('Set Duration'))
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: ElevatedButton(
                                          onPressed: () async{
                                            await updateEndTime();
                                          },
                                          style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10.sp),
                                              ),
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black
                                          ),
                                          child: Text('Set Date')),
                                    )
                                  ],
                                )),
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
                                          'paused': false,
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
                                          'paused': true,
                                        });
                                  }
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
                                Navigator.of(context).pushNamed('/manageTeams', arguments: [teams, game]);
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
                              teams[index].relativeEndTime = game.endTime
                                  .add(Duration(seconds: teams[index].bonusSeconds))
                                  .subtract(Duration(seconds: teams[index].minusSeconds));
                              teams[index].remTimes = game.paused ? teams[index].remTimes :
                                                      setRemText(teams[index].getRemTime(currentTime, game));
                              return Container(
                                padding: EdgeInsets.all(2.w),
                                margin: EdgeInsets.all(1.w),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.sp),
                                    border: Border.all(width: 2, color: teams[index].devices.isNotEmpty ?
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
                                              onTap: teams[index].devices.isNotEmpty ? () async{
                                                Navigator.of(context).pushNamed('/teamMembers', arguments: teams[index]);
                                              }: null,
                                              child: Icon(teams[index].devices.isNotEmpty ? CupertinoIcons.person_crop_circle_badge_checkmark :
                                              CupertinoIcons.person_crop_circle_badge_xmark,
                                                  color: teams[index].devices.isNotEmpty ? Colors.green : Colors.red),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 2.h,),
                                    timeWidget(teams[index].relativeEndTime!),
                                    SizedBox(height: 1.h,),
                                    teams[index].remTimes != null ?  Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(width: 1, color: Colors.grey.shade300),
                                          color: CupertinoColors.extraLightBackgroundGray,
                                          borderRadius: BorderRadius.circular(5.sp)
                                        ),
                                        child: timeCounter(teams[index].remTimes!, counterColor: gameStarted ? Colors.black : Colors.grey)) : Container(),
                                    SizedBox(height: 1.h,),
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
                                                    Expanded(child: Text(bTime, overflow: TextOverflow.ellipsis, maxLines: 1,
                                                    textAlign: TextAlign.right,)),
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
                                                    Expanded(child: Text(mTime, overflow: TextOverflow.ellipsis, maxLines: 1,
                                                      textAlign: TextAlign.right,)),
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
                                          onPressed: (){
                                            confirmDestruction(index);
                                          },
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


  updateStartTime() async{
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
  }
  updateEndTime() async{
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
  }

  // Future<Duration?> pickDuration() async{
  //   final duration = await showDurationPicker(
  //     context: context,
  //     initialTime: Duration(minutes: 1),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(25.sp),
  //       color: Colors.white
  //     )
  //   );
  //   return duration;
  // }

  Future<DateTime?> pickDate(DateTime? initialDate) async{
    DateTime? pickedDate = DateTime.now();
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
                    FilledButton(
                      onPressed: (){
                        Navigator.of(context).pop(false);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.sp))
                      ),
                      child: const Text('Cancel',
                        style: TextStyle(
                          color: Colors.red,
                        ),),
                    ),
                    FilledButton(
                      onPressed: (){
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.sp))
                      ),
                      child: const Text('Confirm',
                        style: TextStyle(
                          color: Colors.white,
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
          if (value != null && value == true){
            //good
          }else{
            pickedDate = null;
          }
    });

    return pickedDate;
  }

  confirmDestruction(int i){
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("End ${teams[i].teamName}'s Gameplay?"),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: const Text('Confirm'),
            onPressed: () async{
              Navigator.of(context).pop();
              await FirebaseFirestore.instance
                  .doc(teams[i].id).update(
                  {'minusSeconds': 604800});
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Cancel', style: TextStyle(color: Colors.red),),
            onPressed: () async{
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
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
              final duration = await myDurationPicker(context);
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
              final duration = await myDurationPicker(context);
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

List<String> setRemText(int timeInSec){
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
  tSeconds = tTime < 0 ? 0 : tTime;


  return [formatNumber(tDays),formatNumber(tHours), formatNumber(tMinutes), formatNumber(tSeconds)];
}
