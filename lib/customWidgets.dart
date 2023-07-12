

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
            color: Colors.black,
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
            color: Colors.black,
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
              color: Colors.black,
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



