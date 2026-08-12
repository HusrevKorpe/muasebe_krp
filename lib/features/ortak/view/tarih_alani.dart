import 'package:flutter/material.dart';

import '../../../core/metin/metinler.dart';
import '../../../core/tarih/tarih_bicimi.dart';

/// Dokununca takvim açan tarih alanı.
///
/// Takvim, uygulamanın Türkçe yerelleştirmesini kullanır; alanın kendisi
/// tarihi `17.09.2021` biçiminde gösterir (bkz. KURALLAR.md §6).
class TarihAlani extends StatelessWidget {
  const TarihAlani({
    required this.etiket,
    required this.tarih,
    required this.onSecildi,
    this.simge = Icons.event_outlined,
    this.bosMetin,
    this.enErken,
    this.etkin = true,
    this.onTemizlendi,
    super.key,
  });

  /// Takvimde geriye gidilebilecek en eski yıl. Muhasebe kaydı için on yıl
  /// geriye bakmak yeterli; kullanıcı yanlışlıkla 1900'e düşmesin.
  static const int _geriyeYil = 10;
  static const int _ileriyeYil = 5;

  final String etiket;
  final DateTime? tarih;
  final ValueChanged<DateTime> onSecildi;
  final IconData simge;

  /// Tarih boşken gösterilen metin.
  final String? bosMetin;

  /// Seçilebilecek en erken tarih — vade, işlem tarihinden önce olamaz.
  final DateTime? enErken;

  final bool etkin;

  /// Verilirse alanın sonunda temizleme düğmesi çıkar.
  final VoidCallback? onTemizlendi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final doluMu = tarih != null;

    return InkWell(
      onTap: etkin ? () => _sec(context) : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiket,
          prefixIcon: Icon(simge),
          enabled: etkin,
          suffixIcon: doluMu && onTemizlendi != null && etkin
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: Metinler.temizle,
                  onPressed: onTemizlendi,
                )
              : null,
        ),
        child: Text(
          doluMu ? uzunTarih(tarih!) : (bosMetin ?? ''),
          style: doluMu
              ? tema.textTheme.bodyLarge
              : tema.textTheme.bodyLarge?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }

  Future<void> _sec(BuildContext context) async {
    final bugun = DateTime.now();
    final baslangic = tarih ?? enErken ?? bugun;

    final secilen = await showDatePicker(
      context: context,
      initialDate: baslangic,
      firstDate: enErken ?? DateTime(bugun.year - _geriyeYil),
      lastDate: DateTime(bugun.year + _ileriyeYil, 12, 31),
    );

    if (secilen != null) onSecildi(secilen);
  }
}
