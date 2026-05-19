import 'package:cloud_firestore/cloud_firestore.dart';

class LogService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Her işlemde çağrılır, logs koleksiyonuna kayıt yazar
  static Future<void> kaydet(String userId, String islem) async {
    await _db.collection('logs').add({
      'userId': userId,
      'islem': islem,
      'zaman': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
