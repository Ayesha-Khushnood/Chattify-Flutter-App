import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chattify/helpers/my_date_util.dart';
import 'package:chattify/models/message.dart';
import 'package:chattify/widgets/message_card.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/Apis.dart';
import '../helpers/dialogs.dart';
import '../models/chat_user.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _list = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showEmoji = false;
  Size? mq;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: !_showEmoji,
        onPopInvoked: (didPop) {
          if (!didPop && _showEmoji) {
            setState(() => _showEmoji = false);
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: _appBar(),
          ),
          backgroundColor: const Color(0xFFDFD0FB),
          body: Column(
            children: [
              Expanded(child: _buildMessageList()),
              _chatInput(),
              if (_showEmoji)
                SizedBox(
                  height: mq!.height * .35,
                  child: EmojiPicker(
                    textEditingController: _textController,

                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: APIs.getAllMessages(widget.user),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
          case ConnectionState.none:
            return const Center(child: CircularProgressIndicator());
          case ConnectionState.active:
          case ConnectionState.done:
            final data = snapshot.data?.docs;
            _list = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

            return _list.isNotEmpty
                ? ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _list.length,
              padding: EdgeInsets.only(
                top: mq!.height * 0.01,
                bottom: mq!.height * 0.01,
              ),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) =>
                  MessageCard(message: _list[index]),
            )
                : const Center(
              child: Text('Say Hi!!!',
                  style: TextStyle(fontSize: 20)),
            );
        }
      },
    );
  }

  Widget _appBar() {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.only(
          top: mq!.height * 0.03,
          left: mq!.width * .025,
          right: mq!.width * .025,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black54),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(mq!.height * .3),
              child: CachedNetworkImage(
                width: mq!.height * .05,
                height: mq!.height * .05,
                imageUrl: widget.user.image,
                errorWidget: (context, url, error) =>
                const CircleAvatar(child: Icon(CupertinoIcons.person)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.user.isOnline
                      ? 'Online'
                      : MyDateUtil.getLastActiveTime(
                      context: context,
                      lastActive: widget.user.lastActive),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.only(
        left: mq!.width * 0.03,
        right: mq!.width * 0.01,
        bottom: mq!.height * 0.02,
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: mq!.height * 0.12),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 1,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          setState(() => _showEmoji = !_showEmoji);
                        });
                      },
                      icon: const Icon(Icons.emoji_emotions,
                          color: Colors.blueAccent),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onTap: () {
                          if (_showEmoji) setState(() => _showEmoji = false);
                        },
                        decoration: const InputDecoration(
                          hintText: 'Type something...',
                          hintStyle: TextStyle(color: Colors.blueAccent),
                          border: InputBorder.none,
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 9),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? picked = await picker.pickImage(
                            source: ImageSource.gallery);
                        if (picked != null) {
                          log('Picked Image Path: ${picked.path}');
                          Dialogs.showProgressBar(context);
                          await APIs.sendChatImage(
                              widget.user, File(picked.path));
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.image, color: Colors.blueAccent),
                    ),
                    IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? picked = await picker.pickImage(
                            source: ImageSource.camera);
                        if (picked != null) {
                          log('Captured Image Path: ${picked.path}');
                          Dialogs.showProgressBar(context);
                          await APIs.sendChatImage(
                              widget.user, File(picked.path));
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.camera_alt_rounded,
                          color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          MaterialButton(
            onPressed: () {
              if (_textController.text.trim().isNotEmpty) {
                APIs.sendMessage(
                    widget.user, _textController.text.trim(), Type.text);
                _textController.clear();
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
            padding: const EdgeInsets.all(11),
            shape: const CircleBorder(),
            color: const Color(0xFFBC9EFB),
            child: const Icon(Icons.send, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}
