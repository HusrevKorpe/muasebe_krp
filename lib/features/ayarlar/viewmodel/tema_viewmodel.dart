import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/tercih/tema_repository.dart';
import '../../../domain/tema/tema_tercihi.dart';

/// Seçili tema. Ayarlardaki anahtar bunu değiştirir, `FidanCariUygulamasi`
/// bunu izler.
///
/// Sağlayıcı otomatik atılmıyor: tema uygulamanın kökünde izleniyor ve ekran
/// değiştikçe kurulup yıkılmamalı.
class TemaViewModel extends Notifier<TemaTercihi> {
  @override
  TemaTercihi build() => ref.read(temaRepositorySaglayici).oku();

  void koyuTemaSecildi(bool koyu) {
    _uygula(koyu ? TemaTercihi.koyu : TemaTercihi.acik);
  }

  void _uygula(TemaTercihi tercih) {
    if (tercih == state) return;

    // Önce ekran, sonra disk: yazma beklenmiyor (bkz. [TemaRepository.yaz]).
    state = tercih;
    ref.read(temaRepositorySaglayici).yaz(tercih);
  }
}

final temaSaglayici = NotifierProvider<TemaViewModel, TemaTercihi>(
  TemaViewModel.new,
);
