import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/log/log.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/islem/islem_kaydi.dart';
import '../../../data/islem/islem_repository.dart';
import 'islem_listesi_durumu.dart';

/// Bir carinin işlem listesi — sayfalama.
///
/// Yürüyen bakiye burada hesaplanmaz; liste yalnızca kayıtları taşır. Bakiye
/// kolonu `islemDokumuSaglayici` içinde, carinin önbelleklenmiş bakiyesiyle
/// birleştirilerek üretilir. Bu ayrım sayesinde carinin adı değiştiğinde
/// işlem listesi baştan çekilmez.
class IslemListesiViewModel extends AsyncNotifier<IslemListesiDurumu> {
  IslemListesiViewModel(this.cariId);

  final String cariId;

  @override
  Future<IslemListesiDurumu> build() => _ilkSayfa();

  Future<void> yenile() async {
    state = const AsyncValue<IslemListesiDurumu>.loading();
    state = await AsyncValue.guard(_ilkSayfa);
  }

  /// Sonraki (daha eski) sayfayı yükleyip listenin sonuna ekler.
  ///
  /// İlk yüklemeden farklı olarak durum `loading`'e düşmez: eldeki kayıtlar
  /// ekranda kalır, altta yalnızca bir gösterge döner.
  Future<void> dahaYukle() async {
    final mevcut = state.value;
    if (mevcut == null ||
        !mevcut.dahaVar ||
        mevcut.dahaYukleniyor ||
        mevcut.bosMu) {
      return;
    }

    state = AsyncValue<IslemListesiDurumu>.data(
      mevcut.kopyala(dahaYukleniyor: true, hatayiTemizle: true),
    );

    try {
      final sayfa = await ref
          .read(islemRepositorySaglayici)
          .listele(cariId: cariId, sonrasindan: mevcut.kayitlar.last);

      state = AsyncValue<IslemListesiDurumu>.data(
        mevcut.kopyala(
          kayitlar: <IslemKaydi>[
            ...mevcut.kayitlar,
            ...sayfa.kayitlar,
          ].toList(growable: false),
          dahaVar: sayfa.dahaVar,
          dahaYukleniyor: false,
          hatayiTemizle: true,
        ),
      );
    } on UygulamaHatasi catch (hata) {
      Log.uyari('Sonraki işlem sayfası yüklenemedi: ${hata.mesaj}');
      state = AsyncValue<IslemListesiDurumu>.data(
        mevcut.kopyala(
          dahaYukleniyor: false,
          sayfaHatasi: Metinler.sonrakiIslemlerYuklenemedi,
        ),
      );
    }
  }

  Future<IslemListesiDurumu> _ilkSayfa() async {
    final sayfa = await ref
        .read(islemRepositorySaglayici)
        .listele(cariId: cariId);

    return IslemListesiDurumu(
      kayitlar: sayfa.kayitlar,
      dahaVar: sayfa.dahaVar,
    );
  }
}

final islemListesiViewModelSaglayici =
    AsyncNotifierProvider.family<
      IslemListesiViewModel,
      IslemListesiDurumu,
      String
    >(IslemListesiViewModel.new, isAutoDispose: true);
