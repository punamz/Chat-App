import 'dart:async';

import 'package:chat_app/constants/strings.dart';
import 'package:chat_app/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class LoginBloc {
  LoginBloc({required this.auth});

  final AuthBase auth;

  final StreamController<bool> _isLoadingController = StreamController<bool>();
  final _emailController = BehaviorSubject<String?>();
  final _passwordController = BehaviorSubject<String?>();

  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  Stream<String?> get emailStream => _emailController.stream;

  Stream<String?> get passwordStream => _passwordController.stream;

  void dispose() {
    _isLoadingController.close();
    _emailController.close();
    _passwordController.close();
  }

  void _setIsLoading(bool isLoading) =>
      _isLoadingController.sink.add(isLoading);

  Future<User?> _signIn(Future<User?> signInMethod) async {
    try {
      _setIsLoading(true);
      return await signInMethod;
    } catch (e) {
      _setIsLoading(false);
      rethrow;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
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
    if (email.isNotEmpty && password.isNotEmpty) {
      return _signIn(auth.signInWithEmail(email, password));
    }
    return null;
  }
}
