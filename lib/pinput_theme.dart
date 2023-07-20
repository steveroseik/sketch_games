import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:sizer/sizer.dart';

class OnlyBottomCursor extends StatefulWidget {
  final FocusNode node;
  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  const OnlyBottomCursor({Key? key,
    required this.controller, required this.node, this.onCompleted}) : super(key: key);

  @override
  _OnlyBottomCursorState createState() => _OnlyBottomCursorState();

  @override
  String toStringShort() => 'With Bottom Cursor';
}

class _OnlyBottomCursorState extends State<OnlyBottomCursor> {
  final controller = TextEditingController();
  late FocusNode focusNode;

  void handleCompleted(String value) {
    if (widget.onCompleted != null) {
      widget.onCompleted!(value);
    }
  }

  @override
  void initState() {
    focusNode = widget.node;
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Colors.green;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22.sp,
        color: Colors.green,
        fontFamily: 'digital'
      ),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.green)
      ),
    );

    final cursor = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
    final preFilledWidget = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );

    return Pinput(
      length: 5,
      pinAnimationType: PinAnimationType.slide,
      controller: widget.controller,
      focusNode: focusNode,
      defaultPinTheme: defaultPinTheme,
      showCursor: true,
      cursor: cursor,
      preFilledWidget: preFilledWidget,
      onCompleted: (value) => handleCompleted(value),
    );
  }
}


class OnlyBottomCursorAdmin extends StatefulWidget {
  final FocusNode node;
  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  const OnlyBottomCursorAdmin({Key? key,
    required this.controller, required this.node, this.onCompleted}) : super(key: key);

  @override
  _OnlyBottomCursorStateAdmin createState() => _OnlyBottomCursorStateAdmin();

  @override
  String toStringShort() => 'With Bottom Cursor';
}

class _OnlyBottomCursorStateAdmin extends State<OnlyBottomCursorAdmin> {
  final controller = TextEditingController();
  late FocusNode focusNode;

  void handleCompleted(String value) {
    if (widget.onCompleted != null) {
      widget.onCompleted!(value);
    }
  }

  @override
  void initState() {
    focusNode = widget.node;
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color.fromRGBO(30, 60, 87, 1);

    const defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(),
    );

    final cursor = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
    final preFilledWidget = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: CupertinoColors.extraLightBackgroundGray,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );

    return Pinput(
      length: 5,
      pinAnimationType: PinAnimationType.slide,
      controller: widget.controller,
      focusNode: focusNode,
      defaultPinTheme: defaultPinTheme,
      showCursor: true,
      cursor: cursor,
      preFilledWidget: preFilledWidget,
      onCompleted: (value) => handleCompleted(value),
    );
  }
}