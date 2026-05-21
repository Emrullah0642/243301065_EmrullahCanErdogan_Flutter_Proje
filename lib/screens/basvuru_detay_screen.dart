import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/basvuru_model.dart';
import '../models/kullanici_model.dart';
import '../services/basvuru_service.dart';
import 'basvuru_ekle_screen.dart';

class BasvuruDetayScreen extends StatefulWidget {
  final BasvuruModel basvuru;
  final KullaniciModel kullanici;

  const BasvuruDetayScreen({super.key, required this.basvuru, required this.kullanici});

  @override
  State<BasvuruDetayScreen> createState() => _BasvuruDetayScreenState();
}

class _BasvuruDetayScreenState extends State<BasvuruDetayScreen> {
  final _basvuruService = BasvuruService();
  final _yorumController = TextEditingController();
  final _danismanLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _danismanLinkController.text = widget.basvuru.danismanDosyaUrl ?? '';
  }

  @override
  void dispose() {
    _yorumController.dispose();
    _danismanLinkController.dispose();
    super.dispose();
  }

  Color _durumRengi(String durum) {
    switch (durum) {
      case 'onaylandi': return Colors.green;
      case 'reddedildi': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _durumMetin(String durum) {
    switch (durum) {
      case 'onaylandi': return 'Onaylandı';
      case 'reddedildi': return 'Reddedildi';
      default: return 'Beklemede';
    }
  }

  Future<void> _dosyaAc(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Açılamadı: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _kararVer(String yeniDurum) async {
    final link = _danismanLinkController.text.trim();
    await _basvuruService.durumGuncelle(
      basvuruId: widget.basvuru.id,
      yeniDurum: yeniDurum,
      danismanId: widget.kullanici.uid,
      yorum: _yorumController.text.trim().isEmpty ? null : _yorumController.text.trim(),
      danismanDosyaUrl: link.isEmpty ? null : link,
      danismanDosyaAdi: link.isEmpty ? null : 'Danışman Belgesi',
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _sil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Başvuruyu Arşivle'),
        content: const Text('Bu başvuru arşive taşınacak. Profilden arşivi görüntüleyebilirsiniz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], foregroundColor: Colors.white),
            child: const Text('Arşivle'),
          ),
        ],
      ),
    );
    if (onay == true) {
      await _basvuruService.basvuruSil(widget.basvuru.id, widget.kullanici.uid);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDanisman = widget.kullanici.rol == 'danisman';
    final b = widget.basvuru;
    final tarihStr = DateFormat('dd.MM.yyyy HH:mm').format(b.tarih);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Başvuru Detayı'),
        actions: [
          if (!isDanisman && b.durum == 'beklemede')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BasvuruEkleScreen(
                    kullanici: widget.kullanici,
                    mevcutBasvuru: b,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Arşivle',
            onPressed: _sil,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bilgiKarti('Evrak Türü', b.evrakTuru, Icons.description),
            _bilgiKarti('Öğrenci', b.ogrenciAd, Icons.person),
            if (b.ogrenciNo != null && b.ogrenciNo!.isNotEmpty)
              _bilgiKarti('Öğrenci No', b.ogrenciNo!, Icons.badge),
            _bilgiKarti('Tarih', tarihStr, Icons.calendar_today),
            _bilgiKarti('Açıklama', b.aciklama, Icons.notes),
            const SizedBox(height: 8),

            // Durum kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _durumRengi(b.durum).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _durumRengi(b.durum)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: _durumRengi(b.durum)),
                  const SizedBox(width: 8),
                  Text(
                    'Durum: ${_durumMetin(b.durum)}',
                    style: TextStyle(
                      color: _durumRengi(b.durum),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Öğrencinin eklediği dosya
            if (b.dosyaUrl != null && b.dosyaUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Öğrenci Belgesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 6),
              _dosyaKarti(
                ad: b.dosyaAdi ?? 'Dosya',
                url: b.dosyaUrl!,
                renk: Colors.indigo,
              ),
            ],

            // Danışman yorumu
            if (b.danismanYorum != null && b.danismanYorum!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _bilgiKarti('Danışman Yorumu', b.danismanYorum!, Icons.comment),
            ],

            // Danışmanın yüklediği yanıt dosyası
            if (b.danismanDosyaUrl != null && b.danismanDosyaUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Danışman Yanıt Belgesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 6),
              _dosyaKarti(
                ad: b.danismanDosyaAdi ?? 'Yanıt Dosyası',
                url: b.danismanDosyaUrl!,
                renk: Colors.teal,
              ),
            ],

            // Danışman karar verme paneli
            if (isDanisman && b.durum == 'beklemede') ...[
              const SizedBox(height: 24),
              const Divider(),
              const Text('Karar Ver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _yorumController,
                decoration: const InputDecoration(
                  labelText: 'Yorum (isteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Danışman yanıt belgesi linki
              const Text('Yanıt Belgesi Linki (İsteğe Bağlı)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              const Text(
                'Google Drive vb. yükleyip paylaşım linkini buraya yapıştırın.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _danismanLinkController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'https://drive.google.com/...',
                  prefixIcon: Icon(Icons.link, color: Colors.teal),
                ),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _kararVer('onaylandi'),
                      icon: const Icon(Icons.check),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _kararVer('reddedildi'),
                      icon: const Icon(Icons.close),
                      label: const Text('Reddet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dosyaKarti({
    required String ad,
    required String url,
    required Color renk,
    VoidCallback? onKaldir,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: renk.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: renk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ad,
              style: TextStyle(color: renk, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onKaldir != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: onKaldir,
              tooltip: 'Kaldır',
            )
          else
            TextButton.icon(
              onPressed: () => _dosyaAc(url),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Aç'),
              style: TextButton.styleFrom(foregroundColor: renk),
            ),
        ],
      ),
    );
  }

  Widget _bilgiKarti(String baslik, String deger, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.indigo, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(deger, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
