import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sizer/sizer.dart';
import 'package:sketch_games/appObjects.dart';

import 'configuration.dart';

class ManageTeamsPage extends StatefulWidget {
  final List<TeamObject> teams;
  const ManageTeamsPage({super.key, required this.teams});

  @override
  State<ManageTeamsPage> createState() => _ManageTeamsPageState();
}

class _ManageTeamsPageState extends State<ManageTeamsPage> {

  ValueNotifier<bool> refreshPage = ValueNotifier(false);
  bool loading = false;
  int teamsToBe = 0;
  int teamsDone = 0;
  @override
  Widget build(BuildContext context) {
    final updatedTeams = List<TeamObject>.from(widget.teams);
    updatedTeams.sort((a, b) => a.compareNumbers(b));
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async{
                        final total = await showNumberPicker(context);
                        if (total != 0) generateTeams(total);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.sp))
                      ),
                      child: Text('Set Number of Teams',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),),
                    ),
                  ),
                  SizedBox(height: 2.h,),
                  ValueListenableBuilder(
                    valueListenable: refreshPage,
                    builder: (context, value, child){
                      return updatedTeams.isEmpty ?
                      Container(
                          width: double.infinity,
                          height: 15.h,
                          padding: EdgeInsets.all(2.w),
                          margin: EdgeInsets.all(2.w)
                          ,
                          decoration: BoxDecoration(
                              color: CupertinoColors.extraLightBackgroundGray,
                              borderRadius: BorderRadius.circular(10.sp)
                          ),
                          child: Center(
                            child: Text("Your teams' credentials will appear here",
                              style: TextStyle(color: Colors.blueGrey.shade600,
                              fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,),
                          ))
                          : ListView.builder(
                          itemCount: updatedTeams.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index){
                            return Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 0, 1.h),
                                child: TeamObjectBox(team: updatedTeams[index], refresher: refreshPage,));
                          });
                    },
                  )
                ],
              ),
            ),
          ),
          AnimatedSwitcher(duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: loading ? Container(
            key: const Key('loadingManagerTeam1234'),
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.1),
            child: Center(
              child: CircularPercentIndicator(
                radius: 40.w,
                circularStrokeCap: CircularStrokeCap.round,
                linearGradient: LinearGradient(colors: [Colors.redAccent, Colors.lightBlueAccent]),
                animation: true,
                animateFromLastPercent: true,
                animationDuration: 1000,
                lineWidth: 20.sp,
                backgroundColor: Colors.transparent,
                percent: 1,//teamsDone == 0 ? 0 : (teamsDone / teamsToBe),
                center: CircleAvatar(
                  radius: 32.w,
                    backgroundColor: Colors.white,
                    child: Text('Done With \n $teamsDone teams out of $teamsToBe.', textAlign: TextAlign.center,)),
              ),
            ),
          ) : Container(key: const Key('emptyLMT81279'),),)
        ],
      ),
    );
  }

  generateTeams(int i) async{
    if (widget.teams.length == i){
      showNotification(context, 'Number chosen is equal to teams found.', error: true);
      return;
    }else if (widget.teams.length < i){
     final resp = await showAlertDialog(context, title: 'Create ${i - widget.teams.length} Teams',
          message: 'You will now create ${i - widget.teams.length} NEW teams, please confirm.');
     if (!resp) return;
    }else{
      final resp = await showAlertDialog(context, title: 'Delete ${widget.teams.length - i} Teams',
          message: 'You will now delete the latest ${widget.teams.length - i} teams FOREVER, please confirm.');
      if (!resp) return;
    }
    setState(() {
      loading = true;
    });
    try{
      final data = await FirebaseFirestore.instance.collection('gamesListeners/firstGame/teams')
          .orderBy('username', descending: true).get();
      final allTeams = teamObjectListFromShot(data.docs);
      final pattern = RegExp(r'\d{1,2}$');
      List<int> numbersFound = [];
      for (var team in allTeams){
        final digit = pattern.firstMatch(team.username)!.group(0);
        final string = team.username.substring(0, team.username.length - digit!.length);
        if (string == 'user'){
          int? n = int.tryParse(digit);
          if (n != null) {
            numbersFound.add(n);
          }
        }
      }
      numbersFound.sort((a, b ) => a.compareTo(b));


      if (allTeams.length < i){
        int remTeam = i - allTeams.length;
        teamsToBe = remTeam;
        teamsDone = 0;
        int ind = 0;
        do{
          do{
            ind++;
          }while(numbersFound.contains(ind));
          Map<String, dynamic> newTeam = {
            'teamName': 'Team $ind',
            'username': 'user$ind',
            'password': 'pass${Random().nextInt(9000) + 1000}',
            'bonusSeconds': 0,
            'minusSeconds': 0,
            'loggedIn': 0,
            'devices': [],
            'gameType': ''
          };
          final newTeamData = await FirebaseFirestore.instance.collection('gamesListeners/firstGame/teams').add(newTeam);
          allTeams.add(teamObjectFromShot(newTeam, newTeamData.id));
          remTeam--;
          setState(() {
            print('$teamsDone / $teamsToBe');
            teamsDone = teamsToBe - remTeam;
          });
        }while(remTeam > 0);
      }else{
        int remTeam = allTeams.length - i;
        teamsToBe = remTeam;
        teamsDone = 0;
        int ind = 1;
        do{
          try{
            await data.docs.firstWhere((element) => element
                .data()['username'] == 'user${numbersFound[numbersFound.length - ind]}').reference.delete();
            ind++;
          }catch (e){
            print('Failed to delete an account');
          }
          remTeam--;
          setState(() {
            teamsDone = teamsToBe - remTeam;
          });
        }while(remTeam > 0);
      }
    }on FirebaseException catch (e){
      print(e);
    }
    refreshPage.value = !refreshPage.value;
    setState(() {
      loading = false;
    });
  }
}
