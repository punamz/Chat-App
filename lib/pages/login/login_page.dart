import 'package:chat_app/blocs/login/login_bloc.dart';
import 'package:chat_app/components/custom_button.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/constants/size_config.dart';
import 'package:chat_app/pages/sign_up/sign_up_page.dart';
import 'package:chat_app/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.auth}) : super(key: key);
  final AuthBase auth;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late LoginBloc bloc;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithEmail() async {
    try {
      await bloc.signInWithEmail(
          _emailController.text, _passwordController.text);
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: e.message.toString());
    }
  }

  void _signUp(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SignUpPage(auth: widget.auth),
        transitionsBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation, Widget child) =>
            SlideTransition(
                position: animation.drive(Tween(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.linear))),
                child: child),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bloc = LoginBloc(auth: widget.auth);
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildEmailTextField() {
      return StreamBuilder<String?>(
          stream: bloc.emailStream,
          builder: (context, snapshot) {
            return TextField(
              controller: _emailController,
              decoration: InputDecoration(
                icon: const Icon(Icons.email, color: Colors.white),
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white),
                hintText: 'sample@sample.com',
                hintStyle: const TextStyle(color: Colors.white38),
                errorText: snapshot.data,
              ),
              style: const TextStyle(color: Colors.white),
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            );
          });
    }

    Widget _buildPasswordTextField() {
      return StreamBuilder<String?>(
          stream: bloc.passwordStream,
          builder: (context, snapshot) {
            return TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                icon: const Icon(Icons.lock, color: Colors.white),
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white),
                errorText: snapshot.data,
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              textInputAction: TextInputAction.done,
              //onEditingComplete: _signInWithEmail,
            );
          });
    }

    Widget _buildLoginBtn() {
      return Container(
        padding:
            EdgeInsets.symmetric(vertical: getProportionateScreenWidth(25)),
        width: double.infinity,
        height: getProportionateScreenHeight(100),
        child: CustomButton(
          child: CustomText(
            text: 'LOGIN',
            textSize: getProportionateScreenWidth(18),
            textColor: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
          color: Colors.white,
          borderRadius: 30,
          onPressed: _signInWithEmail,
        ),
      );
    }

    Widget _buildSignUpBtn() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomText(
            text: "Don't have an account? ",
            textSize: 18,
            textColor: Colors.white,
          ),
          InkWell(
            child: const CustomText(
              text: " Sign Up",
              textSize: 18,
              fontWeight: FontWeight.bold,
              textColor: Colors.white,
            ),
            onTap: () => _signUp(context),
          ),
        ],
      );
    }

    return KeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: StreamBuilder<bool>(
          stream: bloc.isLoadingStream,
          initialData: false,
          builder: (context, snapshot) {
            return Stack(
              children: <Widget>[
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue[300]!,
                        Colors.blue[500]!,
                        Colors.blue[700]!,
                        Colors.blue[900]!,
                      ],
                      stops: const [0.1, 0.3, 0.6, 0.9],
                    ),
                  ),
                ),
                SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(
                          Dimens.bigHorizontalMargin),
                      vertical: getProportionateScreenHeight(120),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CustomText(
                          text: 'Sign in',
                          textColor: Colors.white,
                          textSize: getProportionateScreenWidth(30),
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: getProportionateScreenHeight(50)),
                        _buildEmailTextField(),
                        SizedBox(height: getProportionateScreenHeight(30)),
                        _buildPasswordTextField(),
                        _buildLoginBtn(),
                        SizedBox(height: getProportionateScreenHeight(25)),
                        _buildSignUpBtn(),
                      ],
                    ),
                  ),
                ),
                if (snapshot.data == true)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
