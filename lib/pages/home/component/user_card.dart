import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/pages/home/component/avatar.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserCard extends StatelessWidget {
  const UserCard({Key? key, required this.onTap, required this.user})
      : super(key: key);
  final void Function() onTap;
  final UserInfo user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimens.radius),
        color: getSuitableColor(AppColor.wildSand, AppColor.mineShaft),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: 5.w,
        vertical: 5.h,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 5.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radius),
        ),
        tileColor: getSuitableColor(AppColor.wildSand, AppColor.mineShaft),
        onTap: onTap.call,
        leading: Material(
          color: Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(25)),
          clipBehavior: Clip.hardEdge,
          child: user.photoURL.isNotEmpty
              ? Avatar(
                  photoURL: user.photoURL,
                  sized: 50,
                )
              : Icon(
                  Icons.account_circle_rounded,
                  size: 50,
                  color: getSuitableColor(AppColor.doveGray, AppColor.wildSand),
                ),
        ),
        title: CustomText(
          text: user.name,
          textSize: 16.sp,
          fontWeight: FontWeight.w500,
          textColor: getSuitableColor(AppColor.black, AppColor.white),
        ),
      ),
    );
  }
}
