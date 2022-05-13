import 'dart:io';

import 'package:chat_app/blocs/chat/chat_bloc.dart';
import 'package:chat_app/components/custom_dialog.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/pages/chat/component/chat_bubble.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/notification.dart';
import 'package:chat_app/utils/get_chat_id.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:chat_app/utils/kind_of_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.userInfo}) : super(key: key);

  final UserInfo userInfo;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController textInputController = TextEditingController();
  final ScrollController messageListScrollController = ScrollController();
  final currentUser = Auth().currentUser;
  int _limit = 20;
  final _limitIncrement = 20;
  late ChatBloc bloc;
  late String chatId;
  UploadTask? task;

  Future<void> _onPressSendImage() async {
    var locationPermissionStatus = await Permission.storage.request();
    switch (locationPermissionStatus) {

      /// ok, had permission
      case PermissionStatus.granted:

        /// handle pick and send file
        final fileSelection = await FilePicker.platform
            .pickFiles(allowMultiple: false, type: FileType.media);
        if (fileSelection == null) return;
        final path = fileSelection.files.single.path!;
        int type = checkTypeOfFile(path);
        final file = File(path);
        task = bloc.uploadFile(file, chatId);
        setState(() {});
        final snapshot = await task!;
        final urlDownload = await snapshot.ref.getDownloadURL();

        _sendMessage(type: type, fileName: urlDownload);

        break;

      /// user denied
      case PermissionStatus.permanentlyDenied:
        bool? confirm = await customDialog(
          context: context,
          title: 'Permission denied',
          content:
              'Without this permission, the app is unable access to your gallery to select media. Do you want to enable this permission',
          defaultActionText: 'Yes',
          cancerActionText: 'Cancel',
        );
        if (confirm!) {
          openAppSettings();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _onPressSendFile() async {
    var permissionStatus = await Permission.storage.request();
    switch (permissionStatus) {

      /// ok, had permission
      case PermissionStatus.granted:

        /// pick and handle
        final fileSelection =
            await FilePicker.platform.pickFiles(allowMultiple: false);
        if (fileSelection == null) return;
        final path = fileSelection.files.single.path!;
        final file = File(path);
        int type = checkTypeOfFile(path);
        task = bloc.uploadFile(file, chatId);
        setState(() {});
        final snapshot = await task!;
        final urlDownload = await snapshot.ref.getDownloadURL();

        type == fileType
            ? _sendMessage(
                type: type, fileName: path.split('/').last, url: urlDownload)
            : _sendMessage(type: type, fileName: urlDownload);
        break;

      /// user denied
      case PermissionStatus.permanentlyDenied:
        bool? confirm = await customDialog(
          context: context,
          title: 'Permission denied',
          content:
              'Without this permission, the app is unable access to your storage to get file. Do you want to enable this permission',
          defaultActionText: 'Yes',
          cancerActionText: 'Cancel',
        );
        if (confirm!) {
          openAppSettings();
        }
        break;
      default:
        break;
    }
  }

  void _sendMessage({required int type, String? fileName, String? url}) {
    String content = '';
    if (type == messageType) {
      content = textInputController.text.trim();
    } else {
      content = fileName!;
    }

    if (content.isNotEmpty) {
      textInputController.clear();
      bloc.sendMessage(
        content: content,
        chatId: chatId,
        senderId: currentUser!.uid,
        type: type,
        url: url,
      );

      bloc.sendNotices(
        sender: currentUser!,
        receiver: widget.userInfo,
        message: content,
        type: type,
      );
      messageListScrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _onPressLikeMessage(Message message) => bloc.likeMessage(message);

  Future<void> _downloadFile(String fileName, String url) async {
    var locationPermissionStatus = await Permission.storage.request();
    switch (locationPermissionStatus) {

      /// ok, had permission
      case PermissionStatus.granted:
        Fluttertoast.showToast(msg: 'Start download file $fileName');
        final filepath = await bloc.downloadFile(fileName, url);
        Fluttertoast.showToast(msg: 'Downloaded!\n$filepath');
        break;

      /// user denied
      case PermissionStatus.permanentlyDenied:
        bool? confirm = await customDialog(
          context: context,
          title: 'Permission denied',
          content:
              'Without this permission, the app is unable access to your storage to download this file. Do you want to enable this permission',
          defaultActionText: 'Yes',
          cancerActionText: 'Cancel',
        );
        if (confirm!) {
          openAppSettings();
        }
        break;
      default:
        break;
    }
  }

  void _scrollListener() {
    if (messageListScrollController.offset >=
            messageListScrollController.position.maxScrollExtent &&
        !messageListScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bloc = ChatBloc(
      database: context.read<Database>(),
      notification: context.read<NotificationBase>(),
    );
    messageListScrollController.addListener(_scrollListener);
    chatId = getChatId(currentUser!.uid, widget.userInfo.id);
  }

  @override
  void dispose() {
    bloc.dispose();
    textInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildMessageItem(Message message) {
      bool isMe = message.sendBy == currentUser!.uid;

      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: ChatBubble(
                    message: message,
                    isMe: isMe,
                    downloadFile: () =>
                        _downloadFile(message.message, message.url!),
                  ),
                ),
                if (!isMe)
                  IconButton(
                    onPressed: () => _onPressLikeMessage(message),
                    icon: message.like
                        ? const Icon(Icons.favorite)
                        : const Icon(Icons.favorite_border),
                    color: message.like ? AppColor.primary : AppColor.doveGray,
                  ),
              ],
            ),
          ),
          if (isMe && message.like)
            Positioned(
              bottom: 0,
              left: 45.w,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(Dimens.radius),
                  ),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: AppColor.primary,
                ),
              ),
            ),
        ],
      );
    }

    Widget _buildMessageList() {
      return Flexible(
        child: StreamBuilder<QuerySnapshot>(
          stream: bloc.getMessageStream(chatId, _limit),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final messageList = snapshot.data?.docs;
              if (messageList!.isNotEmpty) {
                return ListView.builder(
                  itemBuilder: (context, index) {
                    final message = Message.fromDocument(messageList[index]);
                    return _buildMessageItem(message);
                  },
                  itemCount: messageList.length,
                  reverse: true,
                  controller: messageListScrollController,
                  addAutomaticKeepAlives: true,
                );
              } else {
                return Container();
              }
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      );
    }

    Widget _buildInput() {
      return Container(
        height: 50.h,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColor.doveGray, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _onPressSendImage,
              icon: const Icon(Icons.photo),
              iconSize: 25.w,
              color: AppColor.primary,
            ),
            IconButton(
              onPressed: _onPressSendFile,
              icon: const Icon(Icons.attach_file),
              iconSize: 25.w,
              color: AppColor.primary,
            ),
            Expanded(
              child: TextField(
                controller: textInputController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Send a message...',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              iconSize: 25.w,
              color: AppColor.primary,
              onPressed: () => _sendMessage(type: 1),
            ),
          ],
        ),
      );
    }

    Widget _buildSendFileStatus(UploadTask task) => StreamBuilder<TaskSnapshot>(
          stream: task.snapshotEvents,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final snap = snapshot.data!;
              final progress = snap.bytesTransferred / snap.totalBytes;
              final percentage = (progress * 100).toStringAsFixed(2);
              return percentage.compareTo('100.00') != 0
                  ? CustomText(
                      text:
                          'Sending file...${(snap.bytesTransferred / 1000000).toStringAsFixed(2)}/${(snap.totalBytes / 1000000).toStringAsFixed(2)}MB ($percentage%)',
                      textColor:
                          getSuitableColor(AppColor.black, AppColor.white),
                    )
                  : const SizedBox.shrink();
            } else {
              return const SizedBox.shrink();
            }
          },
        );

    Widget _buildDownloadStatus() => StreamBuilder<double>(
          stream: bloc.downloadStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              double status = snapshot.data!;
              return status != 100
                  ? CustomText(
                      text:
                          'Downloading file... ${status.toStringAsFixed(2)} %',
                      textColor:
                          getSuitableColor(AppColor.black, AppColor.white),
                    )
                  : const SizedBox.shrink();
            } else {
              return const SizedBox.shrink();
            }
          },
        );

    return KeyboardDismisser(
      child: Scaffold(
        appBar: AppBar(
          title: CustomText(
            text: widget.userInfo.name,
            textColor: AppColor.white,
            textSize: 18.sp,
          ),
        ),
        body: Column(
          children: [
            _buildMessageList(),
            if (task != null) _buildSendFileStatus(task!),
            _buildDownloadStatus(),
            _buildInput(),
          ],
        ),
      ),
    );
  }
}
