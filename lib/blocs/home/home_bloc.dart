import 'package:chat_app/models/user.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBloc {
  final Database database;

  HomeBloc({required this.database});

  Stream<QuerySnapshot> findUserStream(String textSearch) =>
      database.userStream(textSearch: textSearch);

  Stream<QuerySnapshot> getChatStream() => database.chatStream();

  Future<UserInfo> getUserInfo(String id) async {
    final snapshot = await database.getUserInfo(id: id);
    final user = UserInfo.fromDocument(snapshot);
    return user;
  }
}
