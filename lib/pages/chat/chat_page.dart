import 'dart:io';

import 'package:chat_app/blocs/chat/chat_bloc.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/components/video_player.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/notification.dart';
import 'package:chat_app/utils/get_chat_id.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:chat_app/utils/kind_of_file.dart';
import 'package:chat_app/utils/time_format.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.userInfo}) : super(key: key);

  final UserInfo userInfo;

  @override
  _ChatPageState createState() => _ChatPageState();
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
    final fileSelection = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.media);
    if (fileSelection == null) return;
    final path = fileSelection.files.single.path!;
    int type = checkTypeOfFile(path);
    final file = File(path);
    task = bloc.uploadFile(file);
    setState(() {});
    final snapshot = await task!;
    final urlDownload = await snapshot.ref.getDownloadURL();

    _sendMessage(type: type, fileName: urlDownload);
  }

  Future<void> _onPressSendFile() async {
    final fileSelection =
        await FilePicker.platform.pickFiles(allowMultiple: false);
    if (fileSelection == null) return;
    final path = fileSelection.files.single.path!;
    final file = File(path);
    int type = checkTypeOfFile(path);
    task = bloc.uploadFile(file);
    setState(() {});
    final snapshot = await task!;
    final urlDownload = await snapshot.ref.getDownloadURL();

    type == fileType
        ? _sendMessage(
            type: type, fileName: path.split('/').last, url: urlDownload)
        : _sendMessage(type: type, fileName: urlDownload);
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

  void _onPressLikeMessage(Message message) {
    bloc.likeMessage(message);
  }

  Future<void> _downloadFile(String fileName, String url) async {
    Fluttertoast.showToast(msg: 'Start download file $fileName');
    final filepath = await bloc.downloadFile(fileName, url);
    Fluttertoast.showToast(msg: 'Downloaded!\n$filepath');
  }

  _scrollListener() {
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
    // TODO: implement dispose
    super.dispose();
    bloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildContentOfMessage(Message message) {
      bool isMe = message.sendBy == currentUser!.uid;
      switch (message.type) {
        case messageType:
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: CustomText(
                      text: message.message,
                      textColor: isMe
                          ? AppColor.white
                          : getSuitableColor(AppColor.black, AppColor.white),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomText(
                    text: dayFormat(message.timestamp),
                    textSize: 10.w,
                    fontWeight: FontWeight.w200,
                    textColor: isMe
                        ? AppColor.black
                        : getSuitableColor(AppColor.black, AppColor.white),
                  )
                ],
              )
            ],
          );
        case imageType:
          return Column(
            children: [
              Image.network(
                message.message,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomText(
                    text: dayFormat(message.timestamp),
                    textSize: 10.w,
                    fontWeight: FontWeight.w200,
                    textColor: getSuitableColor(AppColor.black, AppColor.white),
                  )
                ],
              )
            ],
          );
        case videoType:
          {
            return Column(
              children: [
                VideoPlayer(videoUrl: message.message),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomText(
                      text: dayFormat(message.timestamp),
                      textSize: 10.w,
                      fontWeight: FontWeight.w200,
                      textColor:
                          getSuitableColor(AppColor.black, AppColor.white),
                    )
                  ],
                )
              ],
            );
          }
        case fileType:
          return GestureDetector(
            onTap: () => _downloadFile(message.message, message.url!),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.download_rounded,
                      color: isMe
                          ? AppColor.white
                          : getSuitableColor(AppColor.black, AppColor.white),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: CustomText(
                        text: message.message,
                        textColor: AppColor.white,
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomText(
                      text: dayFormat(message.timestamp),
                      textSize: 10.w,
                      fontWeight: FontWeight.w200,
                    )
                  ],
                )
              ],
            ),
          );
        default:
          return const SizedBox.shrink();
      }
    }

    _buildMessageItem(Message message) {
      bool isMe = message.sendBy == currentUser!.uid;

      final msg = Container(
          margin: EdgeInsets.only(
            left: isMe ? 50.w : 0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 15.w,
            vertical: message.type == 1 || message.type == 4 ? 10.h : 0,
          ),
          decoration: BoxDecoration(
            color: message.type == messageType || message.type == fileType
                ? isMe
                    ? AppColor.primary
                    : AppColor.doveGray.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(Dimens.radius),
                    bottomLeft: Radius.circular(Dimens.radius),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(Dimens.radius),
                    bottomRight: Radius.circular(Dimens.radius),
                  ),
          ),
          child: _buildContentOfMessage(message));

      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: msg),
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

    _buildMessageList() {
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

    _buildInput() {
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

    _buildSendFileStatus(UploadTask task) => StreamBuilder<TaskSnapshot>(
          stream: task.snapshotEvents,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final snap = snapshot.data!;
              final progress = snap.bytesTransferred / snap.totalBytes;
              final percentage = (progress * 100).toStringAsFixed(2);
              return percentage.compareTo('100.00') != 0
                  ? CustomText(
                      text: 'Sending file... $percentage %',
                      textColor:
                          getSuitableColor(AppColor.black, AppColor.white),
                    )
                  : const SizedBox.shrink();
            } else {
              return const SizedBox.shrink();
            }
          },
        );

    _buildDownloadStatus() => StreamBuilder<double>(
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
            textSize: 17.w,
          ),
        ),
        body: Column(
          children: [
            _buildMessageList(),
            task != null
                ? _buildSendFileStatus(task!)
                : const SizedBox.shrink(),
            _buildDownloadStatus(),
            _buildInput(),
          ],
        ),
      ),
    );
  }
}
