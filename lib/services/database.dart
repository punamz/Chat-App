import 'package:chat_app/constants/api_path.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Database {
  void saveUserInfor(UserInfor user);

  void updateUserAvatar(String uid, String url);

  void updateUserName(String uid, String newName);

  Future<void> saveMessage(Message message);

  void createChat(String chatId);

  void updateLikeMessage(Message message);

  Stream<QuerySnapshot> userStream(String textSearch);

  Stream<QuerySnapshot> chatStream(String currentUserID);

  Stream<QuerySnapshot> messageStream(String chatId, int limit);

  Future<DocumentSnapshot> getUserInfor(String id);
}

class FireStoreDatabase implements Database {
  FireStoreDatabase({required this.uid});

  final String uid;

  @override
  void saveUserInfor(user) {
    // TODO: implement saveUserInfor
    try {
      final path = APIPath.user(user.id);
      final documentReference = FirebaseFirestore.instance.doc(path);
      documentReference.set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot> userStream(String textSearch) {
    final path = APIPath.users();
    return FirebaseFirestore.instance
        .collection(path)
        .where('name', isEqualTo: textSearch)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> chatStream(String currentUserID) {
    // TODO: implement chatStream
    final path = APIPath.chats();
    return FirebaseFirestore.instance
        .collection(path)
        .where('members', arrayContains: currentUserID)
        .snapshots();
  }

  @override
  Future<DocumentSnapshot> getUserInfor(String id) async {
    // TODO: implement getUserInfor
    final path = APIPath.user(id);
    return await FirebaseFirestore.instance.doc(path).get();
  }

  @override
  Stream<QuerySnapshot> messageStream(String chatId, int limit) {
    final path = APIPath.messages();
    return FirebaseFirestore.instance
        .collection(path)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  @override
  Future<void> saveMessage(Message message) async {
    final path = APIPath.message(message.id);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.set(message.toMap());
    bool isChatExit = await checkChatIdExists(message.chatId);
    if (!isChatExit) createChat(message.chatId);
  }

  Future<bool> checkChatIdExists(String chatId) async {
    final path = APIPath.chat(chatId);
    final documentReference = await FirebaseFirestore.instance.doc(path).get();
    return documentReference.exists;
  }

  @override
  void createChat(String chatId) {
    // TODO: implement createChat
    final path = APIPath.chat(chatId);
    final ids = chatId.split('->');
    final documentReference = FirebaseFirestore.instance.doc(path);

    documentReference.set({'members': ids});
  }

  @override
  void updateLikeMessage(Message message) {
    // TODO: implement updateLikeMessage
    final path = APIPath.message(message.id);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.update({'like': !message.like});
  }

  @override
  void updateUserAvatar(String uid, String url) {
    // TODO: implement updateUserAvatar
    final path = APIPath.user(uid);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.update({'photoURL': url});
  }

  @override
  void updateUserName(String uid, String newName) {
    // TODO: implement updateUserName
    final path = APIPath.user(uid);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.update({'name': newName});
  }
}
