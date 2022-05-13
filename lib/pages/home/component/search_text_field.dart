import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchTextField extends StatelessWidget {
  const SearchTextField(
      {Key? key,
      required this.controller,
      required this.onChange,
      required this.onClear})
      : super(key: key);
  final TextEditingController controller;
  final void Function(String) onChange;
  final void Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Dimens.slightHorizontalMargin,
      ),
      height: 45.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimens.radius),
        color: getSuitableColor(AppColor.wildSand, AppColor.mineShaft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 10.w),
          Icon(
            Icons.search,
            color: AppColor.doveGray,
            size: 20.w,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChange,
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixIcon: IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                ),
                hintText: 'Search',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: AppColor.doveGray,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
