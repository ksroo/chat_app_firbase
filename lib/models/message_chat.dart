import 'package:chat_ui/utils/firestore_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessageChat {
  String idFrom;
  String idTo;
  String timestamp;
  String content;
  int type;

  MessageChat({
    required this.content,
    required this.idFrom,
    required this.idTo,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.idFrom: this.idFrom,
      FirestoreConstants.idTo: this.idTo,
      FirestoreConstants.timestamp: this.timestamp,
      FirestoreConstants.content: this.content,
      FirestoreConstants.type: this.type,
    };
  }

  factory MessageChat.fromDocumnet(DocumentSnapshot doc) {
    String idFrom = doc.get(FirestoreConstants.idFrom);
    String idTo = doc.get(FirestoreConstants.idTo);
    String timestamp = doc.get(FirestoreConstants.timestamp);
    String content = doc.get(FirestoreConstants.content);
    int type = doc.get(FirestoreConstants.type);

    return MessageChat(
        content: content,
        idFrom: idFrom,
        idTo: idTo,
        timestamp: timestamp,
        type: type);
  }
}
