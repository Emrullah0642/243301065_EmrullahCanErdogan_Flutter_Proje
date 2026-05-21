import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kullanici_model.dart';
import 'log_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get mevcutKullanici => _auth.currentUser;

  Future<KullaniciModel?> kayitOl({
    required String ad,
    required String email,
    required String sifre,
    required String rol,
    String? ogrenciNo,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: sifre,
    );
    final kullanici = KullaniciModel(
      uid: cred.user!.uid,
      ad: ad,
      email: email,
      rol: rol,
      ogrenciNo: ogrenciNo,
    );
    await _db.collection('kullanicilar').doc(cred.user!.uid).set(kullanici.toMap());
    await LogService.kaydet(cred.user!.uid, 'Kayıt oldu: $email (rol: $rol)');
    return kullanici;
  }

  Future<KullaniciModel?> girisYap({
    required String email,
    required String sifre,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: sifre,
    );
    await LogService.kaydet(cred.user!.uid, 'Giriş yaptı: $email');
    return getKullanici(cred.user!.uid);
  }

  Future<void> cikisYap() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await LogService.kaydet(uid, 'Çıkış yaptı');
    }
    await _auth.signOut();
  }

  Future<KullaniciModel?> getKullanici(String uid) async {
    final doc = await _db.collection('kullanicilar').doc(uid).get();
    if (doc.exists) {
      return KullaniciModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Feature 4: Şifre sıfırlama e-postası gönder
  Future<void> sifreSifirla(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
