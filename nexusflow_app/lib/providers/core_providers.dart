import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/theme_mode_storage.dart';
import '../core/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());

final themeModeStorageProvider = Provider<ThemeModeStorage>((ref) => SecureThemeModeStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return DioApiClient(ref.watch(tokenStorageProvider));
});
