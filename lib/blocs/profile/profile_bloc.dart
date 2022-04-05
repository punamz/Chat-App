import 'dart:io';

import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/notification.dart';
import 'package:chat_app/services/storage_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class ProfileBloc {
  final Database database;

  ProfileBloc({required this.database});

  UploadTask? uploadFile(File file) {
    final currentUser = Auth().currentUser!;
    final fileName = basename(file.path);
    final destination = 'avatar/${currentUser.uid}/$fileName';
    return StorageDatabase.uploadFile(destination, file);
  }

  Future<void> updateAvatar(String url) async {
    final currentUser = Auth().currentUser!;
    await currentUser.updatePhotoURL(url);
    database.updateUserAvatar(url: url);
  }

  void updateName(String name) {
    final currentUser = Auth().currentUser!;
    currentUser.updateDisplayName(name);
    database.updateUserName(newName: name);
  }

  void logout() {
    Auth().signOut();
    database.removeMsgToken(token: currentDeviceMsgToken ?? "");
  }
}
