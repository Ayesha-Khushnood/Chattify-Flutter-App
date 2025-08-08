import 'package:cached_network_image/cached_network_image.dart';
import 'package:chattify/helpers/my_date_util.dart';
import 'package:chattify/models/message.dart';

import 'package:chattify/widgets/view_profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../api/Apis.dart';
import '../models/chat_user.dart';
import '../screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  Message? _message;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * .02, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0.5,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)),
          );
        },
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

            if (list.isNotEmpty) _message = list[0];

            return ListTile(
              title: Text(
                widget.user.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _message != null
                    ? _message!.type == Type.image
                    ? 'image'
                    : _message!.msg
                    : widget.user.about,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewProfileScreen(
                        imageUrl: widget.user.image,
                        name: widget.user.name,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: widget.user.image,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .3),
                    child: CachedNetworkImage(
                      width: mq.height * .055,
                      height: mq.height * .055,
                      imageUrl: widget.user.image,
                      errorWidget: (context, url, error) => const CircleAvatar(
                        child: Icon(CupertinoIcons.person),
                      ),
                    ),
                  ),
                ),
              ),
              trailing: _message == null
                  ? null
                  : _message!.read.isEmpty &&
                  _message!.fromId != APIs.user.uid
                  ? Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
                  : Text(
                MyDateUtil.getLastMessageTime(
                    context: context, time: _message!.sent),
                style: const TextStyle(color: Colors.black54),
              ),
            );
          },
        ),
      ),
    );
  }
}
