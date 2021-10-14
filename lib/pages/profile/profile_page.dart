import 'dart:io';

import 'package:chat_app/blocs/profile/profile_bloc.dart';
import 'package:chat_app/components/custom_button.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/constants/size_config.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/src/provider.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = Auth().currentUser!;

  final TextEditingController _nameController = new TextEditingController();
  late ProfileBloc bloc;
  late Database database;
  String avatar = '';

  UploadTask? task;
  bool isUploadNewAvatar = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _nameController.text = currentUser.displayName ?? "";
    database = context.read<Database>();
    bloc = ProfileBloc(database: database);
    avatar = currentUser.photoURL ?? '';
  }

  Future<void> onPressChangeImage() async {
    final fileSelection = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.image);
    if (fileSelection == null) return;
    final path = fileSelection.files.single.path!;
    final file = File(path);
    setState(() {
      task = bloc.uploadFile(file);
    });

    final snapshot = await task!;
    final urlDownload = await snapshot.ref.getDownloadURL();
    bloc.updateAvatar(urlDownload);

    Fluttertoast.showToast(msg: 'Update your avatar');
    setState(() {
      task = null;
      avatar = urlDownload;
    });
  }

  void _logout() {
    Auth().signOut();
    Navigator.pop(context);
  }

  void _changeName() {
    final newName = _nameController.text.trim();
    bloc.updateName(newName);
    Fluttertoast.showToast(msg: 'Your name have been changed');
  }

  @override
  Widget build(BuildContext context) {
    _buildUploadStatus(UploadTask uploadTask) {
      return StreamBuilder<TaskSnapshot>(
        stream: uploadTask.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final snap = snapshot.data!;
            final progress = snap.bytesTransferred / snap.totalBytes;

            return progress != 1
                ? CircularProgressIndicator(
                    value: progress,
                  )
                : Icon(
                    Icons.camera_alt_outlined,
                    size: 40,
                    color: AppColor.primary.withOpacity(0.3),
                  );
          } else {
            return Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: AppColor.primary.withOpacity(0.3),
            );
          }
        },
      );
    }

    _buildAvatar() {
      return CupertinoButton(
        onPressed: isUploadNewAvatar ? null : onPressChangeImage,
        child: Container(
          height: 100,
          width: 100,
          child: Center(
            child: Stack(
              children: <Widget>[
                Center(
                  child: Material(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    clipBehavior: Clip.hardEdge,
                    child: avatar.isNotEmpty
                        ? Image.network(
                            avatar,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              );
                            },
                          )
                        : Container(),
                  ),
                ),
                Center(
                  child: task != null
                      ? _buildUploadStatus(task!)
                      : Icon(
                          Icons.camera_alt_outlined,
                          size: 40,
                          color: AppColor.primary.withOpacity(0.3),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _buildNameEditing() {
      return TextField(
        controller: _nameController,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(5),
        ),
        onChanged: (value) => setState(() {}),
      );
    }

    _buildChangeNameButton() {
      bool isTrue = currentUser.displayName != _nameController.text &&
          _nameController.text.trim().isNotEmpty;
      return Container(
        width: double.infinity,
        height: getProportionateScreenHeight(45),
        child: CustomButton(
          color: AppColor.primary,
          onPressed: isTrue ? _changeName : null,
          child: CustomText(
            text: 'Change Name',
            textSize: getProportionateScreenWidth(15),
            textColor: AppColor.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return KeyboardDismisser(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          iconTheme: IconThemeData(
            color: AppColor.hotCinnamon,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  getProportionateScreenWidth(Dimens.slight_horizontal_margin),
              vertical:
                  getProportionateScreenHeight(Dimens.slight_vertical_margin),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(),
                Row(
                  children: [
                    CustomText(
                      text: 'Name: ',
                      textSize: getProportionateScreenWidth(15),
                      fontWeight: FontWeight.w500,
                      textColor:
                          getSuitableColor(AppColor.black, AppColor.white),
                    ),
                    Flexible(child: _buildNameEditing())
                  ],
                ),
                SizedBox(height: getProportionateScreenHeight(20)),
                _buildChangeNameButton(),
                SizedBox(height: getProportionateScreenHeight(20)),
                Container(
                  width: double.infinity,
                  height: getProportionateScreenHeight(45),
                  child: CustomButton(
                    color: Colors.red,
                    onPressed: _logout,
                    child: CustomText(
                      text: 'Logout',
                      textSize: getProportionateScreenWidth(15),
                      textColor: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
