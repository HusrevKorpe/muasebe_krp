import 'package:flutter/material.dart';

import '../../../../app/tema.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/para/kurus.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../domain/cari/acik_hesap_ozeti.dart';

/// Açık hesaplar sekmesinin başındaki toplam satırı.
///
/// Renkler listedeki bakiye renkleriyle aynı: alacak kırmızı, borç yeşil
/// (`BakiyeMetni`). Aynı tutarın iki yerde iki renkte görünmemesi için ölçüt
/// tek — bakiyenin işareti.
class AcikHesapOzetiKarti extends StatelessWidget {
  const AcikHesapOzetiKarti({
    required this.ozet,
    this.eksikVar = false,
    super.key,
  });

  final AcikHesapOzeti ozet;

  /// Listenin devamı henüz yüklenmedi mi. Toplam yalnızca yüklenmiş kayıtları
  /// kapsadığı için bu durumda kullanıcıya söyleniyor.
  final bool eksikVar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: tema.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Metinler.acikHesapAdedi(ozet.adet),
            style: tema.textTheme.labelLarge?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Toplam(
                  baslik: Metinler.toplamAlacak,
                  tutar: ozet.alacak,
                  renk: Tema.borcRengi(tema.brightness),
                ),
              ),
              // Borç kalemi yalnızca varsa yer kaplar; her satırda "0,00 ₺"
              // görmek gereksiz gürültü.
              if (!ozet.borc.sifirMi)
                Expanded(
                  child: _Toplam(
                    baslik: Metinler.toplamBorc,
                    tutar: ozet.borc,
                    renk: Tema.alacakRengi(tema.brightness),
                  ),
                ),
            ],
          ),
          if (eksikVar) ...[
            const SizedBox(height: 8),
            Text(
              Metinler.acikHesapKismiToplam,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tek bir toplam sütunu: üstte etiket, altta tutar.
class _Toplam extends StatelessWidget {
  const _Toplam({
    required this.baslik,
    required this.tutar,
    required this.renk,
  });

  final String baslik;
  final Kurus tutar;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          tutar.bicimli,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tema.textTheme.titleMedium?.copyWith(
            color: renk,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
