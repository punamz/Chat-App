import 'dart:async';
import 'dart:io';

import 'package:chat_app/models/message.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/storageDatabase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatBloc {
  final Database database;

  ChatBloc({required this.database});

  final StreamController<double> _downloadStatusController =
      StreamController<double>();

  Stream<double> get downloadStream => _downloadStatusController.stream;

  void dispose() {
    _downloadStatusController.close();
  }

  Stream<QuerySnapshot> getMessageStream(String chatId, int limit) {
    return database.messageStream(chatId, limit);
  }

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
    database.saveMessage(message);
  }

  void likeMessage(Message message) {
    database.updateLikeMessage(message);
  }

  UploadTask? uploadFile(File file) {
    final fileName = basename(file.path);
    final destination = 'files/$fileName';
    return StorageDatabase.uploadFile(destination, file);
  }

  Future<String> downloadFile(String filename, String url) async {
    await Permission.storage.request();
    Dio dio = Dio();
    var dir;
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
