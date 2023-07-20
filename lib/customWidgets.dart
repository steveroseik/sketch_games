

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'configuration.dart';

Widget timeWidget(DateTime time){
  final now = DateTime.now();
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AnimatedContainer(
        height: 9.w,
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
            color: Colors.blueGrey.shade600,
            borderRadius: BorderRadius.circular(15.sp)
        ),
        padding: EdgeInsets.symmetric(horizontal: 15.sp, vertical: 7.sp),
        child: FittedBox(
          child: Text(
            isSameDay(time, now) ? 'TODAY ' : '${time.year}-${time.month}-${time.day}',
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
            style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,),
        ),
      ),
      SizedBox(width: 1.w,),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 7.w,
        height: 7.w,
        decoration: BoxDecoration(
            color: Colors.blueGrey.shade600,
            borderRadius: BorderRadius.circular(4.sp)
        ),
        padding: EdgeInsets.all(4),
        child: FittedBox(
          child: Text('${(time.hour.toString().length < 2 ? '0': '')}'
              '${time.hour.toString()}',
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
            color: Colors.blueGrey.shade600,
            borderRadius: BorderRadius.circular(4.sp)
        ),
        padding: EdgeInsets.all(4),
        child: FittedBox(
          child: Text('${(time.minute.toString().length < 2 ? '0': '')}'
              '${time.minute}',
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
              color: Colors.blueGrey.shade600,
              borderRadius: BorderRadius.circular(4.sp)
          ),
          padding: EdgeInsets.all(4),
          child: FittedBox(
            child: Text('${(time.second.toString().length < 2 ? '0': '')}'
                '${time.second}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700,),
              textAlign: TextAlign.center,),
          )
      )
    ],
  );
}

Future<Duration?> myDurationPicker(BuildContext context) async {
  int days = 0;
  int hours = 0;
  int minutes = 0;
  int seconds = 0;
  Duration? duration;
  await showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        height: 45.h,
        padding: EdgeInsets.symmetric(vertical: 4.w),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children:[
                  FilledButton(
                    child: Text("Cancel", style: TextStyle(color: Colors.red)),
                    style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.sp)
                        ),
                        backgroundColor: Colors.white),
                    onPressed: () {

                      Navigator.of(context).pop(null);
                    },
                  ),
                  Spacer(),
                  FilledButton(
                    child: Text("Confirm"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.sp)
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(Duration(
                        days: days,
                        hours: hours,
                        minutes: minutes,
                        seconds: seconds,
                      ));
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildPicker('Days', 8, (index) => days = index),
                buildPicker('Hours', 24, (index) => hours = index),
                buildPicker('Minutes', 60, (index) => minutes = index),
                buildPicker('Seconds', 60, (index) => seconds = index),
              ],
            ),
          ],
        ),
      );
    },
  ).then((value) {
    if (value != null){
      duration = Duration(
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      );
    }
  });

  return duration;
}

Widget buildPicker(String label, int itemCount, ValueChanged<int> onChanged) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 2.h),
      SizedBox(
        width: 25.w,
        height: 20.h,
        child: CupertinoPicker(
          selectionOverlay: Container(
            margin:  label == 'Days' ? EdgeInsets.only(left: 4.w) :  label == 'Seconds' ? EdgeInsets.only(right: 4.w) : null,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: label == 'Days' ? BorderRadius.only(topLeft: Radius.circular(5.sp), bottomLeft: Radius.circular(5.sp)) :
                            label == 'Seconds' ? BorderRadius.only(topRight: Radius.circular(5.sp), bottomRight: Radius.circular(5.sp)) : null
            ),
          ),
          magnification: 1.2,
          backgroundColor: Colors.transparent,
          itemExtent: 5.h,
          looping: true,
          onSelectedItemChanged: onChanged,
          children: List.generate(itemCount, (index) => index.toString())
              .map((e) => Padding(
            padding: EdgeInsets.symmetric(vertical: 0.5.h),
                child: Center(
            child: Text(e, style: TextStyle(fontSize: 15.sp)),
          ),
              ))
              .toList(),
        ),
      ),
    ],
  );
}

class SequenceContainer extends StatelessWidget {
  final int number;

  const SequenceContainer({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    String numberString = number.toString();
    List<int> digits = numberString.split('').map(int.parse).toList();

    List<Widget> boxes = digits.map((digit) {
      return Container(
        width: 7.w,
        height: 7.w,
        margin: EdgeInsets.all(1.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.sp),
          color: Colors.blueGrey,
        ),
        child: Center(
          child: Text(
            digit.toString(),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white,
            ),
          ),
        ),
      );
    }).toList();

    return  Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: boxes,
      ),
    );
  }
}




