import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../core/metin/metinler.dart';

/// Kişi listesinin başındaki sayı satırı: "128 kişi".
///
/// Kullanıcının isteği: *"kaç farklı kişi olduğunu bilelim."* Açık hesaplar
/// sekmesindeki "14 açık hesap" satırı bunu zaten yapıyordu; aynı bilgi kişi
/// listelerinde de var — orada ölçüt bakiye değil, kayıtlı kişi sayısı.
///
/// Sayı iki kaynaktan gelebiliyor. Liste sonuna kadar yüklüyse eldeki satırlar
/// sayılıyor: bedava ve kesin. Liste kesikse sunucuya toplama sorgusu gidiyor
/// (`cariSayisiSaglayici`); o da cevap veremezse — çevrimdışıyken veremez —
/// yüklenen kayıt sayısı [enAz] ile gösteriliyor: "25+ kişi". Sayının yerine
/// dönen bir gösterge koymak yerine bu yol seçildi: eldeki sayı yanlış değil,
/// yalnızca eksik.
class KisiSayisiSatiri extends StatelessWidget {
  const KisiSayisiSatiri({required this.adet, this.enAz = false, super.key});

  final int adet;

  /// Sayı yüklenmiş kayıtlardan geliyor; gerçek sayı daha büyük olabilir.
  final bool enAz;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tonu = tema.colorScheme.onSurfaceVariant;

    return Padding(
      // Üstte arama kutusunun kendi alt boşluğu var; satır ona yapışık duruyor
      // ve listeden yine bir boşlukla ayrılıyor.
      padding: const EdgeInsets.fromLTRB(
        Olculer.sayfaKenari,
        0,
        Olculer.sayfaKenari,
        Olculer.bosluk8,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.people_outline, size: 16, color: tonu),
          const SizedBox(width: Olculer.bosluk8),
          Text(
            Metinler.kisiSayisi(adet, enAz: enAz),
            style: tema.textTheme.labelLarge?.copyWith(color: tonu),
          ),
        ],
      ),
    );
  }
}
