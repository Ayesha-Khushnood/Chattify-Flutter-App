import 'package:cached_network_image/cached_network_image.dart';
import 'package:chattify/api/Apis.dart';
import 'package:chattify/models/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/my_date_util.dart';

class MessageCard extends StatefulWidget {
  final Message message;

  const MessageCard({super.key, required this.message});

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  bool _hasBeenViewed = false;
  Message get message => widget.message;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    final bool shouldMarkAsRead = APIs.user.uid != message.fromId &&
        message.read.isEmpty &&
        !_hasBeenViewed;

    if (shouldMarkAsRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        APIs.updateMessageReadStatus(message);
        setState(() => _hasBeenViewed = true);
      });
    }

    final isMe = APIs.user.uid == message.fromId;
    final isText = message.type == Type.text;

    return GestureDetector(
      onLongPress: _showBottomSheet,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mq.width * 0.02,
          vertical: mq.height * 0.004,
        ),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mq.width * 0.75),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 16 : 0),
                  topRight: Radius.circular(isMe ? 0 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              color: isMe
                  ? const Color.fromARGB(255, 218, 255, 176)
                  : const Color.fromARGB(255, 221, 245, 255),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: isText
                        ? const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)
                        : const EdgeInsets.all(8),
                    child: isText
                        ? Text(
                      message.msg,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.black87),
                    )
                        : GestureDetector(
                      onTap: _viewImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: message.msg,
                          placeholder: (context, url) => const Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 8, right: 8, bottom: 4, top: 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          MyDateUtil.getFormatTime(
                              context: context, time: message.sent),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                        if (isMe) const SizedBox(width: 4),
                        if (isMe)
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: message.read.isNotEmpty ? Colors.blue : Colors.grey,
                          ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _viewImage() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: CachedNetworkImage(
          imageUrl: message.msg,
          placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (message.type == Type.text)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Text'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.msg));
                  Navigator.pop(context);
                },
              ),
            if (APIs.user.uid == message.fromId && message.type == Type.text)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog();
                },
              ),
            if (APIs.user.uid == message.fromId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  APIs.deleteMessage(message);
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.remove_red_eye_outlined),
              title: Text(
                  'Sent At: ${MyDateUtil.getFormatTime(context: context, time: message.sent)}'),
            ),
            ListTile(
              leading: const Icon(Icons.remove_red_eye, color: Colors.green),
              title: Text(
                message.read.isEmpty
                    ? 'Read At: Not seen yet'
                    : 'Read At: ${MyDateUtil.getFormatTime(context: context, time: message.read)}',
              ),
            ),
          ]),
        );
      },
    );
  }

  void _showEditDialog() {
    String updated = message.msg;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextFormField(
          initialValue: updated,
          onChanged: (val) => updated = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              APIs.updateMessage(message, updated);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
