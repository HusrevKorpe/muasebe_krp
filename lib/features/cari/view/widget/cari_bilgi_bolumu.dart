import 'package:flutter/material.dart';

import '../../../../app/tasarim/bolum_basligi.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../domain/cari/cari.dart';

/// Kişi sayfasındaki iletişim ve not bölümleri.
///
/// Boş alan satır açmaz: telefonu girilmemiş bir kişide "Telefon —" yazan bir
/// satır bilgi değil, gürültü. Hiçbiri doluysa bölüm hiç çizilmez.
class CariBilgiBolumu extends StatelessWidget {
  const CariBilgiBolumu({required this.cari, super.key});

  final Cari cari;

  @override
  Widget build(BuildContext context) {
    final iletisim = <Widget>[
      if (cari.telefon != null)
        _BilgiSatiri(
          simge: Icons.phone_outlined,
          etiket: Metinler.telefon,
          deger: cari.telefon!,
        ),
      if (cari.sehir != null)
        _BilgiSatiri(
          simge: Icons.location_city_outlined,
          etiket: Metinler.sehir,
          deger: cari.sehir!,
        ),
      if (cari.adres != null)
        _BilgiSatiri(
          simge: Icons.home_outlined,
          etiket: Metinler.adres,
          deger: cari.adres!,
        ),
    ];

    if (iletisim.isEmpty && cari.notlar == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: Olculer.bosluk24),
        if (iletisim.isNotEmpty) ...<Widget>[
          BolumBasligi(baslik: Metinler.iletisim),
          Card(child: Column(children: _cizgiliDiz(iletisim))),
        ],
        if (cari.notlar != null) ...<Widget>[
          if (iletisim.isNotEmpty) const SizedBox(height: Olculer.bosluk24),
          BolumBasligi(baslik: Metinler.notlar),
          Card(
            child: _BilgiSatiri(
              simge: Icons.notes_outlined,
              etiket: Metinler.notlar,
              deger: cari.notlar!,
            ),
          ),
        ],
      ],
    );
  }

  /// Satırların arasına ayıraç serper — sonuncunun altına çizgi çekmez.
  static List<Widget> _cizgiliDiz(List<Widget> satirlar) {
    final cikti = <Widget>[];
    for (var sira = 0; sira < satirlar.length; sira++) {
      cikti.add(satirlar[sira]);
      if (sira != satirlar.length - 1) {
        cikti.add(const Divider(indent: Olculer.bosluk16 + 40));
      }
    }
    return cikti;
  }
}

/// Kart içindeki tek bilgi satırı: solda simge, üstte etiket, altta değer.
class _BilgiSatiri extends StatelessWidget {
  const _BilgiSatiri({
    required this.simge,
    required this.etiket,
    required this.deger,
  });

  final IconData simge;
  final String etiket;
  final String deger;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(Olculer.bosluk16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(simge, size: 20, color: tema.colorScheme.onSurfaceVariant),
          const SizedBox(width: Olculer.bosluk16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  etiket,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Olculer.bosluk4),
                Text(deger, style: tema.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
