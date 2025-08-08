import 'dart:developer';
import 'dart:io';

import 'package:chattify/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../helpers/cloudinary_helper.dart';
import '../models/chat_user.dart';

class APIs {
  // for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore store = FirebaseFirestore.instance;

  // for storing self information
  static late ChatUser me;



  //for push notification
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  //for getting firebase message token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();
    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken=t;
        log('Push Token:$t');
      }
    });
  }

  // to return current user
  static User get user => auth.currentUser!;

  // check if user exists
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  // get current user info
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((value) async {
      if (value.exists) {
        me = ChatUser.fromJson(value.data()!);
        await getFirebaseMessagingToken();


        // log('My Data: ${user.data()}');
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  // create a new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey, I'm using We Chat!",
      image: user.photoURL.toString(),
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
    );
    await firestore.collection('users').doc(user.uid).set(chatUser.toJson());
  }

  // get all users
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // update user info
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  //for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
    ChatUser chatUser,
  ) {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: chatUser.id)
        .snapshots();
  }

  // Update the updateActiveStatus method
  // Update the updateActiveStatus method
  static Future<void> updateActiveStatus(bool isOnline) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    await firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': isOnline ? 'online' : time,
    });
  }

// Add this to handle connection changes
  static Future<void> handleConnectionChange(bool isConnected) async {
    if (isConnected) {
      await updateActiveStatus(true);
    } else {
      await updateActiveStatus(false);
    }
  }



  // Cloudinary se image upload + Firestore mein update
  static Future<void> updateProfilePictureCloudinary(File file) async {
    final imageUrl = await CloudinaryHelper.uploadImage(file);

    if (imageUrl != null) {
      me.image = imageUrl;
      await firestore.collection('users').doc(user.uid).update({
        'image': imageUrl,
      });
    } else {
      log('❌ Failed to upload image to Cloudinary.');
    }
  }

  ///******************Chat Screen related APIs***************/

  // chats(colloection) --> conversation_id (doc) -->messages (collection)--message(doc)

  //useful for getting conversation id
  static String getConversationID(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  //get all messages of a specific convo from firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
    ChatUser chatUser,
  ) {
    return firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  static Future<void> sendMessage(
    ChatUser chatUser,
    String msg,
    Type type,
  ) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    //message to send
    final Message message = Message(
      msg: msg,
      toId: chatUser.id,
      read: '',
      type: type,
      fromId: user.uid,
      sent: time,
    );
    final ref = firestore.collection(
      'chats/${getConversationID(chatUser.id)}/messages/',
    );
    await ref.doc(time).set(message.toJson());
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
    ChatUser user,
  ) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  // send chat image
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // Upload to Cloudinary
    final imageUrl = await CloudinaryHelper.uploadImage(file);

    if (imageUrl != null) {
      final Message message = Message(
        msg: imageUrl,
        toId: chatUser.id,
        read: '',
        type: Type.image,
        fromId: user.uid,
        sent: time,
      );

      final ref = firestore.collection(
        'chats/${getConversationID(chatUser.id)}/messages/',
      );
      await ref.doc(time).set(message.toJson());
    } else {
      log('❌ Failed to upload image to Cloudinary.');
    }
  }

  // In class APIs

  /// delete message by doc id (timestamp)
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .delete();
  }

  /// edit/update message text
  static Future<void> updateMessage(
      Message message, String updatedText) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedText});
  }

}
