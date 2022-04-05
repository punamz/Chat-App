import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfo {
  final String id;
  final String name;
  final String photoURL;
  final List<String> msgToken;

  UserInfo({
    required this.id,
    required this.name,
    this.photoURL = '',
    required this.msgToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoURL': photoURL,
      'msgToken': msgToken,
    };
  }

  factory UserInfo.fromDocument(DocumentSnapshot document) {
    return UserInfo(
      id: document.id,
      name: document.get('name'),
      photoURL: document.get('photoURL'),
      msgToken: document.get('msgToken').cast<String>(),
    );
  }
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      name: json['name'],
      photoURL: json['photoURL'],
      msgToken: json['msgToken'].cast<String>(),
    );
  }
}
