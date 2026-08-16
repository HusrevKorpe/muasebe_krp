import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/metin/metinler.dart';

/// Alt sekmeleri taşıyan kabuk: Kişiler · Ürünler · Ayarlar.
///
/// Her sekme kendi gezinme yığınını korur — bir kişinin sayfasındayken Ürünler'e
/// geçip geri dönünce aynı yerde kalınır (`StatefulShellRoute.indexedStack`).
///
/// Kişi sayfası, giriş formları ve hesap dökümü bu kabuğun **dışında** kalıyor:
/// onlar kök gezinmeye açılıp sekme çubuğunu tamamen örter. Kişi sayfasının
/// kendi alt düğmeleri var, iki çubuk alt alta gelmemeli.
class Kabuk extends StatelessWidget {
  const Kabuk({required this.gezinme, super.key});

  final StatefulNavigationShell gezinme;

  @override
  Widget build(BuildContext context) {
    final sema = Theme.of(context).colorScheme;

    return Scaffold(
      body: gezinme,
      // Çubuğun zemini kartlarla aynı beyaz; krem gövdeden ayrılması için üstüne
      // saç teli kalınlığında bir çizgi çekiliyor. Gölge kullanılmadı: küçük
      // ekranda bulanık gri bir hâleye dönüşüyor (bkz. `Tema`).
      //
      // Çizgi `foreground` katmanında: arka planda çizilseydi `NavigationBar`
      // kendi zeminini onun üstüne basar ve çizgi hiç görünmezdi.
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: sema.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: gezinme.currentIndex,
          onDestinationSelected: _sekmeyeGit,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: Metinler.cariler,
            ),
            NavigationDestination(
              icon: Icon(Icons.sell_outlined),
              selectedIcon: Icon(Icons.sell),
              label: Metinler.urunler,
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Metinler.ayarlar,
            ),
          ],
        ),
      ),
    );
  }

  /// Seçili sekmeye yeniden dokunmak o sekmeyi köküne döndürür — listenin
  /// içinde kaybolan kullanıcının bilinen çıkış yolu.
  void _sekmeyeGit(int sira) =>
      gezinme.goBranch(sira, initialLocation: sira == gezinme.currentIndex);
}
