import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internship_chat/models/ChatRoomModel.dart';
import 'package:internship_chat/models/FirebaseHelper.dart';
import 'package:internship_chat/models/UserModel.dart';
import 'package:internship_chat/pages/ChatRoomPage.dart';
import 'package:internship_chat/pages/LoginPage.dart';
import 'package:internship_chat/pages/SearchPage.dart';

class HomePage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const HomePage(
      {super.key, required this.userModel, required this.firebaseUser});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void logout() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(" Are you sure want to logout!",style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  onTap: () async {
                    //Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) {
                          return LoginPage();
                        }));
                  },
                  leading: const Icon(Icons.logout),
                  title: const Text("Yes",style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),),
                ),
                ListTile(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  leading: const Icon(Icons.no_backpack),
                  title: const Text("No",style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade50,
        centerTitle: true,
        leading: Icon(CupertinoIcons.home),
        title: const Text(
          'Home Screen',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
              onPressed: () {
                logout();
              },
              icon: const Icon(Icons.exit_to_app))
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("chatroom")
              .where("users", arrayContains: widget.userModel.uid)
              .orderBy("createdon")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                QuerySnapshot chatRoomSnapshot = snapshot.data as QuerySnapshot;
                return ListView.builder(
                  itemCount: chatRoomSnapshot.docs.length,
                  itemBuilder: (context, index) {
                    ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(
                        chatRoomSnapshot.docs[index].data()
                            as Map<String, dynamic>);
                    Map<String, dynamic> participants =
                        chatRoomModel.participants!;

                    List<String> participantKeys = participants.keys.toList();
                    participantKeys.remove(widget.userModel.uid);

                    return FutureBuilder(
                        future:
                            FirebaseHelper.getUserModelById(participantKeys[0]),
                        builder: (context, userData) {
                          if (userData.connectionState ==
                              ConnectionState.done) {
                            if (userData.data != null) {
                              UserModel targetUser = userData.data as UserModel;
                              return ListTile(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return ChatRoomPage(
                                        targetUser: targetUser,
                                        chatRoom: chatRoomModel,
                                        userModel: widget.userModel,
                                        firebaseUser: widget.firebaseUser);
                                  }));
                                },
                                leading: CircleAvatar(
                                  maxRadius: 22,
                                  backgroundImage: NetworkImage(
                                      targetUser.profilepic.toString()),
                                ),
                                title: Text(
                                  targetUser.fullname.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                subtitle:
                                    (chatRoomModel.lastMessage.toString() != "")
                                        ? Text(
                                            chatRoomModel.lastMessage
                                                .toString(),
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12),
                                          )
                                        : const Text(
                                            "Say hi to your new friend!",
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12),
                                          ),
                                // trailing: Text(chatRoomModel.createdon.toString()),
                              );
                            } else {
                              return Container();
                            }
                          } else {
                            return Container();
                          }
                        });
                  },
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              } else {
                return const Center(
                  child: Text("No Chats"),
                );
              }
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[200],
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return SearchPage(
                userModel: widget.userModel, firebaseUser: widget.firebaseUser);
          }));
        },
        child: const Icon(Icons.search),
      ),
    );
  }
}
