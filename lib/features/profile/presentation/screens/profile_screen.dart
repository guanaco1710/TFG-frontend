import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/features/profile/data/models/user_profile_models.dart';
import 'package:tfg_frontend/features/profile/presentation/providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        return switch (provider.state) {
          ProfileLoadState.initial || ProfileLoadState.loading => const Center(
            child: CircularProgressIndicator(key: Key('profile_loading')),
          ),
          ProfileLoadState.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    key: const Key('profile_error'),
                    provider.errorMessage ?? 'Error al cargar el perfil',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('profile_retry_button'),
                    onPressed: provider.loadProfile,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          ProfileLoadState.loaded => _ProfileContent(profile: provider.profile!),
        };
      },
    );
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent({required this.profile});

  final UserProfile profile;

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specialtyController;

  bool _nameEditing = false;
  bool _phoneEditing = false;
  bool _specialtyEditing = false;

  bool get _anyEditing => _nameEditing || _phoneEditing || _specialtyEditing;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _specialtyController = TextEditingController(
      text: widget.profile.specialty ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  void _cancel() {
    _nameController.text = widget.profile.name;
    _phoneController.text = widget.profile.phone ?? '';
    _specialtyController.text = widget.profile.specialty ?? '';
    setState(() {
      _nameEditing = false;
      _phoneEditing = false;
      _specialtyEditing = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProfileProvider>();
    final phone = _phoneController.text.trim();
    final specialty = _specialtyController.text.trim();
    final success = await provider.updateProfile(
      name: _nameController.text.trim(),
      phone: phone.isEmpty ? null : phone,
      specialty: specialty.isEmpty ? null : specialty,
    );
    if (!mounted) return;
    if (success) {
      setState(() {
        _nameEditing = false;
        _phoneEditing = false;
        _specialtyEditing = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.saveError ?? 'Error al guardar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;
    final isInstructor = profile.role == 'INSTRUCTOR';
    final initials = profile.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              key: const Key('profile_avatar'),
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initials,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _RoleBadge(role: profile.role),
            const SizedBox(height: 32),
            _InfoCard(
              children: [
                if (!_nameEditing)
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Nombre',
                    value: _nameController.text,
                    valueKey: const Key('profile_name'),
                    pencilKey: const Key('edit_name_pencil'),
                    onEdit: () => setState(() => _nameEditing = true),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      key: const Key('edit_name_field'),
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nombre requerido'
                          : null,
                    ),
                  ),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: profile.email,
                  valueKey: const Key('profile_email'),
                ),
                const Divider(height: 1),
                if (!_phoneEditing)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: _phoneController.text.isEmpty
                        ? 'no hay teléfono agregado'
                        : _phoneController.text,
                    valueKey: const Key('profile_phone'),
                    pencilKey: const Key('edit_phone_pencil'),
                    onEdit: () => setState(() => _phoneEditing = true),
                    muted: _phoneController.text.isEmpty,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      key: const Key('edit_phone_field'),
                      controller: _phoneController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        hintText: 'no hay teléfono agregado',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                if (isInstructor) ...[
                  const Divider(height: 1),
                  if (!_specialtyEditing)
                    _InfoRow(
                      icon: Icons.star_outline,
                      label: 'Especialidad',
                      value: _specialtyController.text.isEmpty
                          ? 'sin especialidad'
                          : _specialtyController.text,
                      valueKey: const Key('profile_specialty'),
                      pencilKey: const Key('edit_specialty_pencil'),
                      onEdit: () => setState(() => _specialtyEditing = true),
                      muted: _specialtyController.text.isEmpty,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextFormField(
                        key: const Key('edit_specialty_field'),
                        controller: _specialtyController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Especialidad',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                ],
              ],
            ),
            if (_anyEditing) ...[
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: context.read<ProfileProvider>(),
                builder: (ctx, _) {
                  final saving = ctx.read<ProfileProvider>().isSaving;
                  return Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          key: const Key('edit_save_button'),
                          onPressed: saving ? null : _save,
                          child: saving
                              ? const SizedBox(
                                  key: Key('edit_saving_indicator'),
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Guardar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const Key('edit_cancel_button'),
                          onPressed: saving ? null : _cancel,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(ctx).colorScheme.error,
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'ADMIN' => ('ADMIN', Colors.red),
      'INSTRUCTOR' => ('INSTRUCTOR', Colors.blue),
      _ => ('CLIENTE', Colors.green),
    };

    return Container(
      key: const Key('profile_role_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueKey,
    this.pencilKey,
    this.onEdit,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Key? valueKey;
  final Key? pencilKey;
  final VoidCallback? onEdit;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  key: valueKey,
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted ? theme.colorScheme.onSurfaceVariant : null,
                    fontStyle: muted ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              key: pencilKey,
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
