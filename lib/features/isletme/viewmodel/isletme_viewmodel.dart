import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/isletme/isletme_repository.dart';
import '../../../domain/isletme/isletme.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';

/// İşletme profilinin kaydedilmesi.
///
/// Hem kurulum ekranı hem profil düzenleme ekranı bu ViewModel'i kullanır;
/// ikisi de aynı belgeye yazar, tek fark ilk yazmada belgenin oluşturulması.
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
