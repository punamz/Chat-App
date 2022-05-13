import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final double? borderRadius;
  final VoidCallback? onPressed;

  const CustomButton({
    Key? key,
    this.color = AppColor.primary,
    this.borderRadius,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: color,
        onPrimary: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadius ?? Dimens.radius),
          ),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
