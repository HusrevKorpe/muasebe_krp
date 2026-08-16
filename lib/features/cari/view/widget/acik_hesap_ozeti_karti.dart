import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../app/tasarim/renkler.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/para/kurus.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../domain/cari/acik_hesap_ozeti.dart';

/// Açık hesaplar sekmesinin başındaki toplam kartı.
///
/// Renkler listedeki bakiye renkleriyle aynı: alacak kırmızı, borç yeşil
/// (`BakiyeMetni`). Aynı tutarın iki yerde iki renkte görünmemesi için ölçüt
/// tek — bakiyenin işareti.
///
/// Şerit değil kart: sekmenin en üstünde tam genişlikte bir renk bloğu, altında
/// gelen liste satırlarıyla aynı hizada durunca başlık mı satır mı belli
/// olmuyordu. Kart, kenar boşluğuyla listeden ayrılıyor.
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
    final borcVar = !ozet.borc.sifirMi;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Olculer.sayfaKenari,
        Olculer.bosluk12,
        Olculer.sayfaKenari,
        Olculer.bosluk8,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Olculer.bosluk16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Olculer.bosluk8),
                  Text(
                    Metinler.acikHesapAdedi(ozet.adet),
                    style: tema.textTheme.labelLarge?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Olculer.bosluk16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: _Toplam(
                      baslik: Metinler.toplamAlacak,
                      tutar: ozet.alacak,
                      renk: Renkler.borc(tema.brightness),
                    ),
                  ),
                  // Borç kalemi yalnızca varsa yer kaplar; her satırda "0,00 ₺"
                  // görmek gereksiz gürültü.
                  if (borcVar) ...<Widget>[
                    const _DikeyCizgi(),
                    Expanded(
                      child: _Toplam(
                        baslik: Metinler.toplamBorc,
                        tutar: ozet.borc,
                        renk: Renkler.alacak(tema.brightness),
                      ),
                    ),
                  ],
                ],
              ),
              if (eksikVar) ...<Widget>[
                const SizedBox(height: Olculer.bosluk12),
                Text(
                  Metinler.acikHesapKismiToplam,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
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
      children: <Widget>[
        Text(
          baslik,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Olculer.bosluk4),
        Text(
          tutar.bicimli,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tema.textTheme.titleLarge?.copyWith(color: renk),
        ),
      ],
    );
  }
}

/// İki toplamı ayıran ince çizgi.
class _DikeyCizgi extends StatelessWidget {
  const _DikeyCizgi();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: Olculer.bosluk16),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
