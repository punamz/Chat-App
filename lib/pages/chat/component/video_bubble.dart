import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/components/video_player.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:chat_app/utils/time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VideoBubble extends StatelessWidget {
  const VideoBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);
  final Message message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isMe ? 50.w : 0),
      child: Column(
        children: [
          VideoPlayer(videoUrl: message.message),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomText(
                text: dayFormat(message.timestamp),
                textSize: 10.sp,
                fontWeight: FontWeight.w200,
                textColor: getSuitableColor(AppColor.black, AppColor.white),
              )
            ],
          )
        ],
      ),
    );
  }
}
