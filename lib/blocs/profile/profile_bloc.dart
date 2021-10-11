import 'dart:io';

import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/storageDatabase.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class ProfileBloc {
  final Database database;

  ProfileBloc({required this.database});

  UploadTask? uploadFile(File file) {
    final fileName = basename(file.path);
    final destination = 'files/$fileName';
    return StorageDatabase.uploadFile(destination, file);
  }

  Future<void> updateAvatar(String url) async {
    final currentUser = Auth().currentUser!;
    await currentUser.updatePhotoURL(url);
    database.updateUserAvatar(currentUser.uid, url);
  }

  void updateName(String name) {
    final currentUser = Auth().currentUser!;
    currentUser.updateDisplayName(name);
    database.updateUserName(currentUser.uid, name);
  }
}
