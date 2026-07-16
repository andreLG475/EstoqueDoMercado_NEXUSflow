import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import 'core_providers.dart';

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
  }
}

final usersControllerProvider = Provider<UsersController>((ref) => UsersController(ref));
