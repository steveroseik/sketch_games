import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sketch_games/configuration.dart';
import 'package:sketch_games/pinput_theme.dart';

class NewSequencePage extends StatefulWidget {
  const NewSequencePage({super.key});

  @override
  State<NewSequencePage> createState() => _NewSequencePageState();
}

class _NewSequencePageState extends State<NewSequencePage> {

  TextEditingController pinCodeField1 = TextEditingController();
  FocusNode firstPin1 = FocusNode();

  TextEditingController pinCodeField2 = TextEditingController();
  FocusNode firstPin2 = FocusNode();

  TextEditingController pinCodeField3 = TextEditingController();
  FocusNode firstPin3 = FocusNode();

  @override
  void dispose() {
    pinCodeField1.dispose();
    pinCodeField2.dispose();
    pinCodeField3.dispose();
    firstPin1.dispose();
    firstPin2.dispose();
    firstPin3.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: Text('New Sequence'),),
        body: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('First Sequence',
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600
                  ),),
              ),
              OnlyBottomCursorAdmin(controller: pinCodeField1, node: firstPin1, onCompleted: (value) => firstPin2.requestFocus()),
              SizedBox(height: 3.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Second Sequence',
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600
                  ),),
              ),
              OnlyBottomCursorAdmin(controller: pinCodeField2, node: firstPin2, onCompleted: (value) => firstPin3.requestFocus(),),
              SizedBox(height: 3.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Third Sequence',
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600
                  ),),
              ),
              OnlyBottomCursorAdmin(controller: pinCodeField3, node: firstPin3),
              Spacer(),
              SizedBox(
                height: 5.h,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async{
                          Navigator.of(context).pop(null);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.sp))
                        ),
                        child: Text('Cancel',
                          style: TextStyle(
                            fontSize: 10.sp,
                          ),),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async{
                          if((pinCodeField1.text.length == 5 &&
                              pinCodeField2.text.length == 5 &&
                              pinCodeField3.text.length == 5) &&
                              (pinCodeField1.text[0] != '0' &&
                                  pinCodeField2.text[0] != '0' &&
                                  pinCodeField3.text[0] != '0')){

                            final seq = [
                              int.tryParse(pinCodeField1.text)!,
                              int.tryParse(pinCodeField2.text)!,
                              int.tryParse(pinCodeField3.text)!,
                            ];
                            print(seq);
                            Navigator.of(context).pop(seq);
                          }else{
                            showNotification(context, 'Sequence codes cannot start with 0 and should have length of 5.', error: true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.sp))
                        ),
                        icon: Icon(Icons.check),
                        label: Text('Confirm',
                          style: TextStyle(
                            fontSize: 10.sp,
                          ),),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5.h),
            ],
          ),
        ),
      ),
    );
  }
}
