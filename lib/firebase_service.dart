import 'dart:convert';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';

final database = FirebaseDatabase.instance.ref("notes");

Future<void> addNote(String title, String desc) async {
  final newNote = {
    "title": title,
    "description": desc,
    "timestamp": DateTime.now().toIso8601String()
  };

  await database.push().set(newNote);
}


Stream<DatabaseEvent> getNotesStream() {
  return FirebaseDatabase.instance.ref("notes").onValue;
}




final chatRef = FirebaseDatabase.instance.ref("chat");

// Future<void> sendChatMessage(String message) async {
//   final newMessage = {
//     "text": message,
//     "timestamp": DateTime.now().millisecondsSinceEpoch,
//   };
//   await chatRef.push().set(newMessage);
// }


// Future<void> sendChatMessage(String text, {File? imageFile}) async {
//   String? imageUrl;
//   if (imageFile != null) {
//     final storageRef = FirebaseStorage.instance
//         .ref()
//         .child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//     await storageRef.putFile(imageFile);
//     imageUrl = await storageRef.getDownloadURL();
//   }
//
//   final message = {
//     "text": text,
//     "timestamp": DateTime.now().millisecondsSinceEpoch,
//     if (imageUrl != null) "imageUrl": imageUrl,
//   };
//
//   await FirebaseDatabase.instance.ref("chat").push().set(message);
// }

Stream<DatabaseEvent> getChatStream() {
  return chatRef.orderByChild("timestamp").onValue;
}

Future<void> sendChatMessage(String text, {File? imageFile}) async {
  String? imageBase64;

  if (imageFile != null) {
    final bytes = await imageFile.readAsBytes();
    imageBase64 = base64Encode(bytes);
  }

  final message = {
    "text": text,
    "timestamp": DateTime.now().millisecondsSinceEpoch,
    if (imageBase64 != null) "imageBase64": imageBase64,
  };

  await FirebaseDatabase.instance.ref("chat").push().set(message);
}


Future<void> sendVoiceMessageLocal(String audioPath) async {
  final message = {
    "text": "[VOICE]",
    "localAudioPath": audioPath,
    "timestamp": DateTime.now().millisecondsSinceEpoch,
  };

  await FirebaseDatabase.instance.ref("chat").push().set(message);
}


