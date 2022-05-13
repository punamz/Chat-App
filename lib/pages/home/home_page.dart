import 'dart:async';
import 'dart:convert';

import 'package:chat_app/blocs/home/home_bloc.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/pages/chat/chat_page.dart';
import 'package:chat_app/pages/home/component/avatar.dart';
import 'package:chat_app/pages/home/component/search_text_field.dart';
import 'package:chat_app/pages/home/component/user_card.dart';
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeBloc bloc;
  final currentUser = Auth().currentUser!;
  final TextEditingController _searchUser = TextEditingController();
  String _textSearch = '';
  Timer? _debounce;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bloc = HomeBloc(database: context.read<Database>());
    widget.goPage = onPressUser;

    /// handle if initMsg not null
    /// => navigate to chat page
    if (initMsg != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final json = initMsg!.data;
        final userInfo =
            UserInfo.fromJson(jsonDecode(json['arguments'])['userInfo']);
        onPressUser(userInfo: userInfo);
      });
    }
  }

  @override
  void dispose() {
    _searchUser.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void onPressUser({required UserInfo userInfo}) {
    final NotificationBase notification = context.read<NotificationBase>();
    Navigator.of(context).popUntil((route) => route.isFirst);
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

  void onChangeSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => setState(() => _textSearch = value),
    );
  }

  void onPressClearButton() {
    setState(() {
      _textSearch = '';
      _searchUser.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildSearchUserList() {
      return StreamBuilder<List<UserInfo>>(
        stream: bloc.findUserStream(_textSearch),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userList = snapshot.data;
            if (userList!.isNotEmpty) {
              return ListView.builder(
                itemCount: userList.length,
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  return UserCard(
                    user: userList[index],
                    onTap: () => onPressUser(userInfo: userList[index]),
                  );
                },
              );
            } else {
              return const Center(child: CustomText(text: 'No users'));
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }

    Widget _buildChatList() {
      return StreamBuilder<QuerySnapshot>(
        stream: bloc.getChatStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userIdList = snapshot.data?.docs;
            if (userIdList!.isNotEmpty) {
              return ListView.builder(
                itemCount: userIdList.length,
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  /// all id in chat group
                  final ids = userIdList[index].get('members');

                  /// id of target in chat group
                  /// if  you in group only, return first id in list
                  final id = ids.firstWhere(
                    (element) => element != currentUser.uid,
                    orElse: () => ids[0],
                  );
                  return FutureBuilder<UserInfo>(
                    future: bloc.getUserInfo(id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return UserCard(
                          user: snapshot.data!,
                          onTap: () => onPressUser(userInfo: snapshot.data!),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  );
                },
              );
            } else {
              return const Center(child: CustomText(text: "No users"));
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }

    return KeyboardDismisser(
      child: Scaffold(
        appBar: AppBar(
          title: CustomText(
            text: 'Chat App',
            textSize: 18.sp,
            textColor: AppColor.white,
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: currentUser.photoURL == null
                  ? Icon(
                      Icons.account_circle,
                      color: getSuitableColor(
                          AppColor.doveGray, AppColor.wildSand),
                      size: 30,
                    )
                  : Avatar(photoURL: currentUser.photoURL),
              onPressed: onPressProfileButton,
            )
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 10.h),
              SearchTextField(
                controller: _searchUser,
                onChange: onChangeSearch,
                onClear: onPressClearButton,
              ),
              _textSearch.isEmpty ? _buildChatList() : _buildSearchUserList(),
            ],
          ),
        ),
      ),
    );
  }
}
