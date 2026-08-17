import 'package:fidancari/data/tercih/tema_repository.dart';
import 'package:fidancari/domain/tema/tema_tercihi.dart';
import 'package:fidancari/features/ayarlar/viewmodel/tema_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema anahtarının cihazla olan alışverişi.
///
/// Asıl sınanan şey ekranın rengi değil, tercihin uygulama kapanıp açılınca
/// yerinde durması: kullanıcı koyu temayı bir kez seçiyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> kapKur(Map<String, Object> baslangic) async {
    SharedPreferences.setMockInitialValues(baslangic);
    final tercihler = await SharedPreferences.getInstance();

    // Liste tipi yazılmıyor: riverpod `Override` sınıfını dışa aktarmıyor.
    final kap = ProviderContainer(
      overrides: [
        temaRepositorySaglayici.overrideWithValue(TemaRepository(tercihler)),
      ],
    );
    addTearDown(kap.dispose);

    return kap;
  }

  test('hiç seçim yapılmamışsa açık tema', () async {
    final kap = await kapKur(<String, Object>{});

    expect(kap.read(temaSaglayici), TemaTercihi.acik);
  });

  test('anahtar açılınca koyu temaya geçer', () async {
    final kap = await kapKur(<String, Object>{});

    kap.read(temaSaglayici.notifier).koyuTemaSecildi(true);

    expect(kap.read(temaSaglayici), TemaTercihi.koyu);
  });

  test('seçim cihazda kalır — sonraki açılışta koyu tema', () async {
    final kap = await kapKur(<String, Object>{});
    kap.read(temaSaglayici.notifier).koyuTemaSecildi(true);

    // Yazma future'ı beklenmiyor (bkz. TemaRepository.yaz); diskteki değeri
    // okumadan önce kuyruğun boşalmasını bekliyoruz.
    await Future<void>.delayed(Duration.zero);

    // Önbellekteki örnek atılıyor: yeni açılış gibi, değer depodan okunsun.
    // Aynı örnek üzerinden okunsaydı test yazmanın gerçekten yapıldığını
    // değil, örneğin kendi belleğini sınardı.
    SharedPreferences.resetStatic();
    final tercihler = await SharedPreferences.getInstance();
    final yeniKap = ProviderContainer(
      overrides: [
        temaRepositorySaglayici.overrideWithValue(TemaRepository(tercihler)),
      ],
    );
    addTearDown(yeniKap.dispose);

    expect(yeniKap.read(temaSaglayici), TemaTercihi.koyu);
  });

  test('koyudan açığa dönülebilir', () async {
    final kap = await kapKur(<String, Object>{'tema': 'koyu'});
    expect(kap.read(temaSaglayici), TemaTercihi.koyu);

    kap.read(temaSaglayici.notifier).koyuTemaSecildi(false);

    expect(kap.read(temaSaglayici), TemaTercihi.acik);
  });
}
