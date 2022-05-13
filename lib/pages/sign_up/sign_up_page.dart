import 'package:chat_app/blocs/sign_up/sign_up_bloc.dart';
import 'package:chat_app/components/custom_button.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key, required this.auth}) : super(key: key);
  final AuthBase auth;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late SignUpBloc bloc;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _createUserWithEmailAndPassword() async {
    try {
      final isComplete = await bloc.createUserWithEmailAndPassword(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
      if (isComplete && mounted) Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: e.message.toString());
    }
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    bloc = SignUpBloc(auth: widget.auth);
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildFullNameTextField() {
      return StreamBuilder<String?>(
        stream: bloc.fullNameStream,
        builder: (context, snapshot) {
          return TextField(
            controller: _nameController,
            decoration: InputDecoration(
              icon: const Icon(Icons.assignment_ind, color: AppColor.white),
              labelText: 'FullName',
              labelStyle: const TextStyle(color: AppColor.white),
              errorText: snapshot.data,
            ),
            cursorColor: AppColor.white,
            style: const TextStyle(color: AppColor.white),
            autocorrect: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
          );
        },
      );
    }

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
            cursorColor: AppColor.white,
            style: const TextStyle(color: AppColor.white),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onEditingComplete: _createUserWithEmailAndPassword,
          );
        },
      );
    }

    Widget _buildSignUpBtn() {
      return SizedBox(
        width: 1.sw,
        height: 45.h,
        child: CustomButton(
          color: Colors.white,
          borderRadius: 30.r,
          onPressed: _createUserWithEmailAndPassword,
          child: CustomText(
            text: 'SIGN UP',
            textSize: 18.sp,
            textColor: AppColor.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Widget _buildLoginBtn() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            text: "Have an account? ",
            textSize: 16.sp,
            textColor: AppColor.white,
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: CustomText(
              text: " Login",
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
        appBar: AppBar(
          backgroundColor: AppColor.primary,
          centerTitle: true,
          title: CustomText(
            text: 'Sign up',
            textColor: Colors.white,
            textSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                        Colors.blue[400]!,
                        Colors.blue[500]!,
                        Colors.blue[700]!,
                        Colors.blue[900]!,
                      ],
                      stops: const [0.1, 0.3, 0.6, 0.9],
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
                        _buildFullNameTextField(),
                        SizedBox(height: 30.h),
                        _buildEmailTextField(),
                        SizedBox(height: 30.h),
                        _buildPasswordTextField(),
                        SizedBox(height: 25.h),
                        _buildSignUpBtn(),
                        SizedBox(height: 25.h),
                        _buildLoginBtn(),
                      ],
                    ),
                  ),
                ),
                if (snapshot.data == true)
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }
}
