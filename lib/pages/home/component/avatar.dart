import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({Key? key, this.photoURL, this.sized = 30.0}) : super(key: key);
  final String? photoURL;

  final double sized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(25)),
      clipBehavior: Clip.hardEdge,
      child: Image.network(
        photoURL!,
        width: sized,
        height: sized,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: sized,
            width: sized,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, object, stackTrace) {
          return Icon(
            Icons.account_circle_rounded,
            size: sized,
            color: getSuitableColor(AppColor.doveGray, AppColor.wildSand),
          );
        },
      ),
    );
  }
}
