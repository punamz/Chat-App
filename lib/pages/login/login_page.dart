import 'package:chat_app/blocs/login/login_bloc.dart';
import 'package:chat_app/components/custom_button.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/pages/sign_up/sign_up_page.dart';
import 'package:chat_app/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.auth}) : super(key: key);
  final AuthBase auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late LoginBloc bloc;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithEmail() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await bloc.signInWithEmail(
          _emailController.text, _passwordController.text);
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: e.message.toString());
    }
  }

  void _signUp() {
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
  void dispose() {
    // TODO: implement dispose
    bloc.dispose();
    super.dispose();
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
              icon: const Icon(Icons.email, color: AppColor.white),
              labelText: 'Email',
              labelStyle: const TextStyle(color: AppColor.white),
              hintText: 'example@example.com',
              hintStyle: TextStyle(color: AppColor.white.withOpacity(0.5)),
              errorText: snapshot.data,
            ),
            cursorColor: AppColor.white,
            style: const TextStyle(color: AppColor.white),
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          );
        },
      );
    }

    Widget _buildPasswordTextField() {
      return StreamBuilder<String?>(
        stream: bloc.passwordStream,
        builder: (context, snapshot) {
          return TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              icon: const Icon(Icons.lock, color: AppColor.white),
              labelText: 'Password',
              labelStyle: const TextStyle(color: AppColor.white),
              errorText: snapshot.data,
            ),
            style: const TextStyle(color: AppColor.white),
            cursorColor: AppColor.white,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onEditingComplete: _signInWithEmail,
          );
        },
      );
    }

    Widget _buildLoginBtn() {
      return SizedBox(
        width: 1.sw,
        height: 45.h,
        child: CustomButton(
          color: AppColor.white,
          borderRadius: 25.r,
          onPressed: _signInWithEmail,
          child: CustomText(
            text: 'LOGIN',
            textSize: 18.sp,
            textColor: AppColor.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Widget _buildSignUpBtn() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            text: "Don't have an account? ",
            textSize: 16.sp,
            textColor: AppColor.white,
          ),
          GestureDetector(
            onTap: _signUp,
            child: CustomText(
              text: " Sign Up",
              textSize: 16.sp,
              fontWeight: FontWeight.bold,
              textColor: AppColor.white,
            ),
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
                  height: 1.sh,
                  width: 1.sw,
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
                      stops: const [0.1, 0.2, 0.5, 0.9],
                    ),
                  ),
                ),
                SizedBox(
                  height: 1.sh,
                  width: 1.sw,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimens.bigHorizontalMargin,
                      vertical: 120.h,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CustomText(
                          text: 'Sign in',
                          textColor: AppColor.white,
                          textSize: 30.w,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 50.h),
                        _buildEmailTextField(),
                        SizedBox(height: 25.h),
                        _buildPasswordTextField(),
                        SizedBox(height: 25.h),
                        _buildLoginBtn(),
                        SizedBox(height: 50.h),
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
