import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/basvuru_service.dart';
import '../models/kullanici_model.dart';
import '../models/basvuru_model.dart';
import 'basvuru_ekle_screen.dart';
import 'basvuru_detay_screen.dart';
import 'profil_screen.dart';
import 'ogrenci_listesi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _basvuruService = BasvuruService();
  KullaniciModel? _kullanici;
  String _filtre = 'Hepsi';
  String _aramaMetni = '';
  final _aramaController = TextEditingController();

  // Feature 3: Durum değişikliği bildirimi
  final Map<String, String> _eskiDurumlar = {};
  StreamSubscription<List<BasvuruModel>>? _basvuruSub;

  @override
  void initState() {
    super.initState();
    _kullaniciyiYukle();
  }

  @override
  void dispose() {
    _basvuruSub?.cancel();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _kullaniciyiYukle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final k = await _authService.getKullanici(uid);
      if (mounted) {
        setState(() => _kullanici = k);
        if (k != null) _basvuruDinle(k);
      }
    }
  }

  // Feature 3: Başvuru durumu değişince bildirim banner göster
  void _basvuruDinle(KullaniciModel k) {
    final stream = k.rol == 'danisman'
        ? _basvuruService.danismanBasvurulari(k.email)
        : _basvuruService.ogrenciBasvurulari(k.uid);

    bool ilkYukleme = true;

    _basvuruSub = stream.listen((liste) {
      if (ilkYukleme) {
        // İlk yüklemede sadece mevcut durumları kaydet, bildirim gösterme
        for (final b in liste) {
          _eskiDurumlar[b.id] = b.durum;
        }
        ilkYukleme = false;
        return;
      }

      for (final b in liste) {
        final eskiDurum = _eskiDurumlar[b.id];
        if (eskiDurum != null && eskiDurum != b.durum) {
          // Durum değişti!
          final mesaj = b.durum == 'onaylandi'
              ? '✅ "${b.evrakTuru}" başvurunuz onaylandı!'
              : b.durum == 'reddedildi'
                  ? '❌ "${b.evrakTuru}" başvurunuz reddedildi.'
                  : '"${b.evrakTuru}" durumu güncellendi.';
          final renk = b.durum == 'onaylandi'
              ? Colors.green[700]!
              : b.durum == 'reddedildi'
                  ? Colors.red[700]!
                  : Colors.orange;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(mesaj)),
                  ],
                ),
                backgroundColor: renk,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
        _eskiDurumlar[b.id] = b.durum;
      }
    });
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

  IconData _durumIkonu(String durum) {
    switch (durum) {
      case 'onaylandi': return Icons.check_circle;
      case 'reddedildi': return Icons.cancel;
      default: return Icons.hourglass_empty;
    }
  }

  List<BasvuruModel> _filtrele(List<BasvuruModel> liste) {
    var sonuc = liste;
    if (_filtre != 'Hepsi') {
      sonuc = sonuc.where((b) => b.durum == _filtre).toList();
    }
    if (_aramaMetni.isNotEmpty) {
      sonuc = sonuc.where((b) =>
        b.evrakTuru.toLowerCase().contains(_aramaMetni.toLowerCase()) ||
        b.aciklama.toLowerCase().contains(_aramaMetni.toLowerCase()) ||
        b.ogrenciAd.toLowerCase().contains(_aramaMetni.toLowerCase())
      ).toList();
    }
    return sonuc;
  }

  Widget _ozet(List<BasvuruModel> liste) {
    final beklemede = liste.where((b) => b.durum == 'beklemede').length;
    final onaylandi = liste.where((b) => b.durum == 'onaylandi').length;
    final reddedildi = liste.where((b) => b.durum == 'reddedildi').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          _ozetKart('Beklemede', beklemede, Colors.orange),
          const SizedBox(width: 8),
          _ozetKart('Onaylanan', onaylandi, Colors.green),
          const SizedBox(width: 8),
          _ozetKart('Reddedilen', reddedildi, Colors.red),
        ],
      ),
    );
  }

  Widget _ozetKart(String baslik, int sayi, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: renk.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$sayi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: renk)),
            const SizedBox(height: 2),
            Text(baslik, style: TextStyle(fontSize: 11, color: renk)),
          ],
        ),
      ),
    );
  }

  // Feature 8: Pull to refresh
  Future<void> _yenile() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_kullanici == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDanisman = _kullanici!.rol == 'danisman';
    final stream = isDanisman
        ? _basvuruService.danismanBasvurulari(_kullanici!.email)
        : _basvuruService.ogrenciBasvurulari(_kullanici!.uid);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(isDanisman ? 'Tüm Başvurular' : 'Başvurularım'),
        actions: [
          // Feature 6: Danışman öğrenci listesi butonu
          if (isDanisman)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Öğrenci Listesi',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OgrenciListesiScreen(kullanici: _kullanici!),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilScreen(kullanici: _kullanici!)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<BasvuruModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tumListe = snapshot.data ?? [];
          final filtrelenmis = _filtrele(tumListe);

          return Column(
            children: [
              // Özet kartlar
              _ozet(tumListe),
              const SizedBox(height: 8),

              // Arama kutusu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _aramaController,
                  decoration: InputDecoration(
                    hintText: 'Başvuru ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _aramaMetni.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _aramaController.clear();
                              setState(() => _aramaMetni = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (v) => setState(() => _aramaMetni = v),
                ),
              ),
              const SizedBox(height: 8),

              // Filtre chip'leri
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: ['Hepsi', 'beklemede', 'onaylandi', 'reddedildi'].map((f) {
                    final etiket = f == 'Hepsi' ? 'Hepsi' : _durumMetin(f);
                    final secili = _filtre == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(etiket),
                        selected: secili,
                        onSelected: (_) => setState(() => _filtre = f),
                        selectedColor: Colors.indigo.withValues(alpha: 0.2),
                        checkmarkColor: Colors.indigo,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),

              // Liste (Feature 8: Pull to refresh ile)
              Expanded(
                child: filtrelenmis.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _yenile,
                        child: ListView(
                          children: [
                            SizedBox(
                              height: 300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.inbox, size: 64, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    Text(
                                      _aramaMetni.isNotEmpty || _filtre != 'Hepsi'
                                          ? 'Sonuç bulunamadı'
                                          : isDanisman ? 'Henüz başvuru yok' : 'Henüz başvurunuz yok',
                                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Yenilemek için aşağı çekin',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _yenile,
                        color: Colors.indigo,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: filtrelenmis.length,
                          itemBuilder: (context, index) {
                            final b = filtrelenmis[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _durumRengi(b.durum).withValues(alpha: 0.15),
                                  child: Icon(_durumIkonu(b.durum), color: _durumRengi(b.durum)),
                                ),
                                title: Text(b.evrakTuru, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  isDanisman ? b.ogrenciAd : b.aciklama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _durumRengi(b.durum).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _durumRengi(b.durum)),
                                  ),
                                  child: Text(
                                    _durumMetin(b.durum),
                                    style: TextStyle(color: _durumRengi(b.durum), fontSize: 12),
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BasvuruDetayScreen(
                                      basvuru: b,
                                      kullanici: _kullanici!,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isDanisman
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BasvuruEkleScreen(kullanici: _kullanici!),
                ),
              ),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Başvuru'),
            ),
    );
  }
}
