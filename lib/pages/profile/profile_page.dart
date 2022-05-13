import 'dart:io';

import 'package:chat_app/blocs/profile/profile_bloc.dart';
import 'package:chat_app/components/custom_button.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/constants/strings.dart';
import 'package:chat_app/pages/profile/component/avatar.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = Auth().currentUser!;

  final TextEditingController _nameController = TextEditingController();
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> onPressChangeImage() async {
    var locationPermissionStatus = await Permission.storage.request();
    switch (locationPermissionStatus) {

      /// ok, had permission
      case PermissionStatus.granted:
        break;

      /// user denied
      case PermissionStatus.permanentlyDenied:
        bool? confirm = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Permission denied "),
            content: const Text(
                'Without this permission, the app is unable access to your gallery to select picture.Do you want to enable this permission'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              // The "Yes" button
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes')),
            ],
          ),
        );
        if (confirm!) {
          openAppSettings();
        }
        break;
      default:
        return;
    }

    /// Pick and handle file
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
    currentUser.updatePhotoURL(urlDownload);
    Fluttertoast.showToast(msg: 'Update your avatar');
    setState(() {
      task = null;
      avatar = urlDownload;
    });
  }

  void _logout() {
    bloc.logout();
    Navigator.pop(context);
  }

  void _changeName() {
    FocusManager.instance.primaryFocus?.unfocus();
    final newName = _nameController.text.trim();
    bloc.updateName(newName);
    Fluttertoast.showToast(msg: 'Your name have been changed');
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildCameraOverlay() => Icon(
          Icons.camera_alt_outlined,
          size: 40,
          color: AppColor.primary.withOpacity(0.4),
        );
    Widget _buildUploadStatus(UploadTask uploadTask) {
      return StreamBuilder<TaskSnapshot>(
        stream: uploadTask.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final snap = snapshot.data!;
            final progress = snap.bytesTransferred / snap.totalBytes;

            return progress != 1
                ? CircularProgressIndicator(value: progress)
                : _buildCameraOverlay();
          } else {
            return _buildCameraOverlay();
          }
        },
      );
    }

    Widget _buildAvatar() {
      return CupertinoButton(
        onPressed: isUploadNewAvatar ? null : onPressChangeImage,
        child: SizedBox(
          height: 100,
          width: 100,
          child: Center(
            child: Stack(
              children: <Widget>[
                Center(
                  child: Avatar(avatar: avatar),
                ),
                Center(
                  child: task != null
                      ? _buildUploadStatus(task!)
                      : _buildCameraOverlay(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildNameEditing() {
      return TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(5),
        ),
        onChanged: (value) => setState(() {}),
      );
    }

    Widget _buildChangeNameButton() {
      bool isTrue = currentUser.displayName != _nameController.text &&
          _nameController.text.trim().isNotEmpty;
      return SizedBox(
        width: 1.sw,
        height: 45.h,
        child: CustomButton(
          color: AppColor.primary,
          onPressed: isTrue ? _changeName : null,
          child: CustomText(
            text: 'Change Name',
            textSize: 15.sp,
            textColor: AppColor.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return KeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          iconTheme: const IconThemeData(
            color: AppColor.hotCinnamon,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Dimens.slightHorizontalMargin,
              vertical: Dimens.slightVerticalMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(),
                Row(
                  children: [
                    CustomText(
                      text: 'Name: ',
                      textSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      textColor:
                          getSuitableColor(AppColor.black, AppColor.white),
                    ),
                    Flexible(child: _buildNameEditing())
                  ],
                ),
                SizedBox(height: 20.h),
                _buildChangeNameButton(),
                SizedBox(height: 20.h),
                SizedBox(
                  width: 1.sw,
                  height: 45.h,
                  child: CustomButton(
                    color: Colors.red,
                    onPressed: _logout,
                    child: CustomText(
                      text: 'Logout',
                      textSize: 15.sp,
                      textColor: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 350.h),
                Center(
                  child: CustomText(
                    text: 'Version: ${Strings.versionName}',
                    textSize: 12.sp,
                    fontWeight: FontWeight.w300,
                    textColor:
                        getSuitableColor(AppColor.doveGray, AppColor.wildSand),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
