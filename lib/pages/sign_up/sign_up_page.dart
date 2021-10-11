import 'package:chat_app/blocs/sign_up/sign_up_bloc.dart';
import 'package:chat_app/components/custom_button.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/constants/size_config.dart';
import 'package:chat_app/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key, required this.auth}) : super(key: key);
  final AuthBase auth;

  @override
  _SignUpPageState createState() => _SignUpPageState();
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
      if (isComplete) Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      print(e);
      Fluttertoast.showToast(msg: e.message.toString());
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    bloc.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
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
              icon: Icon(Icons.assignment_ind, color: Colors.white),
              labelText: 'FullName',
              labelStyle: TextStyle(color: Colors.white),
              errorText: snapshot.data,
            ),
            style: TextStyle(color: Colors.white),
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
              icon: Icon(Icons.email, color: Colors.white),
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.white),
              hintText: 'sample@sample.com',
              hintStyle: TextStyle(color: Colors.white38),
              errorText: snapshot.data,
            ),
            style: TextStyle(color: Colors.white),
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
              icon: Icon(Icons.lock, color: Colors.white),
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.white),
              errorText: snapshot.data,
            ),
            style: TextStyle(color: Colors.white),
            obscureText: true,
            textInputAction: TextInputAction.done,
            //onEditingComplete: _signInWithEmail,
          );
        },
      );
    }

    Widget _buildSignUpBtn() {
      return Container(
        padding:
            EdgeInsets.symmetric(vertical: getProportionateScreenWidth(25)),
        width: double.infinity,
        height: getProportionateScreenHeight(100),
        child: CustomButton(
          child: CustomText(
            text: 'SIGN UP',
            textSize: getProportionateScreenWidth(18),
            textColor: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
          color: Colors.white,
          borderRadius: 30,
          onPressed: _createUserWithEmailAndPassword,
        ),
      );
    }

    Widget _buildLoginBtn() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            text: "Have an account? ",
            textSize: 18,
            textColor: Colors.white,
          ),
          InkWell(
            child: CustomText(
              text: " Login",
              textSize: 18,
              fontWeight: FontWeight.bold,
              textColor: Colors.white,
            ),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return KeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: CustomText(
            text: 'Sign up',
            textColor: Colors.white,
            textSize: getProportionateScreenWidth(20),
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
                      stops: [0.1, 0.3, 0.6, 0.9],
                    ),
                  ),
                ),
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(
                          Dimens.big_horizontal_margin),
                      vertical: getProportionateScreenHeight(120),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _buildFullNameTextField(),
                        SizedBox(height: getProportionateScreenHeight(30)),
                        _buildEmailTextField(),
                        SizedBox(height: getProportionateScreenHeight(30)),
                        _buildPasswordTextField(),
                        _buildSignUpBtn(),
                        SizedBox(height: getProportionateScreenHeight(25)),
                        _buildLoginBtn(),
                      ],
                    ),
                  ),
                ),
                if (snapshot.data == true)
                  Center(
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
