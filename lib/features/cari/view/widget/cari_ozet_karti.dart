import 'package:flutter/material.dart';

import '../../../../app/tasarim/bas_harf_karesi.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../app/tasarim/renkler.dart';
import '../../../../app/tasarim/rozet.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/para/kurus.dart';
import '../../../../core/tarih/tarih_bicimi.dart';
import '../../../../data/cari/cari_kaydi.dart';
import '../../../../domain/cari/cari.dart';
import 'bakiye_metni.dart';

/// Kişi sayfasının başındaki kimlik satırı ve bakiye kartı.
///
/// Bakiye kartının zemini bakiyenin işaretini taşıyor: borçluysa soluk kırmızı,
/// alacaklıysa soluk yeşil, kapalıysa nötr. Rakamın rengi zaten bunu söylüyordu
/// ama sayfayı açan kişi önce rengi görüyor, sonra rakamı okuyor — zemin bu
/// sırayı doğru kuruyor (bkz. KURALLAR.md §3.4).
class CariOzetKarti extends StatelessWidget {
  const CariOzetKarti({required this.kayit, super.key});

  final CariKaydi kayit;

  @override
  Widget build(BuildContext context) {
    final cari = kayit.cari;
    final tema = Theme.of(context);
    final parlaklik = tema.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Kimlik(cari: cari),
        const SizedBox(height: Olculer.bosluk20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Olculer.bosluk20),
          decoration: BoxDecoration(
            color: _zemin(cari.bakiye, parlaklik, tema.colorScheme),
            borderRadius: Olculer.koseBuyuk,
            border: Border.all(
              color: _renk(
                cari.bakiye,
                parlaklik,
                tema.colorScheme,
              ).withValues(alpha: 0.20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                Metinler.bakiye,
                style: tema.textTheme.labelLarge?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: Olculer.bosluk8),
              BakiyeMetni(
                bakiye: cari.bakiye,
                stil: tema.textTheme.headlineMedium,
              ),
              const SizedBox(height: Olculer.bosluk4),
              Text(
                _bakiyeAciklamasi(cari),
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              if (cari.sonIslemTarihi != null) ...<Widget>[
                const SizedBox(height: Olculer.bosluk16),
                _AltNot(
                  simge: Icons.history,
                  metin:
                      '${Metinler.sonIslem}: '
                      '${kisaTarih(cari.sonIslemTarihi!)}',
                ),
              ],
              if (kayit.beklemede) ...<Widget>[
                const SizedBox(height: Olculer.bosluk12),
                _AltNot(
                  simge: Icons.cloud_upload_outlined,
                  metin: Metinler.kaydedilmediAciklama,
                  renk: tema.colorScheme.tertiary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Color _renk(Kurus bakiye, Brightness parlaklik, ColorScheme sema) {
    if (bakiye.sifirMi) return sema.onSurfaceVariant;
    return bakiye.pozitifMi
        ? Renkler.borc(parlaklik)
        : Renkler.alacak(parlaklik);
  }

  static Color _zemin(Kurus bakiye, Brightness parlaklik, ColorScheme sema) {
    if (bakiye.sifirMi) return sema.surfaceContainer;
    return bakiye.pozitifMi
        ? Renkler.borcZemini(parlaklik)
        : Renkler.alacakZemini(parlaklik);
  }

  static String _bakiyeAciklamasi(Cari cari) {
    if (cari.bakiye.sifirMi) return Metinler.bakiyeKapali;
    return cari.bakiye.pozitifMi
        ? Metinler.bakiyeCariBorclu
        : Metinler.bakiyeIsletmeBorclu;
  }
}

/// Baş harf karesi, ad, firma adı ve rozetler (fidancı, listeden kaldırıldı).
class _Kimlik extends StatelessWidget {
  const _Kimlik({required this.cari});

  final Cari cari;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Row(
      children: <Widget>[
        BasHarfKaresi(ad: cari.ad, cap: 56),
        const SizedBox(width: Olculer.bosluk16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(cari.ad, style: tema.textTheme.titleLarge),
              // Grup yalnızca fidancıda yazılıyor: müşteri varsayılan, her
              // sayfaya "Müşteri" basmak bilgi vermez. "Listeden kaldırıldı"
              // ise mutlaka: kaldırılmış kişinin sayfası ötekinden ayırt
              // edilemiyordu, oysa o kişi hiçbir listede görünmüyor.
              if (cari.grup.fidanciMi || !cari.aktif) ...<Widget>[
                const SizedBox(height: Olculer.bosluk8),
                Wrap(
                  spacing: Olculer.bosluk8,
                  runSpacing: Olculer.bosluk4,
                  children: <Widget>[
                    if (cari.grup.fidanciMi)
                      Rozet(
                        metin: Metinler.cariGrubuFidanci,
                        renk: tema.colorScheme.onSurfaceVariant,
                        stil: tema.textTheme.labelSmall,
                        kalin: false,
                      ),
                    if (!cari.aktif)
                      Rozet(
                        metin: Metinler.cariKaldirildi,
                        renk: tema.colorScheme.error,
                        simge: Icons.person_off_outlined,
                        stil: tema.textTheme.labelSmall,
                        kalin: false,
                      ),
                  ],
                ),
              ],
              if (cari.altBaslik != null) ...<Widget>[
                const SizedBox(height: Olculer.bosluk4),
                Text(
                  cari.altBaslik!,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Bakiye kartının altındaki küçük not satırı.
class _AltNot extends StatelessWidget {
  const _AltNot({required this.simge, required this.metin, this.renk});

  final IconData simge;
  final String metin;
  final Color? renk;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tonu = renk ?? tema.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(simge, size: 15, color: tonu),
        const SizedBox(width: Olculer.bosluk8),
        Expanded(
          child: Text(
            metin,
            style: tema.textTheme.bodySmall?.copyWith(color: tonu),
          ),
        ),
      ],
    );
  }
}
