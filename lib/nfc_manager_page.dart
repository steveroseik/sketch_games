import 'dart:convert';
import 'dart:io';
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:sizer/sizer.dart';
import 'package:sketch_games/configuration.dart';
import 'package:sketch_games/customWidgets.dart';

class NfcManagerPage extends StatefulWidget {
  const NfcManagerPage({super.key});

  @override
  State<NfcManagerPage> createState() => _NfcManagerPageState();
}

class _NfcManagerPageState extends State<NfcManagerPage> {

  TextEditingController _controller = TextEditingController();

  String? NFCMessage;
  late AnimationController controller;
  late Animation animation;
  bool positive = true;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Column(
            children: [
              Text('NFC TAG MANAGER',
                style: TextStyle(
                    fontFamily: 'Quartzo',
                    fontSize: 25.sp
                ),
                textAlign: TextAlign.center,),
              SizedBox(height: 5.h,),
              Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),),
                    child: NFCMessage == null ? Container(key: Key('emptycontainer298761')) :
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.grey),
                        borderRadius: BorderRadius.circular(15.sp),
                      ),
                      padding: EdgeInsets.all(5.w),
                      child: Text(
                        'content scanned:\n${NFCMessage!}',
                        style: TextStyle(fontFamily: 'Quartzo', fontSize: 15.sp),
                      textAlign: TextAlign.center, ),
                    ),
                  )
              ),
              SizedBox(height: 5.h),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.h),
                    label: Text('Seconds'),
                    hintText: 'Ex: 200',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.sp)
                    ),
                  prefixIcon: IconButton(
                    onPressed: (){
                      setState(() {
                        positive = !positive;
                      });
                    },
                    icon: Icon(positive ? CupertinoIcons.plus : CupertinoIcons.minus),
                  )
                ),
              ),
              SizedBox(height: 3.w),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.sp),
                          )
                      ),
                      onPressed: (){
                        FocusScope.of(context).requestFocus(FocusNode());
                        if (NFCMessage != null ){
                          setState(() {
                            NFCMessage = null;
                          });
                        }
                        if(_controller.text.isEmpty){
                          showNotification(context, 'No content to be written to the NFC tag', error: true);
                        }else{
                          _listenForNFCEvents(write: true, content: '${positive ? '+' : '-'}${_controller.text}');
                        }
                      },
                      child: const Text('WRITE',
                        style: TextStyle(
                          fontFamily: 'Quartzo',
                        ),),),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.sp),
                          )
                      ),
                      onPressed: () async{
                        FocusScope.of(context).requestFocus(FocusNode());
                        if (NFCMessage != null ){
                          setState(() {
                            NFCMessage = null;
                          });
                        }
                        _listenForNFCEvents();
                      },
                      child: const Text('SCAN',
                        style: TextStyle(
                          fontFamily: 'Quartzo',
                        ),),),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.sp),
                      )
                  ),
                  onPressed: () async{
                    final duration = await myDurationPicker(context);
                    if (duration != null){
                      _controller.text = duration.inSeconds.toString();
                    }
                  },
                  child: const Text('GENERATE DURATION',
                    style: TextStyle(
                      fontFamily: 'Quartzo',
                    ),),),
              ),
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
        print('NFC listener running in background now, approach tag(s)',);
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
                print("Writting failed: $e");
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
                  setState(() {
                    NFCMessage = payload;
                  });
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
        print('finished');
      });
    }
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
}
