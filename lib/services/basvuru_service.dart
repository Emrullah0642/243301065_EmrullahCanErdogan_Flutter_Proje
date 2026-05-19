import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/basvuru_model.dart';
import 'log_service.dart';

class BasvuruService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> basvuruOlustur(BasvuruModel basvuru) async {
    await _db.collection('basvurular').add(basvuru.toMap());
    await LogService.kaydet(basvuru.ogrenciId, 'Başvuru oluşturdu: ${basvuru.evrakTuru}');
  }

  Stream<List<BasvuruModel>> ogrenciBasvurulari(String ogrenciId) {
    return _db
        .collection('basvurular')
        .where('ogrenciId', isEqualTo: ogrenciId)
        .snapshots()
        .map((snap) {
          final liste = snap.docs
              .map((d) => BasvuruModel.fromMap(d.id, d.data()))
              .where((b) => !b.arsivlendi) // dart tarafında filtrele
              .toList();
          liste.sort((a, b) => b.tarih.compareTo(a.tarih));
          return liste;
        });
  }

  // Danışman kendi e-postasına gönderilen başvuruları görür (arşivlenenler hariç)
  Stream<List<BasvuruModel>> danismanBasvurulari(String danismanEmail) {
    return _db
        .collection('basvurular')
        .where('danismanEmail', isEqualTo: danismanEmail)
        .snapshots()
        .map((snap) {
          final liste = snap.docs
              .map((d) => BasvuruModel.fromMap(d.id, d.data()))
              .where((b) => !b.arsivlendi) // arşivlenenleri gizle
              .toList();
          liste.sort((a, b) => b.tarih.compareTo(a.tarih));
          return liste;
        });
  }

  Future<void> durumGuncelle({
    required String basvuruId,
    required String yeniDurum,
    required String danismanId,
    String? yorum,
    String? danismanDosyaUrl,
    String? danismanDosyaAdi,
  }) async {
    await _db.collection('basvurular').doc(basvuruId).update({
      'durum': yeniDurum,
      'danismanYorum': yorum,
      'danismanDosyaUrl': danismanDosyaUrl,
      'danismanDosyaAdi': danismanDosyaAdi,
    });
    await LogService.kaydet(danismanId, 'Başvuru $yeniDurum: $basvuruId');
  }

  Future<void> basvuruGuncelle(BasvuruModel basvuru) async {
    await _db.collection('basvurular').doc(basvuru.id).update(basvuru.toMap());
    await LogService.kaydet(basvuru.ogrenciId, 'Başvuru düzenledi: ${basvuru.evrakTuru}');
  }

  // Gerçekten silmez, arşive taşır
  Future<void> basvuruSil(String basvuruId, String ogrenciId) async {
    await _db.collection('basvurular').doc(basvuruId).update({'arsivlendi': true});
    await LogService.kaydet(ogrenciId, 'Başvuru arşivledi: $basvuruId');
  }

  // Öğrencinin arşivlenmiş başvuruları
  Stream<List<BasvuruModel>> arsivBasvurular(String ogrenciId) {
    return _db
        .collection('basvurular')
        .where('ogrenciId', isEqualTo: ogrenciId)
        .where('arsivlendi', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final liste = snap.docs
              .map((d) => BasvuruModel.fromMap(d.id, d.data()))
              .toList();
          liste.sort((a, b) => b.tarih.compareTo(a.tarih));
          return liste;
        });
  }

  // Danışmanın arşivlenmiş başvuruları
  Stream<List<BasvuruModel>> danismanArsivBasvurular(String danismanEmail) {
    return _db
        .collection('basvurular')
        .where('danismanEmail', isEqualTo: danismanEmail)
        .where('arsivlendi', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final liste = snap.docs
              .map((d) => BasvuruModel.fromMap(d.id, d.data()))
              .toList();
          liste.sort((a, b) => b.tarih.compareTo(a.tarih));
          return liste;
        });
  }
}
