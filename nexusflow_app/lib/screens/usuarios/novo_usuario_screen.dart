import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../models/role.dart';
import '../../providers/users_provider.dart';

class NovoUsuarioScreen extends ConsumerStatefulWidget {
  const NovoUsuarioScreen({super.key, this.isPublic = false});

  final bool isPublic;

  @override
  ConsumerState<NovoUsuarioScreen> createState() => _NovoUsuarioScreenState();
}

class _NovoUsuarioScreenState extends ConsumerState<NovoUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  Role _role = Role.atendente;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(usersControllerProvider).create(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _role.value,
          );
      if (!mounted) return;

      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmController.clear();
      setState(() => _role = Role.atendente);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso')),
      );

      if (widget.isPublic) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) context.go('/login');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isPublic ? 'Criar conta' : 'Novo Usuário',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            widget.isPublic
                ? 'Crie sua conta de acesso ao sistema'
                : 'Cadastre uma nova conta de acesso ao sistema',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(labelText: 'Nome'),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty) ? 'Informe o nome' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(labelText: 'E-mail'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
                                if (!value.contains('@')) return 'E-mail inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Role>(
                              initialValue: _role,
                              decoration: const InputDecoration(labelText: 'Papel'),
                              items: [
                                for (final role in Role.values)
                                  DropdownMenuItem(value: role, child: Text(role.label)),
                              ],
                              onChanged: (value) => setState(() => _role = value ?? _role),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: const InputDecoration(labelText: 'Senha'),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Informe a senha';
                                if (value.length < 6) return 'Mínimo de 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: const InputDecoration(labelText: 'Confirmar senha'),
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) =>
                                  value != _passwordController.text ? 'As senhas não coincidem' : null,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Cadastrar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
