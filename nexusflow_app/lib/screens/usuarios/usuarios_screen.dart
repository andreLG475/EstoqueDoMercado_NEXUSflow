import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../models/profile.dart';
import '../../models/role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/users_provider.dart';

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Profile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: Text(
          'Tem certeza que deseja excluir "${user.name}"? Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(usersControllerProvider).delete(user.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final currentProfile = ref.watch(authProvider).valueOrNull;
    // Regra de autorização (também aplicada no backend, que é a fonte de
    // verdade): só o Gerente Geral vê e aciona a exclusão de usuários.
    final canDelete = currentProfile?.role == Role.gerenteGeral;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuários',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Gerencie as contas de acesso ao sistema',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.push('/usuarios/novo'),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Novo Usuário'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('Nenhum usuário cadastrado'));
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(usersListProvider.future),
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelf = user.id == currentProfile?.id;
                      return ListTile(
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${user.email} · ${user.role.label}'),
                        trailing: canDelete
                            ? IconButton(
                                tooltip:
                                    isSelf ? 'Você não pode excluir seu próprio usuário' : 'Excluir usuário',
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: isSelf
                                      ? Theme.of(context).disabledColor
                                      : Theme.of(context).colorScheme.error,
                                ),
                                onPressed: isSelf ? null : () => _confirmDelete(context, ref, user),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
