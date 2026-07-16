import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

/// Ponte entre o estado assíncrono do Riverpod e o `refreshListenable` do
/// go_router, que espera um [Listenable] tradicional.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }
}
