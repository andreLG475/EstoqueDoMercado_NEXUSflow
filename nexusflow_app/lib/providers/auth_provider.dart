import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import 'core_providers.dart';

class AuthController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final api = ref.watch(apiClientProvider);
    api.onUnauthorized = () => state = const AsyncData(null);

    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) return null;

    try {
      final data = await api.get('/api/auth/me') as Map<String, dynamic>;
      return Profile.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      await ref.read(tokenStorageProvider).clear();
      return null;
    }
  }

  /// Lança [ApiException] em caso de falha, para a tela de login exibir a
  /// mensagem de erro específica.
  Future<void> login(String email, String password) async {
    final api = ref.read(apiClientProvider);
    final data = await api.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;

    await ref.read(tokenStorageProvider).write(data['token'] as String);
    state = AsyncData(Profile.fromJson(data['user'] as Map<String, dynamic>));
  }

  Future<void> logout() async {
    final api = ref.read(apiClientProvider);
    try {
      await api.post('/api/auth/logout');
    } catch (_) {
      // Falha ao notificar o servidor não impede o logout local.
    }
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthController, Profile?>(AuthController.new);
