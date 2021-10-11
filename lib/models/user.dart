import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfor {
  final String id;
  final String name;
  final String photoURL;

  UserInfor({
    required this.id,
    required this.name,
    this.photoURL = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoURL': photoURL,
    };
  }

  factory UserInfor.fromDocument(DocumentSnapshot document) {
    return UserInfor(
      id: document.id,
      name: document.get('name'),
      photoURL: document.get('photoURL'),
    );
  }
}
