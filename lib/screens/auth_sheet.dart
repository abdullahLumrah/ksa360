import 'package:flutter/material.dart';

import '../data/app_legal.dart';
import '../data/auth_session.dart';
import '../theme/app_theme.dart';
import 'in_app_browser_screen.dart';

enum _AuthStage { pick, login, register }

Future<void> showAuthSheet(BuildContext context, {bool register = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x661C1915),
    builder: (context) => _AuthSheet(startRegister: register),
  );
}

class _AuthSheet extends StatefulWidget {
  const _AuthSheet({required this.startRegister});

  final bool startRegister;

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  late _AuthStage _stage;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _hidePass = true;
  var _busy = false;
  var _agreed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stage = widget.startRegister ? _AuthStage.pick : _AuthStage.pick;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _openPrivacy() {
    openInAppBrowser(
      context,
      url: AppLegal.privacyUrl,
      title: AppLegal.privacyLabel,
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_agreed) {
      setState(() => _error = 'Please agree to the Privacy Policy to continue');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      if (AuthSession.instance.isSignedIn) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() => _run(AuthSession.instance.loginWithGoogle);

  Future<void> _submitLogin() => _run(
        () => AuthSession.instance.login(
          email: _email.text.trim(),
          password: _password.text,
        ),
      );

  Future<void> _submitRegister() => _run(() {
        return AuthSession.instance.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          confirmPassword: _confirm.text,
        );
      });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 18 + inset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.stroke,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_stage),
                      child: _body(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_stage) {
      case _AuthStage.pick:
        return _Pick(
          register: widget.startRegister,
          busy: _busy,
          agreed: _agreed,
          error: _error,
          onToggleAgree: () => setState(() => _agreed = !_agreed),
          onPrivacy: _openPrivacy,
          onGoogle: _google,
          onEmail: () => setState(() {
            _error = null;
            _stage = widget.startRegister ? _AuthStage.register : _AuthStage.login;
          }),
        );
      case _AuthStage.login:
        return _LoginForm(
          email: _email,
          password: _password,
          hidePass: _hidePass,
          busy: _busy,
          agreed: _agreed,
          error: _error,
          onTogglePass: () => setState(() => _hidePass = !_hidePass),
          onToggleAgree: () => setState(() => _agreed = !_agreed),
          onPrivacy: _openPrivacy,
          onGoogle: _google,
          onSubmit: _submitLogin,
          onBack: () => setState(() => _stage = _AuthStage.pick),
          onRegister: () => setState(() => _stage = _AuthStage.register),
        );
      case _AuthStage.register:
        return _RegisterForm(
          name: _name,
          email: _email,
          password: _password,
          confirm: _confirm,
          hidePass: _hidePass,
          busy: _busy,
          agreed: _agreed,
          error: _error,
          onTogglePass: () => setState(() => _hidePass = !_hidePass),
          onToggleAgree: () => setState(() => _agreed = !_agreed),
          onPrivacy: _openPrivacy,
          onSubmit: _submitRegister,
          onBack: () => setState(() => _stage = _AuthStage.pick),
          onLogin: () => setState(() => _stage = _AuthStage.login),
        );
    }
  }
}

class _Pick extends StatelessWidget {
  const _Pick({
    required this.register,
    required this.busy,
    required this.agreed,
    required this.error,
    required this.onToggleAgree,
    required this.onPrivacy,
    required this.onGoogle,
    required this.onEmail,
  });

  final bool register;
  final bool busy;
  final bool agreed;
  final String? error;
  final VoidCallback onToggleAgree;
  final VoidCallback onPrivacy;
  final VoidCallback onGoogle;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          register ? 'Create your account' : 'Welcome back',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          register
              ? 'A light profile so we can keep your saved places with you.'
              : 'Sign in to sync your profile across this phone.',
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 22),
        _AuthButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata_rounded,
          filled: false,
          busy: busy,
          onTap: onGoogle,
        ),
        const SizedBox(height: 10),
        _AuthButton(
          label: 'Continue with email',
          icon: Icons.mail_outline_rounded,
          filled: true,
          onTap: onEmail,
        ),
        const SizedBox(height: 14),
        _AgreeLine(agreed: agreed, onToggle: onToggleAgree, onPrivacy: onPrivacy),
        if (error != null) ...[
          const SizedBox(height: 14),
          Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
        ],
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.email,
    required this.password,
    required this.hidePass,
    required this.busy,
    required this.agreed,
    required this.error,
    required this.onTogglePass,
    required this.onToggleAgree,
    required this.onPrivacy,
    required this.onGoogle,
    required this.onSubmit,
    required this.onBack,
    required this.onRegister,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool hidePass;
  final bool busy;
  final bool agreed;
  final String? error;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleAgree;
  final VoidCallback onPrivacy;
  final VoidCallback onGoogle;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetBack(label: 'Log in', onBack: onBack),
        const SizedBox(height: 16),
        _Field(controller: email, label: 'Email', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _Field(
          controller: password,
          label: 'Password',
          obscure: hidePass,
          suffix: IconButton(
            onPressed: onTogglePass,
            icon: Icon(
              hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: AppColors.muted,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        _AgreeLine(agreed: agreed, onToggle: onToggleAgree, onPrivacy: onPrivacy),
        const SizedBox(height: 16),
        _AuthButton(label: 'Log in', filled: true, busy: busy, onTap: onSubmit),
        const SizedBox(height: 10),
        _AuthButton(
          label: 'Sign in with Google',
          icon: Icons.g_mobiledata_rounded,
          filled: false,
          busy: busy,
          onTap: onGoogle,
        ),
        const SizedBox(height: 14),
        _SwitchLine(
          prompt: 'New here?',
          action: 'Create account',
          onTap: onRegister,
        ),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.name,
    required this.email,
    required this.password,
    required this.confirm,
    required this.hidePass,
    required this.busy,
    required this.agreed,
    required this.error,
    required this.onTogglePass,
    required this.onToggleAgree,
    required this.onPrivacy,
    required this.onSubmit,
    required this.onBack,
    required this.onLogin,
  });

  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirm;
  final bool hidePass;
  final bool busy;
  final bool agreed;
  final String? error;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleAgree;
  final VoidCallback onPrivacy;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetBack(label: 'Create account', onBack: onBack),
        const SizedBox(height: 16),
        _Field(controller: name, label: 'Name', textCapitalization: TextCapitalization.words),
        const SizedBox(height: 10),
        _Field(controller: email, label: 'Email', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _Field(
          controller: password,
          label: 'Password',
          obscure: hidePass,
          suffix: IconButton(
            onPressed: onTogglePass,
            icon: Icon(
              hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Field(controller: confirm, label: 'Confirm password', obscure: hidePass),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        _AgreeLine(agreed: agreed, onToggle: onToggleAgree, onPrivacy: onPrivacy),
        const SizedBox(height: 16),
        _AuthButton(label: 'Create account', filled: true, busy: busy, onTap: onSubmit),
        const SizedBox(height: 14),
        _SwitchLine(prompt: 'Already have an account?', action: 'Log in', onTap: onLogin),
      ],
    );
  }
}

class _AgreeLine extends StatelessWidget {
  const _AgreeLine({
    required this.agreed,
    required this.onToggle,
    required this.onPrivacy,
  });

  final bool agreed;
  final VoidCallback onToggle;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: agreed,
            onChanged: (_) => onToggle(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'I agree to the ',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              GestureDetector(
                onTap: onPrivacy,
                child: const Text(
                  AppLegal.privacyLabel,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetBack extends StatelessWidget {
  const _SheetBack({required this.label, required this.onBack});

  final String label;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboard,
    this.obscure = false,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.bg,
        suffixIcon: suffix,
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.icon,
    this.busy = false,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: filled ? AppColors.greenDeep : AppColors.bg,
          foregroundColor: filled ? AppColors.onDark : AppColors.navy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: filled ? Colors.transparent : AppColors.stroke),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
      ),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: const TextStyle(color: AppColors.muted)),
        TextButton(
          onPressed: onTap,
          child: Text(action, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
