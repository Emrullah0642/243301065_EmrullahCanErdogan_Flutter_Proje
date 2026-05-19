import 'package:flutter/material.dart';
import '../models/kullanici_model.dart';
import '../models/basvuru_model.dart';
import '../services/auth_service.dart';
import '../services/basvuru_service.dart';
import 'arsiv_screen.dart';

class ProfilScreen extends StatelessWidget {
  final KullaniciModel kullanici;

  const ProfilScreen({super.key, required this.kullanici});

  @override
  Widget build(BuildContext context) {
    final isDanisman = kullanici.rol == 'danisman';
    final basvuruService = BasvuruService();
    final stream = isDanisman
        ? basvuruService.danismanBasvurulari(kullanici.email)
        : basvuruService.ogrenciBasvurulari(kullanici.uid);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Profilim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo.withValues(alpha: 0.2),
              child: Icon(
                isDanisman ? Icons.person_pin : Icons.school,
                size: 50,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              kullanici.ad,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo),
              ),
              child: Text(
                isDanisman ? 'Danışman' : 'Öğrenci',
                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.indigo),
                title: const Text('E-posta'),
                subtitle: Text(kullanici.email),
              ),
            ),
            const SizedBox(height: 16),

            // İstatistikler
            StreamBuilder<List<BasvuruModel>>(
              stream: stream,
              builder: (context, snapshot) {
                final liste = snapshot.data ?? [];
                final beklemede = liste.where((b) => b.durum == 'beklemede').length;
                final onaylandi = liste.where((b) => b.durum == 'onaylandi').length;
                final reddedildi = liste.where((b) => b.durum == 'reddedildi').length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDanisman ? 'Başvuru İstatistikleri' : 'Başvuru Özeti',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _istatKart('Toplam', liste.length, Colors.indigo),
                        const SizedBox(width: 8),
                        _istatKart('Beklemede', beklemede, Colors.orange),
                        const SizedBox(width: 8),
                        _istatKart('Onaylanan', onaylandi, Colors.green),
                        const SizedBox(width: 8),
                        _istatKart('Reddedilen', reddedildi, Colors.red),
                      ],
                    ),
                    if (isDanisman && beklemede > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              '$beklemede bekleyen başvurunuz var!',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArsivScreen(kullanici: kullanici)),
                ),
                icon: const Icon(Icons.archive),
                label: const Text('Arşivi Görüntüle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthService().cikisYap();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _istatKart(String baslik, int sayi, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: renk.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$sayi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: renk)),
            Text(baslik, style: TextStyle(fontSize: 10, color: renk)),
          ],
        ),
      ),
    );
  }
}
