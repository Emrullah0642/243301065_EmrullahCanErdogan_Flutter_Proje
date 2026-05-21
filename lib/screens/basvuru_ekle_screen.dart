import 'package:flutter/material.dart';
import '../models/kullanici_model.dart';
import '../models/basvuru_model.dart';
import '../services/basvuru_service.dart';

class BasvuruEkleScreen extends StatefulWidget {
  final KullaniciModel kullanici;
  final BasvuruModel? mevcutBasvuru;

  const BasvuruEkleScreen({super.key, required this.kullanici, this.mevcutBasvuru});

  @override
  State<BasvuruEkleScreen> createState() => _BasvuruEkleScreenState();
}

class _BasvuruEkleScreenState extends State<BasvuruEkleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aciklamaController = TextEditingController();
  final _danismanEmailController = TextEditingController();
  final _dosyaLinkController = TextEditingController();
  final _digerEvrakController = TextEditingController();
  final _basvuruService = BasvuruService();
  String _seciliEvrakTuru = 'Transkript';
  bool _yukleniyor = false;

  final List<String> _evrakTurleri = [
    'Transkript',
    'Öğrenci Belgesi',
    'Staj Formu',
    'Mezuniyet Belgesi',
    'Askerlik Tecil',
    'Burs Başvurusu',
    'Ders Muafiyet Formu',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.mevcutBasvuru != null) {
      _seciliEvrakTuru = widget.mevcutBasvuru!.evrakTuru;
      _aciklamaController.text = widget.mevcutBasvuru!.aciklama;
      _danismanEmailController.text = widget.mevcutBasvuru!.danismanEmail;
      _dosyaLinkController.text = widget.mevcutBasvuru!.dosyaUrl ?? '';
    }
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _danismanEmailController.dispose();
    _dosyaLinkController.dispose();
    _digerEvrakController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _yukleniyor = true);
    try {
      final link = _dosyaLinkController.text.trim();
      // "Diğer" seçildiyse özel metni kullan
      final evrakTuru = _seciliEvrakTuru == 'Diğer'
          ? _digerEvrakController.text.trim()
          : _seciliEvrakTuru;
      if (widget.mevcutBasvuru != null) {
        final guncellenmis = BasvuruModel(
          id: widget.mevcutBasvuru!.id,
          ogrenciId: widget.kullanici.uid,
          ogrenciAd: widget.kullanici.ad,
          evrakTuru: evrakTuru,
          aciklama: _aciklamaController.text.trim(),
          danismanEmail: _danismanEmailController.text.trim(),
          durum: 'beklemede',
          tarih: DateTime.now(),
          dosyaUrl: link.isEmpty ? null : link,
          dosyaAdi: link.isEmpty ? null : 'Belge Linki',
          ogrenciNo: widget.kullanici.ogrenciNo,
        );
        await _basvuruService.basvuruGuncelle(guncellenmis);
      } else {
        final yeni = BasvuruModel(
          id: '',
          ogrenciId: widget.kullanici.uid,
          ogrenciAd: widget.kullanici.ad,
          evrakTuru: evrakTuru,
          aciklama: _aciklamaController.text.trim(),
          danismanEmail: _danismanEmailController.text.trim(),
          durum: 'beklemede',
          tarih: DateTime.now(),
          dosyaUrl: link.isEmpty ? null : link,
          dosyaAdi: link.isEmpty ? null : 'Belge Linki',
          ogrenciNo: widget.kullanici.ogrenciNo,
        );
        await _basvuruService.basvuruOlustur(yeni);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duzenlemeModu = widget.mevcutBasvuru != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(duzenlemeModu ? 'Başvuruyu Düzenle' : 'Yeni Başvuru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Evrak Türü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _seciliEvrakTuru,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _evrakTurleri
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _seciliEvrakTuru = v!),
              ),
              if (_seciliEvrakTuru == 'Diğer') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _digerEvrakController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Evrak türünü yazınız...',
                    prefixIcon: Icon(Icons.edit, color: Colors.indigo),
                  ),
                  validator: (v) {
                    if (_seciliEvrakTuru == 'Diğer' && (v == null || v.trim().isEmpty)) {
                      return 'Evrak türünü giriniz';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),
              const Text('Danışman E-postası', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _danismanEmailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'danisman@selcuk.edu.tr',
                  prefixIcon: Icon(Icons.person_pin),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Danışman e-postası giriniz';
                  if (!v.contains('@')) return 'Geçerli e-posta giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Açıklama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aciklamaController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Talebinizi açıklayınız...',
                ),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Açıklama giriniz' : null,
              ),
              const SizedBox(height: 20),

              // Belge linki alanı
              const Text('Belge Linki (İsteğe Bağlı)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text(
                'Belgenizi Google Drive, OneDrive vb. yükleyip paylaşım linkini buraya yapıştırın.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dosyaLinkController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'https://drive.google.com/...',
                  prefixIcon: Icon(Icons.link, color: Colors.indigo),
                ),
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v != null && v.isNotEmpty && !v.startsWith('http')) {
                    return 'Geçerli bir link giriniz (http ile başlamalı)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _yukleniyor ? null : _kaydet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: _yukleniyor
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        duzenlemeModu ? 'Güncelle' : 'Başvuru Gönder',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
