import 'package:chat_app/utils/kind_of_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String sendBy;
  final String chatId;
  final String timestamp;
  final String message;
  final int type;
  final bool like;
  final String? url;

  Message(
      {required this.id,
      required this.sendBy,
      required this.chatId,
      required this.timestamp,
      required this.message,
      required this.type,
      required this.like,
      this.url});

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'message': message,
      'send by': sendBy,
      'timestamp': timestamp,
      'type': type,
      'like': like,
      if (url != null) 'url': url,
    };
  }

  factory Message.fromDocument(DocumentSnapshot doc) {
    int type = doc.get('type');
    return Message(
      id: doc.id,
      chatId: doc.get('chatId'),
      sendBy: doc.get('send by'),
      timestamp: doc.get('timestamp'),
      message: doc.get('message'),
      type: doc.get('type'),
      like: doc.get('like'),
      url: type == fileType ? doc.get('url') : null,
    );
  }
}
