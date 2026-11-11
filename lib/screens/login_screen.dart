import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/app_banner.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    await auth.login(email: _email.text, password: _password.text);
    // Si tiene éxito, el router redirige automáticamente al inicio.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthLayout(
      title: 'Bienvenido de nuevo',
      subtitle: 'Ingresa para recibir recomendaciones de cultivos para tu terreno.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Flexible(child: Text('¿No tienes cuenta?')),
          TextButton(
            onPressed: auth.isBusy
                ? null
                : () {
                    auth.clearMessages();
                    context.go('/register');
                  },
            child: const Text('Crear cuenta'),
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
              if (auth.noticeMessage != null) ...[
                AppBanner(message: auth.noticeMessage!, onClose: auth.clearMessages),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                controller: _email,
                label: 'Correo electrónico',
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
                label: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.loginPassword,
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
              AppButton(label: 'Ingresar', icon: Icons.login_rounded, isLoading: auth.isBusy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
