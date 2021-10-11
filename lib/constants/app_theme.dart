import 'package:flutter/material.dart';

import 'colors.dart';

final ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  // fontFamily: AppFont.bentonSans,
  primaryColor: AppColor.primary,
  scaffoldBackgroundColor: AppColor.white,
  brightness: Brightness.light,
);
final ThemeData darkTheme = ThemeData(
  primarySwatch: Colors.blue,
  // fontFamily: AppFont.bentonSans,
  primaryColor: AppColor.primary,
  scaffoldBackgroundColor: AppColor.codGray,
  brightness: Brightness.dark,
);
