import 'package:chat_app/models/user.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBloc {
  final Database database;

  HomeBloc({required this.database});


  Stream<QuerySnapshot> findUserStream(String textSearch) {
    return database.userStream(textSearch);
  }

  Stream<QuerySnapshot> getChatStream(String currentUserId){
    return database.chatStream(currentUserId);
  }

  Future<UserInfor> getUserInfor(String id) async {
    final snapshot = await database.getUserInfor(id);
    final user = UserInfor.fromDocument(snapshot);
    return user;
  }
}
