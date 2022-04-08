import 'package:chat_app/models/message.dart';
import 'package:chat_app/pages/chat/component/file_bubble.dart';
import 'package:chat_app/pages/chat/component/image_bubble.dart';
import 'package:chat_app/pages/chat/component/message_bubble.dart';
import 'package:chat_app/pages/chat/component/video_bubble.dart';
import 'package:chat_app/utils/kind_of_file.dart';
import 'package:flutter/material.dart';

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
      default:
        return const SizedBox.shrink();
    }
  }
}
