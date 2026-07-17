import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/profile.dart';
import 'core_providers.dart';

final usersListProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/api/usuarios') as List<dynamic>;
  return data.map((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
});

class UsersController {
  UsersController(this._ref);

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> create({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await _api.post(
      '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password, 'role': role},
    );
    _ref.invalidate(usersListProvider);
  }

  Future<void> delete(String id) async {
    await _api.delete('/api/usuarios/$id');
    _ref.invalidate(usersListProvider);
  }
}

final usersControllerProvider = Provider<UsersController>((ref) => UsersController(ref));
