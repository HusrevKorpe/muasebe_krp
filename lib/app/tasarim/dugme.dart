import 'package:flutter/material.dart';

import 'dugme_turu.dart';
import 'olculer.dart';

/// Uygulamadaki metinli düğmelerin tamamı.
///
/// Önceden her ekran kendi düğmesini kuruyordu: bir yerde `FilledButton`, öbür
/// yerde `OutlinedButton.icon`, kaydetme düğmelerinin her birinde elle yazılmış
/// yükleniyor göstergesi. Aynı iş üç ekranda üç farklı yükseklikte görünüyordu.
/// Artık tek giriş noktası burası; görünüm [DugmeTuru] ile seçiliyor, ölçüler
/// temadan geliyor (bkz. `TemaDugmeleri`).
///
/// Altında yine Material düğmeleri var — `FilledButton`, `OutlinedButton`,
/// `TextButton`. Kendi çizdiğimiz bir yüzey değil: dokunma dalgası, klavye
/// odağı ve erişilebilirlik ağacı hazır geliyor.
///
/// ```dart
/// Dugme.birincil(metin: Metinler.kaydet, onBasildi: _kaydet, yukleniyor: true)
/// Dugme.ikincil(metin: Metinler.urundenSec, simge: Icons.sell_outlined, ...)
/// Dugme.sade(metin: Metinler.vazgec, onBasildi: () => Navigator.pop(context))
/// ```
class Dugme extends StatelessWidget {
  const Dugme({
    required this.metin,
    required this.onBasildi,
    this.tur = DugmeTuru.birincil,
    this.simge,
    this.genis = false,
    this.yukleniyor = false,
    this.kompakt = false,
    super.key,
  });

  /// Ekranın asıl eylemi. Dolu zemin, ana renk.
  const Dugme.birincil({
    required this.metin,
    required this.onBasildi,
    this.simge,
    this.genis = false,
    this.yukleniyor = false,
    this.kompakt = false,
    super.key,
  }) : tur = DugmeTuru.birincil;

  /// Yardımcı eylem. Çerçeveli, zeminsiz.
  const Dugme.ikincil({
    required this.metin,
    required this.onBasildi,
    this.simge,
    this.genis = false,
    this.yukleniyor = false,
    this.kompakt = false,
    super.key,
  }) : tur = DugmeTuru.ikincil;

  /// Taşıyıcı olmayan eylem. Yalnızca metin.
  const Dugme.sade({
    required this.metin,
    required this.onBasildi,
    this.simge,
    this.genis = false,
    this.yukleniyor = false,
    this.kompakt = false,
    super.key,
  }) : tur = DugmeTuru.sade;

  /// Yıkıcı eylemin onayı. Dolu zemin, hata rengi.
  const Dugme.tehlikeli({
    required this.metin,
    required this.onBasildi,
    this.simge,
    this.genis = false,
    this.yukleniyor = false,
    this.kompakt = false,
    super.key,
  }) : tur = DugmeTuru.tehlikeli;

  /// Yıkıcı eylemi *açan* düğme. Zeminsiz, hata renginde metin.
  const Dugme.tehlikeliSade({
    required this.metin,
    required this.onBasildi,
    this.simge,
    this.genis = false,
    this.yukleniyor = false,
    this.kompakt = false,
    super.key,
  }) : tur = DugmeTuru.tehlikeliSade;

  final String metin;

  /// `null` ise düğme pasiftir. [yukleniyor] doğruyken de basılamaz.
  final VoidCallback? onBasildi;

  final DugmeTuru tur;
  final IconData? simge;

  /// Satırın tamamını kaplasın mı. Kaydetme düğmeleri zaten `ListView` içinde
  /// tam genişlikte çiziliyor; bu bayrak `Row` ve `Column` içindekiler için.
  final bool genis;

  /// Metnin yerine dönen gösterge çizilir ve düğme kilitlenir.
  ///
  /// Kaydetme yolunun ağa bağlanmadığı yerlerde bu gösterge bir an bile
  /// görünmez (bkz. KURALLAR.md §4.4) — yine de kilit gerekli: çift dokunuş
  /// aynı kaydı iki kez göndermemeli.
  final bool yukleniyor;

  /// Alçak biçim: 52 yerine 44 birim yükseklik, dar iç boşluk.
  ///
  /// Kutu (dialog) eylemleri için: kutunun altında iki üç düğme yan yana
  /// duruyor ve tam boy düğmeler kutuyu ekranın yarısına çıkarıyor. Form
  /// düğmeleri tam boy kalır — onlara eldivenle basılıyor.
  final bool kompakt;

  @override
  Widget build(BuildContext context) {
    final dugme = _dugme(Theme.of(context).colorScheme);
    return genis ? SizedBox(width: double.infinity, child: dugme) : dugme;
  }

  Widget _dugme(ColorScheme sema) {
    final basilinca = yukleniyor ? null : onBasildi;
    final icerik = _icerik(sema);
    final stil = _stil(sema);

    return switch (tur) {
      DugmeTuru.birincil => simge == null || yukleniyor
          ? FilledButton(onPressed: basilinca, style: stil, child: icerik)
          : FilledButton.icon(
              onPressed: basilinca,
              style: stil,
              icon: Icon(simge),
              label: icerik,
            ),
      DugmeTuru.tehlikeli => simge == null || yukleniyor
          ? FilledButton(onPressed: basilinca, style: stil, child: icerik)
          : FilledButton.icon(
              onPressed: basilinca,
              style: stil,
              icon: Icon(simge),
              label: icerik,
            ),
      DugmeTuru.ikincil => simge == null || yukleniyor
          ? OutlinedButton(onPressed: basilinca, style: stil, child: icerik)
          : OutlinedButton.icon(
              onPressed: basilinca,
              style: stil,
              icon: Icon(simge),
              label: icerik,
            ),
      DugmeTuru.sade || DugmeTuru.tehlikeliSade => simge == null || yukleniyor
          ? TextButton(onPressed: basilinca, style: stil, child: icerik)
          : TextButton.icon(
              onPressed: basilinca,
              style: stil,
              icon: Icon(simge),
              label: icerik,
            ),
    };
  }

  /// Türün ve [kompakt] bayrağının gerektirdiği düzeltmeler. Geri kalan her şey
  /// temadan geliyor; burada yalnızca *fark* yazılıyor.
  ButtonStyle? _stil(ColorScheme sema) {
    final alcak = kompakt
        ? const Size(0, Olculer.kucukDugmeYuksekligi)
        : null;

    return switch (tur) {
      DugmeTuru.birincil => kompakt
          ? FilledButton.styleFrom(
              minimumSize: alcak,
              padding: const EdgeInsets.symmetric(
                horizontal: Olculer.bosluk20,
              ),
            )
          : null,
      DugmeTuru.tehlikeli => FilledButton.styleFrom(
        backgroundColor: sema.error,
        foregroundColor: sema.onError,
        minimumSize:
            alcak ?? const Size.fromHeight(Olculer.dugmeYuksekligi),
        padding: const EdgeInsets.symmetric(horizontal: Olculer.bosluk20),
      ),
      DugmeTuru.ikincil => kompakt
          ? OutlinedButton.styleFrom(minimumSize: alcak)
          : null,
      DugmeTuru.sade => kompakt
          ? TextButton.styleFrom(minimumSize: alcak)
          : null,
      DugmeTuru.tehlikeliSade => TextButton.styleFrom(
        foregroundColor: sema.error,
        minimumSize: alcak,
      ),
    };
  }

  /// Yükleniyor göstergesi düğmenin kendi ön rengini alır: dolu düğmede beyaz,
  /// çerçevelide ana renk. Sabit bir renk verilseydi biri görünmezdi.
  Widget _icerik(ColorScheme sema) {
    if (!yukleniyor) return Text(metin);

    return SizedBox.square(
      dimension: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: switch (tur) {
          DugmeTuru.birincil => sema.onPrimary,
          DugmeTuru.tehlikeli => sema.onError,
          DugmeTuru.tehlikeliSade => sema.error,
          DugmeTuru.ikincil || DugmeTuru.sade => sema.primary,
        },
      ),
    );
  }
}
