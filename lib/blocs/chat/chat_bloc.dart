import 'dart:async';
import 'dart:io';

import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user.dart' as u;
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/notification.dart';
import 'package:chat_app/services/storage_database.dart';
import 'package:chat_app/utils/kind_of_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ChatBloc {
  final Database database;
  final NotificationBase notification;

  ChatBloc({required this.database, required this.notification});

  final StreamController<double> _downloadStatusController =
      StreamController<double>();

  Stream<double> get downloadStream => _downloadStatusController.stream;

  void dispose() {
    _downloadStatusController.close();
  }

  Stream<QuerySnapshot> getMessageStream(String chatId, int limit) =>
      database.messageStream(chatId: chatId, limit: limit);

  void sendMessage({
    required String content,
    required String chatId,
    required String senderId,
    required int type,
    String? url,
  }) {
    final message = Message(
      id: senderId + DateTime.now().millisecondsSinceEpoch.toString(),
      sendBy: senderId,
      chatId: chatId,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      message: content,
      like: false,
      url: url,
    );
    database.saveMessage(message: message);
  }

  Future<void> sendNotices({
    required u.UserInfo receiver,
    required User sender,
    required String message,
    required int type,
  }) async {
    List<String> msgToken = await database.getMsgToken(id: receiver.id);

    /// if receiver does login any device
    /// we don't need to send notification
    if (msgToken.isEmpty) return;

    String body = '';
    switch (type) {
      case messageType:
        body = message;
        break;
      case videoType:
        body = '${sender.displayName} send a video to you';
        break;
      case imageType:
        body = '${sender.displayName} send a picture to you';
        break;
      case fileType:
        body = '${sender.displayName} send a file to you';
        break;
      default:
        body = '${sender.displayName} send a message';
        break;
    }
    final Map<String, dynamic> param = {
      'notification': {
        'body': body,
        'title': sender.displayName ?? 'App Chat',
        'android_channel_id': '02862582324',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'image': type == imageType ? message : null,
        'sound': 'enable',
      },
      'priority': 'high',
      'data': {
        'page': 'ChatPage',
        'arguments': {
          'userInfo': {
            'id': sender.uid,
            'name': sender.displayName,
            'photoURL': sender.photoURL,
            'msgToken': [currentDeviceMsgToken],
          }
        },
      },
      'registration_ids': msgToken,
      'apns': {
        'payload': {
          'aps': {'sound': 'default'}
        }
      }
    };
    notification.sendNotification(param: param);
  }

  void likeMessage(Message message) =>
      database.updateLikeMessage(message: message);

  UploadTask? uploadFile(File file, String chatID) {
    final fileName = basename(file.path);
    final destination =
        'files/$chatID/$fileName-at-${DateTime.now().millisecondsSinceEpoch}';
    return StorageDatabase.uploadFile(destination, file);
  }

  Future<String> downloadFile(String filename, String url) async {
    Dio dio = Dio();
    String dir = "";
    if (Platform.isAndroid) {
      dir = "/sdcard/download/";
    } else {
      dir = (await getApplicationDocumentsDirectory()).path;
    }

    final file = '$dir/$filename';

    await dio.download(
      url,
      file,
      onReceiveProgress: (receivedBytes, totalBytes) {
        _downloadStatusController.sink.add((receivedBytes / totalBytes) * 100);
      },
    );

    return file;
  }
}
