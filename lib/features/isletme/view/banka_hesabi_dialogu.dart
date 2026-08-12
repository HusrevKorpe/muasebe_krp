import 'package:flutter/material.dart';

import '../../../core/metin/metinler.dart';
import '../../../domain/isletme/banka_hesabi.dart';
import '../../../domain/isletme/iban.dart';
import '../../../domain/isletme/isletme_dogrulama.dart';

/// Banka hesabı ekleme penceresi.
///
/// Kaydedilen hesabı döner; kullanıcı vazgeçerse `null`. Hesap listesi işletme
/// belgesinin içinde yaşadığı için burada Firestore'a yazma yapılmaz — kayıt
/// işletme profiliyle birlikte gönderilir.
class BankaHesabiDialogu extends StatefulWidget {
  const BankaHesabiDialogu({super.key});

  @override
  State<BankaHesabiDialogu> createState() => _BankaHesabiDialoguDurumu();
}

class _BankaHesabiDialoguDurumu extends State<BankaHesabiDialogu> {
  final _formAnahtari = GlobalKey<FormState>();
  final _bankaKontrolcu = TextEditingController();
  final _ibanKontrolcu = TextEditingController();
  final _hesapNoKontrolcu = TextEditingController();

  String _paraBirimi = BankaHesabi.varsayilanParaBirimi;

  @override
  void dispose() {
    _bankaKontrolcu.dispose();
    _ibanKontrolcu.dispose();
    _hesapNoKontrolcu.dispose();
    super.dispose();
  }

  void _kaydet() {
    if (!_formAnahtari.currentState!.validate()) return;

    final hesapNo = _hesapNoKontrolcu.text.trim();
    Navigator.of(context).pop(
      BankaHesabi(
        banka: _bankaKontrolcu.text.trim(),
        // Normalize edilmiş biçim saklanır; ekranda gruplanarak gösterilir.
        iban: Iban.normalize(_ibanKontrolcu.text),
        hesapNo: hesapNo.isEmpty ? null : hesapNo,
        paraBirimi: _paraBirimi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Metinler.bankaHesabiEkle),
      content: SingleChildScrollView(
        child: Form(
          key: _formAnahtari,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _bankaKontrolcu,
                textCapitalization: TextCapitalization.words,
                validator: IsletmeDogrulama.bankaAdi,
                decoration: const InputDecoration(
                  labelText: Metinler.bankaAdi,
                  hintText: Metinler.bankaAdiIpucu,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ibanKontrolcu,
                textCapitalization: TextCapitalization.characters,
                validator: IsletmeDogrulama.iban,
                decoration: const InputDecoration(
                  labelText: Metinler.iban,
                  hintText: 'TR00 0000 0000 0000 0000 0000 00',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hesapNoKontrolcu,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText:
                      '${Metinler.hesapNo} (${Metinler.istegeBagli})',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paraBirimi,
                decoration: const InputDecoration(
                  labelText: Metinler.paraBirimi,
                ),
                items: [
                  for (final birim in BankaHesabi.paraBirimleri)
                    DropdownMenuItem<String>(value: birim, child: Text(birim)),
                ],
                onChanged: (secilen) =>
                    setState(() => _paraBirimi = secilen ?? _paraBirimi),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Metinler.vazgec),
        ),
        FilledButton(onPressed: _kaydet, child: const Text(Metinler.ekle)),
      ],
    );
  }
}
