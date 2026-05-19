class BasvuruModel {
  final String id;
  final String ogrenciId;
  final String ogrenciAd;
  final String evrakTuru;
  final String aciklama;
  final String durum; // 'beklemede', 'onaylandi', 'reddedildi'
  final DateTime tarih;
  final String? danismanYorum;
  final String danismanEmail;
  final bool arsivlendi;
  final String? dosyaUrl;      // öğrencinin eklediği dosya
  final String? dosyaAdi;
  final String? danismanDosyaUrl;  // danışmanın yanıt dosyası
  final String? danismanDosyaAdi;

  BasvuruModel({
    required this.id,
    required this.ogrenciId,
    required this.ogrenciAd,
    required this.evrakTuru,
    required this.aciklama,
    required this.durum,
    required this.tarih,
    required this.danismanEmail,
    this.danismanYorum,
    this.arsivlendi = false,
    this.dosyaUrl,
    this.dosyaAdi,
    this.danismanDosyaUrl,
    this.danismanDosyaAdi,
  });

  factory BasvuruModel.fromMap(String id, Map<String, dynamic> map) {
    return BasvuruModel(
      id: id,
      ogrenciId: map['ogrenciId'] ?? '',
      ogrenciAd: map['ogrenciAd'] ?? '',
      evrakTuru: map['evrakTuru'] ?? '',
      aciklama: map['aciklama'] ?? '',
      durum: map['durum'] ?? 'beklemede',
      tarih: DateTime.fromMillisecondsSinceEpoch(map['tarih'] ?? 0).toLocal(),
      danismanEmail: map['danismanEmail'] ?? '',
      danismanYorum: map['danismanYorum'],
      arsivlendi: map['arsivlendi'] ?? false,
      dosyaUrl: map['dosyaUrl'],
      dosyaAdi: map['dosyaAdi'],
      danismanDosyaUrl: map['danismanDosyaUrl'],
      danismanDosyaAdi: map['danismanDosyaAdi'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ogrenciId': ogrenciId,
      'ogrenciAd': ogrenciAd,
      'evrakTuru': evrakTuru,
      'aciklama': aciklama,
      'durum': durum,
      'tarih': tarih.millisecondsSinceEpoch,
      'danismanEmail': danismanEmail,
      'danismanYorum': danismanYorum,
      'arsivlendi': arsivlendi,
      'dosyaUrl': dosyaUrl,
      'dosyaAdi': dosyaAdi,
      'danismanDosyaUrl': danismanDosyaUrl,
      'danismanDosyaAdi': danismanDosyaAdi,
    };
  }
}
