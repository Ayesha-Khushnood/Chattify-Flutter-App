enum Type { text, image }

class Message {
  Message({
    required this.msg,
    required this.toId,
    required this.read,
    required this.type,
    required this.fromId,
    required this.sent,
  });

  final String msg;
  final String toId;
  final String read;
  final Type type;
  final String fromId;
  final String sent;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      msg: json['msg'] ?? '',
      toId: json['toId'] ?? '',
      read: json['read'] ?? '',
      fromId: json['fromId'] ?? '',
      sent: json['sent'] ?? '',
      type: _typeFromString(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msg': msg,
      'toId': toId,
      'read': read,
      'type': type.name,
      'fromId': fromId,
      'sent': sent,
    };
  }

  static Type _typeFromString(String? type) {
    if (type == null) return Type.text;
    return Type.values.firstWhere(
          (e) => e.name == type,
      orElse: () => Type.text,
    );
  }
}
