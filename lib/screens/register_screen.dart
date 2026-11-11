import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/app_banner.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<AuthProvider>().register(
      fullName: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('¡Cuenta creada! Bienvenido a AgroSMART.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthLayout(
      title: 'Crea tu cuenta',
      subtitle: 'Guarda tus consultas y revisa tus recomendaciones cuando quieras.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Flexible(child: Text('¿Ya tienes cuenta?')),
          TextButton(
            onPressed: auth.isBusy
                ? null
                : () {
                    auth.clearMessages();
                    context.go('/login');
                  },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Todos los campos son obligatorios.',
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _name,
                label: 'Nombre completo *',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: Validators.fullName,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _email,
                label: 'Correo electrónico *',
                hint: 'nombre@correo.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _password,
                label: 'Contraseña *',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.newPassword,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PasswordChecklist(password: _password.text),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _confirm,
                label: 'Repite la contraseña *',
                icon: Icons.lock_reset_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.confirmPassword(v, _password.text),
                onSubmitted: (_) => _submit(),
              ),
              AnimatedSize(
                duration: AppDurations.normal,
                child: auth.errorMessage == null
                    ? const SizedBox(height: AppSpacing.lg)
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: AppBanner(message: auth.errorMessage!, tone: BannerTone.error),
                      ),
              ),
              AppButton(
                label: 'Crear cuenta',
                icon: Icons.person_add_alt_1_rounded,
                isLoading: auth.isBusy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Requisitos de contraseña que se marcan en tiempo real.
class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = [
      ('Al menos ${AppConfig.passwordMinLength} caracteres', password.length >= AppConfig.passwordMinLength),
      ('Incluye letras', RegExp(r'[A-Za-z]').hasMatch(password)),
      ('Incluye números', RegExp(r'\d').hasMatch(password)),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (label, ok) in rules)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Icon(
                  ok ? Icons.check_circle_rounded : Icons.circle_outlined,
                  key: ValueKey(ok),
                  size: 16,
                  color: ok ? context.agro.success : context.colors.outline,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: context.text.bodySmall),
            ],
          ),
      ],
    );
  }
}
