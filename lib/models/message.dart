import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: constant_identifier_names
enum MessageType { Text, Image }
// ignore: constant_identifier_names
enum MessageStatus { Waiting, Sent, Delivered, Seen }

class Message {
  String? senderID;
  String? content;
  MessageType? messageType;
  Timestamp? sentAt;
  MessageStatus? status;

  Message({
    required this.senderID,
    required this.content,
    required this.messageType,
    required this.sentAt,
    this.status = MessageStatus.Waiting,
  });

  Message.fromJson(Map<String, dynamic> json) {
    senderID = json['senderID'];
    content = json['content'];
    sentAt = json['sentAt'] != null ? json['sentAt'] as Timestamp : null;
    messageType = json['messageType'] != null
        ? MessageType.values.byName(json['messageType'])
        : null;
    status = json['status'] != null
        ? MessageStatus.values.byName(json['status'])
        : MessageStatus.Waiting;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['senderID'] = senderID;
    data['content'] = content;
    data['sentAt'] = sentAt;
    data['messageType'] = messageType?.name;
    data['messageStatus'] = messageType?.name;
    data['status'] = status?.name;
    return data;
  }

  Map<String, dynamic> updateStatus(String recentStatus) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['senderID'] = senderID;
    data['content'] = content;
    data['sentAt'] = sentAt;
    data['messageType'] = messageType?.name;
    data['messageStatus'] = messageType?.name;
    data['status'] = recentStatus;
    return data;
  }

}
