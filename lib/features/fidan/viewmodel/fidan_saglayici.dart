import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/fidan/fidan_kaydi.dart';
import '../../../data/fidan/fidan_repository.dart';
import '../../../domain/fidan/fidan_oneri_alani.dart';

/// Tek bir fidanı canlı izler.
///
/// Düzenleme ekranı listeden gelen kopyayı değil bu akışı okur: kayıt
/// güncellenip geri dönüldüğünde ekran kendiliğinden tazelenir. Belge yoksa
/// `null` yayar.
final fidanSaglayici = StreamProvider.family<FidanKaydi?, String>((
  ref,
  fidanId,
) {
  return ref.watch(fidanRepositorySaglayici).izle(fidanId);
}, isAutoDispose: true);

/// Öneri sorgusunun kimliği: hangi alan, hangi öntakı.
typedef FidanOneriIstegi = ({FidanOneriAlani alan, String onek});

/// Tür ve anaç alanlarına geçmiş girişlerden öneri getirir.
///
/// Form bu sağlayıcıyı **yazılan metnin tamamıyla değil, ilk harfiyle** çağırır:
/// "E", "El", "Elm", "Elma" tek bir sorguya düşer ve daralan eşleşme ekranda
/// yerel olarak süzülür. Aksi hâlde her tuşa basış bir Firestore okuması olurdu
/// (KURALLAR.md §4.3).
final fidanOnerileriSaglayici =
    FutureProvider.family<List<String>, FidanOneriIstegi>((ref, istek) {
      return ref
          .watch(fidanRepositorySaglayici)
          .oneriler(alan: istek.alan, onek: istek.onek);
    }, isAutoDispose: true);
