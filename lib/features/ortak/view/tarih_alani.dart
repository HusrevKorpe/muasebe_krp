import 'package:flutter/material.dart';

import '../../../core/tarih/tarih_bicimi.dart';

/// Dokununca takvim açan tarih alanı.
///
/// Takvim, uygulamanın Türkçe yerelleştirmesini kullanır; alanın kendisi
/// tarihi `17.09.2021` biçiminde gösterir (bkz. KURALLAR.md §6).
///
/// Tarih boş olamaz: işlem tarihi her zaman doludur, forma bugünle açılır.
class TarihAlani extends StatelessWidget {
  const TarihAlani({
    required this.etiket,
    required this.tarih,
    required this.onSecildi,
    this.etkin = true,
    super.key,
  });

  /// Takvimde geriye gidilebilecek en eski yıl. Muhasebe kaydı için on yıl
  /// geriye bakmak yeterli; kullanıcı yanlışlıkla 1900'e düşmesin.
  static const int _geriyeYil = 10;
  static const int _ileriyeYil = 5;

  final String etiket;
  final DateTime tarih;
  final ValueChanged<DateTime> onSecildi;
  final bool etkin;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return InkWell(
      onTap: etkin ? () => _sec(context) : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiket,
          prefixIcon: const Icon(Icons.event_outlined),
          enabled: etkin,
        ),
        child: Text(uzunTarih(tarih), style: tema.textTheme.bodyLarge),
      ),
    );
  }

  Future<void> _sec(BuildContext context) async {
    final bugun = DateTime.now();

    final secilen = await showDatePicker(
      context: context,
      initialDate: tarih,
      firstDate: DateTime(bugun.year - _geriyeYil),
      lastDate: DateTime(bugun.year + _ileriyeYil, 12, 31),
    );

    if (secilen != null) onSecildi(secilen);
  }
}
