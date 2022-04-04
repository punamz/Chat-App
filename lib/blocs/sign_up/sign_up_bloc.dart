import 'dart:async';

import 'package:chat_app/constants/strings.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:rxdart/rxdart.dart';

class SignUpBloc {
  SignUpBloc({required this.auth});

  final AuthBase auth;

  final StreamController<bool> _isLoadingController = StreamController<bool>();
  final _fullNameController = BehaviorSubject<String?>();
  final _emailController = BehaviorSubject<String?>();
  final _passwordController = BehaviorSubject<String?>();

  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  Stream<String?> get fullNameStream => _fullNameController.stream;

  Stream<String?> get emailStream => _emailController.stream;

  Stream<String?> get passwordStream => _passwordController.stream;

  void dispose() {
    _isLoadingController.close();
    _fullNameController.close();
    _emailController.close();
    _passwordController.close();
  }

  void _setIsLoading(bool isLoading) => _isLoadingController.add(isLoading);

  Future<bool> createUserWithEmailAndPassword(
      String name, String email, String password) async {
    if (name.isEmpty) {
      _fullNameController.sink.add(Strings.nameNullError);
    } else {
      _fullNameController.sink.add(null);
    }
    if (email.isEmpty) {
      _emailController.sink.add(Strings.emailNullError);
    } else {
      _emailController.sink.add(null);
    }
    if (password.isEmpty) {
      _passwordController.sink.add(Strings.passNullError);
    } else {
      _passwordController.sink.add(null);
    }
    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      try {
        _setIsLoading(true);
        final user = await auth.createUserWithEmailAndPassword(email, password);
        await user!.updateDisplayName(name);
        FireStoreDatabase(uid: user.uid).saveUserInfo(
          userInfo: UserInfo(
            id: user.uid,
            name: name,
            photoURL: user.photoURL ?? '',
            msgToken: [],
          ),
        );
        return true;
      } catch (e) {
        _setIsLoading(false);
        rethrow;
      }
    }
    return false;
  }
}
