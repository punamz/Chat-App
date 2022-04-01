import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String? icon;
  final Widget child;
  final Color color;
  final double borderRadius;
  final VoidCallback? onPressed;

  const CustomButton({
    this.color: AppColor.primary,
    this.borderRadius: Dimens.radius,
    required this.onPressed,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ElevatedButton(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) Image.asset(icon!),
          child,
        ],
      ),
      style: ElevatedButton.styleFrom(
        primary: color,
        onPrimary: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadius),
          ),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
