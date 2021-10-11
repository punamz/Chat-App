import 'package:chat_app/blocs/home/home_bloc.dart';
import 'package:chat_app/components/custom_text.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/constants/dimens.dart';
import 'package:chat_app/constants/size_config.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/pages/chat/chat_page.dart';
import 'package:chat_app/pages/profile/profile_page.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
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
    bloc = new HomeBloc(database: context.read<Database>());
  }

  Future<void> onPressUser(UserInfor user) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            Provider<Database>(
              create: (_) => FireStoreDatabase(uid: currentUser.uid),
            )
          ],
          child: ChatPage(user: user),
        ),
      ),
    );
  }

  void onPressProfileButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Provider<Database>(
                create: (_) => FireStoreDatabase(uid: currentUser.uid),
                child: ProfilePage(),
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildSearchUser() {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal:
              getProportionateScreenWidth(Dimens.slight_horizontal_margin),
        ),
        height: getProportionateScreenHeight(50),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimens.radius),
          color: AppColor.wildSand,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: getProportionateScreenWidth(10)),
            Icon(
              Icons.search,
              color: AppColor.doveGray,
              size: getProportionateScreenWidth(20),
            ),
            SizedBox(width: getProportionateScreenWidth(10)),
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
                    icon: Icon(Icons.clear),
                  ),
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontSize: getProportionateScreenWidth(14),
                    color: AppColor.doveGray,
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }

    Widget _buildUserCard(BuildContext context, UserInfor user) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radius),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(5),
          vertical: getProportionateScreenHeight(5),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(16),
            vertical: getProportionateScreenHeight(5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radius),
          ),
          tileColor: AppColor.wildSand,
          onTap: () => onPressUser(user),
          leading: Material(
            borderRadius: BorderRadius.all(Radius.circular(25)),
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
                        color: AppColor.doveGray,
                      );
                    },
                  )
                : Icon(
                    Icons.account_circle,
                    size: 50,
                    color: AppColor.doveGray,
                  ),
          ),
          title: CustomText(
            text: user.name,
            textSize: getProportionateScreenWidth(16),
            fontWeight: FontWeight.w600,
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
            if ((userList!.length) > 0) {
              // this help us fix bug " field does not exist within the DocumentSnapshotPlatform"
              // cause stream has latest data of chat stream
              try {
                print('${userList[0]['name']}');
              } catch (e) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.all(10),
                itemBuilder: (context, index) => _buildUserCard(
                    context, UserInfor.fromDocument(userList[index])),
                itemCount: userList.length,
              );
            } else {
              return Center(
                child: Text("No users"),
              );
            }
          } else {
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      );
    }

    _buildChatList() {
      return StreamBuilder<QuerySnapshot>(
        stream: bloc.getChatStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userIdList = snapshot.data?.docs;
            if ((userIdList!.length) > 0) {
              // this help us fix bug " field does not exist within the DocumentSnapshotPlatform"
              // cause stream has latest data of chat stream
              try {
                print('${userIdList[0]['members']}');
              } catch (e) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final ids = userIdList[index].get('members');
                  final id =
                      ids.firstWhere((element) => element != currentUser.uid);
                  return FutureBuilder<UserInfor>(
                    future: bloc.getUserInfor(id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData)
                        return _buildUserCard(context, snapshot.data!);
                      else
                        return Center(child: CircularProgressIndicator());
                    },
                  );
                },
                itemCount: userIdList.length,
              );
            } else {
              return Center(
                child: Text("No users"),
              );
            }
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      );
    }

    _buildBody() {
      return _textSearch.isEmpty ? _buildChatList() : _buildSearchUserList();
    }

    return KeyboardDismisser(
      child: Scaffold(
        appBar: AppBar(
          title: CustomText(
            text: 'Chat App',
            textSize: getProportionateScreenWidth(18),
            textColor: AppColor.white,
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: currentUser.photoURL == null
                  ? Icon(
                      Icons.account_circle,
                      color: Colors.white,
                    )
                  : Material(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
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
                            size: 50,
                            color: AppColor.doveGray,
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
              SizedBox(height: getProportionateScreenHeight(10)),
              _buildSearchUser(),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }
}
