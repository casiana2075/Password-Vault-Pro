import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EncryptionHelper.dart';

class SecureKeyManager {
  static final _db = FirebaseFirestore.instance;

  static Future<String> getOrCreateUserKey() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");

    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();

    if (doc.exists && doc.data()!.containsKey('aesKey')) {
      return doc.data()!['aesKey'];
    } else {
      final newKey = EncryptionHelper.generateRandomAESKey();
      await docRef.set({'aesKey': newKey}, SetOptions(merge: true));
      return newKey;
    }
  }
}
