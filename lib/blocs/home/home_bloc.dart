import 'package:chat_app/models/user.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBloc {
  final Database database;

  HomeBloc({required this.database});

  Stream<List<UserInfo>> findUserStream(String textSearch) async* {
    final List<UserInfo> usersInfo = [];
    database.userStream(textSearch: textSearch).listen((event) {
      final data = event.docs;
      usersInfo.clear();
      for (var user in data) {
        if (true) {
          usersInfo.add(UserInfo.fromDocument(user));
        }
      }
    });

    yield usersInfo;
  }

  Stream<QuerySnapshot> getChatStream() => database.chatStream();

  Future<UserInfo> getUserInfo(String id) async {
    final snapshot = await database.getUserInfo(id: id);
    final user = UserInfo.fromDocument(snapshot);
    return user;
  }
}
