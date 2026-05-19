import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/kullanici_model.dart';
import '../services/basvuru_service.dart';

class ArsivScreen extends StatelessWidget {
  final KullaniciModel kullanici;

  const ArsivScreen({super.key, required this.kullanici});

  @override
  Widget build(BuildContext context) {
    final basvuruService = BasvuruService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[700],
        foregroundColor: Colors.white,
        title: const Text('Arşiv'),
      ),
      body: StreamBuilder(
        stream: kullanici.rol == 'danisman'
            ? basvuruService.danismanArsivBasvurular(kullanici.email)
            : basvuruService.arsivBasvurular(kullanici.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final liste = snapshot.data ?? [];
          if (liste.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Arşivde başvuru yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final b = liste[index];
              final tarihStr = DateFormat('dd.MM.yyyy HH:mm').format(b.tarih);
              return Card(
                color: Colors.grey[100],
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.archive, color: Colors.white),
                  ),
                  title: Text(b.evrakTuru, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$tarihStr\n${b.aciklama}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
