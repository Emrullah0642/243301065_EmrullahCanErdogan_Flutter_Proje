class KullaniciModel {
  final String uid;
  final String ad;
  final String email;
  final String rol; // 'ogrenci' veya 'danisman'

  KullaniciModel({
    required this.uid,
    required this.ad,
    required this.email,
    required this.rol,
  });

  factory KullaniciModel.fromMap(Map<String, dynamic> map) {
    return KullaniciModel(
      uid: map['uid'] ?? '',
      ad: map['ad'] ?? '',
      email: map['email'] ?? '',
      rol: map['rol'] ?? 'ogrenci',
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'ad': ad, 'email': email, 'rol': rol};
  }
}
