import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class ChatScreen extends StatefulWidget {
  static const id = 'chat';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _store = FirebaseFirestore.instance;
  AnimationController controller;
  Animation animation;
  User user;
  String messageText;
  bool _showSpinner = false;
  TextEditingController textController = TextEditingController();
  bool isSenderCurrentUser = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    controller.forward();
    animation = ColorTween(begin: Colors.white, end: Colors.lightBlueAccent)
        .animate(controller);
    animation.addListener(() => setState(() {}));
    user = _auth.currentUser;
    if (user == null) {
      Navigator.pop(context);
    } else {
      print('Hello ${user.email}');
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller = null;
    animation = null;
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _showSpinner,
      child: Scaffold(
        appBar: AppBar(
          leading: null,
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
          title: Text('⚡️Chat'),
          backgroundColor: animation.value,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: MessageBuilder(store: _store, currentUser: user.email),
              ),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: textController,
                        onChanged: (value) {
                          messageText = value;
                        },
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    FlatButton(
                      onPressed: () async {
                        setState(() => _showSpinner = true);
                        try {
                          DocumentReference doc = await _store
                              .collection('messages')
                              .add({'text': messageText, 'sender': user.email});
                          if (doc == null) {
                            throw 'unable to send message';
                          }
                        } catch (e) {
                          print(e);
                        } finally {
                          setState(() => _showSpinner = false);
                          textController.clear();
                        }
                      },
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageBuilder extends StatelessWidget {
  final FirebaseFirestore store;
  final String currentUser;
  MessageBuilder({this.store, this.currentUser});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: StreamBuilder<QuerySnapshot>(
        stream: store.collection('messages').snapshots(),
        builder: (context, snapshot) {
          List<Widget> messageWidgets = [];
          if (snapshot.hasData) {
            snapshot.data.docs.forEach((element) {
              String text = element.data()['text'];
              String sender = element.data()['sender'];
              bool isSenderCurrentUser = currentUser == sender ? true : false;
              messageWidgets.add(
                MessageBubble(
                    sender: sender,
                    text: text,
                    isSenderCurrentUser: isSenderCurrentUser),
              );
            });
          }
          return ListView(
            children: messageWidgets,
          );
        },
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isSenderCurrentUser});

  final String sender;
  final String text;
  final bool isSenderCurrentUser;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isSenderCurrentUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(sender, style: TextStyle(color: Colors.grey.shade700)),
        Material(
          borderRadius:
              isSenderCurrentUser ? kMeBorderRadius : kNotMeBorderRadius,
          color:
              isSenderCurrentUser ? Colors.blueAccent : Colors.lightBlueAccent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      isSenderCurrentUser ? FontWeight.bold : FontWeight.normal,
                  color: isSenderCurrentUser ? Colors.white : Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
