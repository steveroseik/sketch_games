import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'appObjects.dart';
import 'package:sizer/sizer.dart';

import 'configuration.dart';

class TeamMembersPage extends StatefulWidget {
  final TeamObject team;
  const TeamMembersPage({super.key, required this.team});

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.team.teamName} Members'),),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            children: [
              SizedBox(height: 4.h),
              ListView.separated(
                  itemCount: widget.team.devices.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index){
                    final device = widget.team.devices[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.black,
                        borderRadius: BorderRadius.circular(15.sp)
                      ),
                     padding: EdgeInsets.symmetric(vertical: 2.w, horizontal: 5.w),
                     child: Row(
                       children: [
                         Text(device.name,
                         style: TextStyle(
                             fontWeight: FontWeight.w700,
                             color: Colors.white,
                             fontSize: 13.sp),
                           overflow: TextOverflow.ellipsis,
                         ),
                         Spacer(),
                         ElevatedButton(
                             onPressed: () async{
                               final response = await showAlertDialog(context, title: "KICK ${device.name}",
                                   message: "You will kick '${device.name}' out of the game.");
                               if (response){
                                 try{
                                   await FirebaseFirestore.instance.doc(widget.team.id)
                                       .update({'devices': FieldValue.arrayRemove([device.toJson()])});
                                   showNotification(context, '${device.name} was sign out successfully.');
                                   widget.team.devices.removeAt(index);
                                   if (widget.team.devices.isEmpty) {
                                     Navigator.of(context).pop();
                                   }else{
                                     setState(() {});
                                   }
                                 }catch (e){
                                   showNotification(context, e.toString(), error: true);
                                 }
                               }
                             },
                             style: ElevatedButton.styleFrom(
                                 backgroundColor: CupertinoColors.destructiveRed,
                                 foregroundColor: Colors.black,
                                 shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(10.sp))
                             ),
                             child: const Text('KICK'))
                       ],
                     ),
                    );
                  }, separatorBuilder: (context, index){
                    return SizedBox(height: 1.h);
              }),
              Spacer(),
              ElevatedButton(
                  onPressed: () async{
                    final response = await showAlertDialog(context, title: "SIGN OUT TEAM",
                        message: "You will Sign '${widget.team.teamName}' Out of all devices.");
                    if (response){
                      try{
                        await FirebaseFirestore.instance.doc(widget.team.id).update({
                          'devices': []
                        });
                        showNotification(context, '${widget.team.teamName} members were sign out successfully.');
                        Navigator.of(context).pop();
                      }catch (e){
                        showNotification(context, e.toString(), error: true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CupertinoColors.black,
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.sp))
                  ),
                  child: const Text('SIGN ALL OUT'))
            ],
          ),
        ),
      ),
    );
  }
}
