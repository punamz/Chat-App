import 'dart:convert';
import 'dart:developer';

import 'package:chat_app/blocs/home/home_bloc.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/pages/chat/chat_page.dart';
import 'package:chat_app/pages/profile/profile_page.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/notification.dart';
import 'package:chat_app/utils/get_color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  HomePage._();

  static HomePage instance = HomePage._();

  factory HomePage() => instance;

  // HomePage({Key? key}) : super(key: key);

  late Function({required UserInfo userInfo}) goPage;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeBloc bloc;
  final currentUser = Auth().currentUser!;
  TextEditingController searchUser = TextEditingController();
  String _textSearch = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bloc = HomeBloc(database: context.read<Database>());
    widget.goPage = onPressUser;

    /// handle if initMsg not null
    /// => navigate to chat page
    if (initMsg != null) {
      SchedulerBinding.instance?.addPostFrameCallback((_) {
        final json = initMsg!.data;
        final userInfo =
            UserInfo.fromJson(jsonDecode(json['arguments'])['userInfo']);
        onPressUser(userInfo: userInfo);
      });
    }
  }

  void onPressUser({required UserInfo userInfo}) {
    final NotificationBase notification = context.read<NotificationBase>();
    // Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            Provider<Database>(create: (_) => bloc.database),
            Provider<NotificationBase>(create: (_) => notification),
          ],
          child: ChatPage(userInfo: userInfo),
        ),
      ),
    );
  }

  void onPressProfileButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Provider<Database>(
          create: (_) => bloc.database,
          child: const ProfilePage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildSearchUser() {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: Dimens.slightHorizontalMargin,
        ),
        height: 50.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimens.radius),
          color: getSuitableColor(AppColor.wildSand, AppColor.mineShaft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 10.w),
            Icon(
              Icons.search,
              color: AppColor.doveGray,
              size: 20.w,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: TextField(
                controller: searchUser,
                onChanged: (value) => setState(() {
                  _textSearch = value;
                }),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _textSearch = '';

                      searchUser.clear();
                    }),
                    icon: const Icon(Icons.clear),
                  ),
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontSize: 14.w,
                    color: AppColor.doveGray,
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }

    Widget _buildUserCard(BuildContext context, UserInfo user) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimens.radius),
          color: getSuitableColor(AppColor.wildSand, AppColor.mineShaft),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: 5.w,
          vertical: 5.h,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 5.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radius),
          ),
          tileColor: getSuitableColor(AppColor.wildSand, AppColor.mineShaft),
          onTap: () => onPressUser(userInfo: user),
          leading: Material(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            clipBehavior: Clip.hardEdge,
            child: user.photoURL.isNotEmpty
                ? Image.network(
                    user.photoURL,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      );
                    },
                    errorBuilder: (context, object, stackTrace) {
                      return Icon(
                        Icons.account_circle,
                        size: 50,
                        color: getSuitableColor(
                            AppColor.doveGray, AppColor.wildSand),
                      );
                    },
                  )
                : Icon(
                    Icons.account_circle,
                    size: 50,
                    color:
                        getSuitableColor(AppColor.doveGray, AppColor.wildSand),
                  ),
          ),
          title: CustomText(
            text: user.name,
            textSize: 16.w,
            fontWeight: FontWeight.w600,
            textColor: getSuitableColor(AppColor.black, AppColor.white),
          ),
        ),
      );
    }

    _buildSearchUserList() {
      return StreamBuilder<QuerySnapshot>(
        stream: bloc.findUserStream(_textSearch),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userList = snapshot.data?.docs;
            if (userList!.isNotEmpty) {
              // this help us fix bug " field does not exist within the DocumentSnapshotPlatform"
              // cause stream has latest data of chat stream
              try {
                log('${userList[0]['name']}');
              } catch (e) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  return _buildUserCard(
                      context, UserInfo.fromDocument(userList[index]));
                },
                itemCount: userList.length,
              );
            } else {
              return const Center(
                child: Text("No users"),
              );
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      );
    }

    _buildChatList() {
      return StreamBuilder<QuerySnapshot>(
        stream: bloc.getChatStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userIdList = snapshot.data?.docs;
            if (userIdList!.isNotEmpty) {
              // this help us fix bug " field does not exist within the DocumentSnapshotPlatform"
              // cause stream has latest data of chat stream
              try {
                log('${userIdList[0]['members']}');
              } catch (e) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final ids = userIdList[index].get('members');
                  final id =
                      ids.firstWhere((element) => element != currentUser.uid);
                  return FutureBuilder<UserInfo>(
                    future: bloc.getUserInfo(id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _buildUserCard(context, snapshot.data!);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  );
                },
                itemCount: userIdList.length,
              );
            } else {
              return const Center(
                child: Text("No users"),
              );
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      );
    }

    _buildBody() =>
        _textSearch.isEmpty ? _buildChatList() : _buildSearchUserList();

    return KeyboardDismisser(
      child: Scaffold(
        appBar: AppBar(
          title: CustomText(
            text: 'Chat App',
            textSize: 18.w,
            textColor: AppColor.white,
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: currentUser.photoURL == null
                  ? const Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: 30,
                    )
                  : Material(
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                      clipBehavior: Clip.hardEdge,
                      child: Image.network(
                        currentUser.photoURL!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          );
                        },
                        errorBuilder: (context, object, stackTrace) {
                          return Icon(
                            Icons.account_circle,
                            size: 30,
                            color: getSuitableColor(
                                AppColor.doveGray, AppColor.wildSand),
                          );
                        },
                      ),
                    ),
              onPressed: onPressProfileButton,
            )
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 10.h),
              _buildSearchUser(),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }
}
