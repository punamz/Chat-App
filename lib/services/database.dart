import 'package:chat_app/constants/api_path.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Database {
  void saveUserInfo({required UserInfo userInfo});

  void updateUserAvatar({required String url});

  void updateUserName({required String newName});

  void addMsgToken({required String? token});

  void removeMsgToken({required String token});

  Future<List<String>> getMsgToken({required String id});

  Future<void> saveMessage({required Message message});

  void createChat({required String chatId});

  void updateLikeMessage({required Message message});

  Stream<QuerySnapshot> userStream({required String textSearch});

  Stream<QuerySnapshot> chatStream();

  Stream<QuerySnapshot> messageStream(
      {required String chatId, required int limit});

  Future<DocumentSnapshot> getUserInfo({required String id});
}

class FireStoreDatabase implements Database {
  FireStoreDatabase({required this.uid});

  final String uid;

  @override
  void saveUserInfo({required UserInfo userInfo}) {
    try {
      final path = APIPath.user(userInfo.id);
      final documentReference = FirebaseFirestore.instance.doc(path);
      documentReference.set(userInfo.toMap());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<QuerySnapshot> userStream({required String textSearch}) {
    final path = APIPath.users();
    return FirebaseFirestore.instance
        .collection(path)
        .where('name', isEqualTo: textSearch)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> chatStream() {
    final path = APIPath.chats();
    return FirebaseFirestore.instance
        .collection(path)
        .where('members', arrayContains: uid)
        .snapshots();
  }

  @override
  Future<DocumentSnapshot> getUserInfo({required String id}) async {
    final path = APIPath.user(id);
    return await FirebaseFirestore.instance.doc(path).get();
  }

  @override
  Stream<QuerySnapshot> messageStream(
      {required String chatId, required int limit}) {
    final path = APIPath.messages();
    return FirebaseFirestore.instance
        .collection(path)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  @override
  Future<void> saveMessage({required Message message}) async {
    final path = APIPath.message(message.id);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.set(message.toMap());
    bool isChatExit = await checkChatIdExists(message.chatId);
    if (!isChatExit) createChat(chatId: message.chatId);
  }

  Future<bool> checkChatIdExists(String chatId) async {
    final path = APIPath.chat(chatId);
    final documentReference = await FirebaseFirestore.instance.doc(path).get();
    return documentReference.exists;
  }

  @override
  void createChat({required String chatId}) {
    final path = APIPath.chat(chatId);
    final ids = chatId.split('->');
    final documentReference = FirebaseFirestore.instance.doc(path);

    documentReference.set({'members': ids});
  }

  @override
  void updateLikeMessage({required Message message}) {
    final path = APIPath.message(message.id);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.update({'like': !message.like});
  }

  @override
  void updateUserAvatar({required String url}) {
    final path = APIPath.user(uid);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.update({'photoURL': url});
  }

  @override
  void updateUserName({required String newName}) {
    final path = APIPath.user(uid);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.update({'name': newName});
  }

  @override
  void addMsgToken({required String? token}) {
    if (token == null) return;
    final path = APIPath.user(uid);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.update({
      'msgToken': FieldValue.arrayUnion([token])
    });
  }

  @override
  void removeMsgToken({required String token}) {
    final path = APIPath.user(uid);
    final documentReference = FirebaseFirestore.instance.doc(path);
    documentReference.update({
      'msgToken': FieldValue.arrayRemove([token])
    });
  }

  @override
  Future<List<String>> getMsgToken({required String id}) async {
    final path = APIPath.user(id);
    final documentSnapshot = await FirebaseFirestore.instance.doc(path).get();
    return documentSnapshot.get('msgToken').cast<String>();
  }
}
