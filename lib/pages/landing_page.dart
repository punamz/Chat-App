import 'package:chat_app/constants/size_config.dart';
import 'package:chat_app/pages/home/home_page.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login/login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final auth = Provider.of<AuthBase>(context, listen: false);
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        final User? user = snapshot.data;
        if (user == null) {
          return LoginPage(auth: auth);
        } else {
          return Provider<Database>(
            create: (_) => FireStoreDatabase(uid: user.uid),
            child: HomePage(),
          );
        }
      },
    );
  }
}
