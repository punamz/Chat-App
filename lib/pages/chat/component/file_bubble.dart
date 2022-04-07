import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:chat_app/utils/time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FileBubble extends StatelessWidget {
  const FileBubble({
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
    return GestureDetector(
      onTap: downloadFile,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 50.w : 0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 15.w,
          vertical: 10.h,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColor.primary : AppColor.doveGray.withOpacity(0.3),
          borderRadius: isMe
              ? BorderRadius.only(
                  topLeft: Radius.circular(Dimens.radius),
                  bottomLeft: Radius.circular(Dimens.radius),
                )
              : BorderRadius.only(
                  topRight: Radius.circular(Dimens.radius),
                  bottomRight: Radius.circular(Dimens.radius),
                ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.download_rounded,
                  color: isMe
                      ? AppColor.white
                      : getSuitableColor(AppColor.black, AppColor.white),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: CustomText(
                    text: message.message,
                    textColor: AppColor.white,
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomText(
                  text: dayFormat(message.timestamp),
                  textSize: 10.sp,
                  fontWeight: FontWeight.w200,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
