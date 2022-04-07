import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/components/video_player.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/pages/chat/component/file_bubble.dart';
import 'package:chat_app/pages/chat/component/image_bubble.dart';
import 'package:chat_app/pages/chat/component/message_bubble.dart';
import 'package:chat_app/pages/chat/component/video_bubble.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:chat_app/utils/kind_of_file.dart';
import 'package:chat_app/utils/time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.downloadFile,
  }) : super(key: key);
  final Message message;
  final bool isMe;
  final void Function()? downloadFile;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case messageType:
        return MessageBubble(message: message, isMe: isMe);
      case imageType:
        return ImageBubble(message: message, isMe: isMe);
      case videoType:
        return VideoBubble(message: message, isMe: isMe);
      case fileType:
        return FileBubble(
            message: message, isMe: isMe, downloadFile: downloadFile);
      //   GestureDetector(
      //   onTap: downloadFile,
      //   child: Column(
      //     children: [
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.start,
      //         children: [
      //           Icon(
      //             Icons.download_rounded,
      //             color: isMe
      //                 ? AppColor.white
      //                 : getSuitableColor(AppColor.black, AppColor.white),
      //           ),
      //           SizedBox(width: 10.w),
      //           Flexible(
      //             child: CustomText(
      //               text: message.message,
      //               textColor: AppColor.white,
      //             ),
      //           )
      //         ],
      //       ),
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.end,
      //         children: [
      //           CustomText(
      //             text: dayFormat(message.timestamp),
      //             textSize: 10.w,
      //             fontWeight: FontWeight.w200,
      //           )
      //         ],
      //       )
      //     ],
      //   ),
      // );
      default:
        return const SizedBox.shrink();
    }
  }
}
