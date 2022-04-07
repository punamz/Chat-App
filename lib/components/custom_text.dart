import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double? textSize;
  final Color? textColor;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double height;

  const CustomText({
    Key? key,
    this.text = '',
    this.textSize,
    this.textColor,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.start,
    this.height = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: textSize ?? 15.sp,
        fontWeight: fontWeight,
        color: textColor,
        height: height,
      ),
    );
  }
}
