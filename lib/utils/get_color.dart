import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

Color getSuitableColor(Color lightColor, Color darkColor) {
  return SchedulerBinding.instance.window.platformBrightness == Brightness.light
      ? lightColor
      : darkColor;
}
