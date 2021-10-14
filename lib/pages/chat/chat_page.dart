import 'dart:io';

import 'package:chat_app/blocs/chat/chat_bloc.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/components/video_player.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/constants/size_config.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/utils/get_chat_id.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:chat_app/utils/kind_of_file.dart';
import 'package:chat_app/utils/time_format.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.user}) : super(key: key);

  final UserInfor user;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController textInputController = new TextEditingController();
  final ScrollController messageListScrollController = new ScrollController();
  final currentUser = Auth().currentUser;
  int _limit = 20;
  final _limitIncrement = 20;
  late Database database;
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
    if (type == messageType)
      content = textInputController.text.trim();
    else
      content = fileName!;

    if (content.isNotEmpty) {
      textInputController.clear();
      bloc.sendMessage(
        content: content,
        chatId: chatId,
        senderId: currentUser!.uid,
        type: type,
        url: url,
      );
      messageListScrollController.animateTo(0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
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
    database = context.read<Database>();
    bloc = new ChatBloc(database: database);
    messageListScrollController.addListener(_scrollListener);
    chatId = getChatId(currentUser!.uid, widget.user.id);
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
                    textSize: getProportionateScreenWidth(10),
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
                    textSize: getProportionateScreenWidth(10),
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
                      textSize: getProportionateScreenWidth(10),
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
                    SizedBox(width: getProportionateScreenWidth(10)),
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
                      textSize: getProportionateScreenWidth(10),
                      fontWeight: FontWeight.w200,
                    )
                  ],
                )
              ],
            ),
          );
        default:
          return Container();
      }
    }

    _buildMessageItem(Message message) {
      bool isMe = message.sendBy == currentUser!.uid;

      final msg = Container(
          margin: EdgeInsets.only(
            left: isMe ? getProportionateScreenWidth(50) : 0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(15),
            vertical: message.type == 1 || message.type == 4
                ? getProportionateScreenHeight(10)
                : 0,
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
            padding: EdgeInsets.only(bottom: getProportionateScreenHeight(10)),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: msg),
                if (!isMe)
                  IconButton(
                    onPressed: () => _onPressLikeMessage(message),
                    icon: message.like
                        ? Icon(Icons.favorite)
                        : Icon(Icons.favorite_border),
                    color: message.like ? AppColor.primary : AppColor.doveGray,
                  ),
              ],
            ),
          ),
          if (isMe && message.like)
            Positioned(
              bottom: 0,
              left: getProportionateScreenWidth(45),
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(Dimens.radius),
                  ),
                ),
                child: Icon(
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
              if ((messageList!.length) > 0) {
                return ListView.builder(
                  itemBuilder: (context, index) {
                    final message = Message.fromDocument(messageList[index]);
                    return _buildMessageItem(message);
                  },
                  itemCount: messageList.length,
                  reverse: true,
                  controller: messageListScrollController,
                );
              } else
                return Container();
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      );
    }

    _buildInput() {
      return Container(
        height: getProportionateScreenHeight(50),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColor.doveGray, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _onPressSendImage,
              icon: Icon(Icons.photo),
              iconSize: getProportionateScreenWidth(25),
              color: AppColor.primary,
            ),
            IconButton(
              onPressed: _onPressSendFile,
              icon: Icon(Icons.attach_file),
              iconSize: getProportionateScreenWidth(25),
              color: AppColor.primary,
            ),
            Expanded(
              child: Container(
                child: TextField(
                  controller: textInputController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Send a message...',
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              iconSize: getProportionateScreenWidth(25),
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
                  : Container();
            } else {
              return Container();
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
                  : Container();
            } else
              return Container();
          },
        );

    return KeyboardDismisser(
      child: Scaffold(
        appBar: AppBar(
          title: CustomText(
            text: widget.user.name,
            textColor: AppColor.white,
            textSize: getProportionateScreenWidth(17),
          ),
        ),
        body: Column(
          children: [
            _buildMessageList(),
            task != null ? _buildSendFileStatus(task!) : Container(),
            _buildDownloadStatus(),
            _buildInput(),
          ],
        ),
      ),
    );
  }
}
