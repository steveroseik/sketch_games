import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:sketch_games/appObjects.dart';
import 'package:sketch_games/customWidgets.dart';
import 'package:sketch_games/pinput_theme.dart';

class SequenceSelectionPage extends StatefulWidget {
  const SequenceSelectionPage({super.key});

  @override
  State<SequenceSelectionPage> createState() => _SequenceSelectionPageState();
}

class _SequenceSelectionPageState extends State<SequenceSelectionPage> {

  bool loading = true;

  List<List<int>> previousSequences = [[76532, 29682, 39403]];

  @override
  void initState() {
    loadPreviousSequences();
    super.initState();
  }

  loadPreviousSequences() async{
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('sequences')){
      final data = jsonDecode(prefs.getString('sequences')!);
      previousSequences = List<List<int>>.from(data['sequences'].map((x) => List<int>.from(x)));
    }

    setState(() {
      loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select A Sequence'),),
      body: loading ? loadingWidget(loading) : Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async{
                    Navigator.of(context).pushNamed('/newSequence').then((value) async{
                      if (value != null && value is List<int>){
                        print(value);
                        setState(() {
                          previousSequences.add(value);
                        });
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setString('sequences', jsonEncode({'sequences': previousSequences}));
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.sp))
                  ),
                  icon: const Icon(Icons.password_rounded, color: Colors.white),
                  label: Text('Add new Sequence',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                    ),),
                ),
              ),
              SizedBox(
                height: 3.h,
              ),
              SizedBox(
                width: 80.w,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, i){
                    return SizedBox(height: 3.h);
                  },
                  itemCount: previousSequences.length,
                    itemBuilder: (context, i){
                    return Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.sp),
                        color: CupertinoColors.extraLightBackgroundGray
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Text('1: ',
                                style: TextStyle(color: Colors.blueGrey.shade900, fontWeight: FontWeight.w600),),
                              SequenceContainer(number: previousSequences[i][0]),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Text('2: ', style: TextStyle(color: Colors.blueGrey.shade900, fontWeight: FontWeight.w600),),
                              SequenceContainer(number: previousSequences[i][1]),
                            ],
                          ),
                          Row(
                            children: [
                              Text('3: ', style: TextStyle(color: Colors.blueGrey.shade900, fontWeight: FontWeight.w600),),
                              SequenceContainer(number: previousSequences[i][2]),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () async{
                                    Navigator.of(context).pop(previousSequences[i]);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey.shade900,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.sp))
                                  ),
                                  icon: Icon(CupertinoIcons.back, size: 15.sp),
                                  label: const FittedBox(
                                    child: Text('Select Sequence',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),),
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: () async{
                                   setState(() {
                                     previousSequences.removeAt(i);
                                   });
                                   final prefs = await SharedPreferences.getInstance();
                                   prefs.setString('sequences', jsonEncode({'sequences': previousSequences}));
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade300,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.sp))
                                  ),
                                  child: Icon(CupertinoIcons.delete)
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
