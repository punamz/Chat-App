import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double textSize;
  final Color textColor;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double height;

  const CustomText({
    this.text = '',
    this.textSize: 15.0,
    this.textColor: Colors.black,
    this.fontWeight: FontWeight.normal,
    this.textAlign: TextAlign.start,
    this.height: 1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: textSize,
        fontWeight: fontWeight,
        color: textColor,
        height: height,
      ),
    );
  }
}
