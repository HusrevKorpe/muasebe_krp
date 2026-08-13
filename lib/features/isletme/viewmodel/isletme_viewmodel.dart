import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/isletme/isletme_repository.dart';
import '../../../domain/isletme/isletme.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';

/// İşletme profilinin kaydedilmesi.
///
/// Profil belgesi ilk kayıtta oluşur, sonrakilerde güncellenir; ikisi de aynı
/// çağrı (bkz. `IsletmeRepository.kaydet` — `merge`).
class IsletmeViewModel extends IslemViewModel {
  Future<bool> kaydet(Isletme isletme) => calistir(
    () => ref.read(isletmeRepositorySaglayici).kaydet(isletme),
    etiket: 'İşletme kaydı',
  );
}

final isletmeViewModelSaglayici = AsyncNotifierProvider<IsletmeViewModel, void>(
  IsletmeViewModel.new,
  isAutoDispose: true,
);
