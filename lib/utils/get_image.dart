import 'dart:ui';

import 'package:flutter/scheduler.dart';

String getSuitableImage(String lightImage, String darkImage) {
  return SchedulerBinding.instance.window.platformBrightness == Brightness.light
      ? lightImage
      : darkImage;
}
