import 'package:flutter/material.dart';
import '../models/kullanici_model.dart';
import '../models/basvuru_model.dart';
import '../services/basvuru_service.dart';

class OgrenciListesiScreen extends StatelessWidget {
  final KullaniciModel kullanici;

  const OgrenciListesiScreen({super.key, required this.kullanici});

  @override
  Widget build(BuildContext context) {
    final basvuruService = BasvuruService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Öğrenci Listesi'),
      ),
      body: StreamBuilder<List<BasvuruModel>>(
        stream: basvuruService.danismanBasvurulari(kullanici.email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tumBasvurular = snapshot.data ?? [];

          if (tumBasvurular.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Henüz başvuru gönderen öğrenci yok',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Öğrenci ID'sine göre tekrarsız liste oluştur
          final Map<String, _OgrenciOzet> ogrenciler = {};
          for (final b in tumBasvurular) {
            if (!ogrenciler.containsKey(b.ogrenciId)) {
              ogrenciler[b.ogrenciId] = _OgrenciOzet(
                ogrenciId: b.ogrenciId,
                ogrenciAd: b.ogrenciAd,
                basvurular: [],
              );
            }
            ogrenciler[b.ogrenciId]!.basvurular.add(b);
          }

          final liste = ogrenciler.values.toList();
          // Öğrenci adına göre sırala
          liste.sort((a, b) => a.ogrenciAd.compareTo(b.ogrenciAd));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final ogr = liste[index];
              final beklemede = ogr.basvurular.where((b) => b.durum == 'beklemede').length;
              final onaylandi = ogr.basvurular.where((b) => b.durum == 'onaylandi').length;
              final reddedildi = ogr.basvurular.where((b) => b.durum == 'reddedildi').length;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.withValues(alpha: 0.15),
                    child: Text(
                      ogr.ogrenciAd.isNotEmpty ? ogr.ogrenciAd[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    ogr.ogrenciAd,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Toplam ${ogr.basvurular.length} başvuru',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (beklemede > 0)
                        _durumBadge('$beklemede', Colors.orange),
                      if (onaylandi > 0) ...[
                        const SizedBox(width: 4),
                        _durumBadge('$onaylandi', Colors.green),
                      ],
                      if (reddedildi > 0) ...[
                        const SizedBox(width: 4),
                        _durumBadge('$reddedildi', Colors.red),
                      ],
                      const Icon(Icons.expand_more),
                    ],
                  ),
                  children: ogr.basvurular.map((b) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                      leading: Icon(
                        b.durum == 'onaylandi'
                            ? Icons.check_circle
                            : b.durum == 'reddedildi'
                                ? Icons.cancel
                                : Icons.hourglass_empty,
                        color: b.durum == 'onaylandi'
                            ? Colors.green
                            : b.durum == 'reddedildi'
                                ? Colors.red
                                : Colors.orange,
                        size: 20,
                      ),
                      title: Text(b.evrakTuru, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        b.aciklama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (b.durum == 'onaylandi'
                                  ? Colors.green
                                  : b.durum == 'reddedildi'
                                      ? Colors.red
                                      : Colors.orange)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b.durum == 'onaylandi'
                              ? 'Onaylandı'
                              : b.durum == 'reddedildi'
                                  ? 'Reddedildi'
                                  : 'Beklemede',
                          style: TextStyle(
                            fontSize: 11,
                            color: b.durum == 'onaylandi'
                                ? Colors.green[700]
                                : b.durum == 'reddedildi'
                                    ? Colors.red[700]
                                    : Colors.orange[700],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _durumBadge(String sayi, Color renk) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: renk,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          sayi,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _OgrenciOzet {
  final String ogrenciId;
  final String ogrenciAd;
  final List<BasvuruModel> basvurular;

  _OgrenciOzet({
    required this.ogrenciId,
    required this.ogrenciAd,
    required this.basvurular,
  });
}
