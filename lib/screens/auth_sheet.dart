import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../data/app_legal.dart';
import '../data/auth_session.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'in_app_browser_screen.dart';
import 'terms_screen.dart';

bool get _showAppleSignIn => !kIsWeb && Platform.isIOS;

enum _AuthStage { pick, login, register }

Future<void> showAuthSheet(
  BuildContext context, {
  bool register = false,
  bool allowSkip = false,
  bool promote = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x661C1915),
    builder: (context) => _AuthSheet(
      startRegister: register,
      allowSkip: allowSkip,
      promote: promote,
    ),
  );
}

class _AuthSheet extends StatefulWidget {
  const _AuthSheet({
    required this.startRegister,
    this.allowSkip = false,
    this.promote = false,
  });

  final bool startRegister;
  final bool allowSkip;
  final bool promote;

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

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TermsScreen()),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_agreed) {
      setState(() => _error = AppLocalizations.of(context).agreeTermsNeeded);
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

  Future<void> _apple() => _run(AuthSession.instance.loginWithApple);

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
          promote: widget.promote,
          allowSkip: widget.allowSkip,
          busy: _busy,
          agreed: _agreed,
          error: _error,
          onToggleAgree: () => setState(() => _agreed = !_agreed),
          onPrivacy: _openPrivacy,
          onTerms: _openTerms,
          onGoogle: _google,
          onApple: _apple,
          onSkip: () => Navigator.of(context).pop(),
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
          allowSkip: widget.allowSkip,
          onTogglePass: () => setState(() => _hidePass = !_hidePass),
          onToggleAgree: () => setState(() => _agreed = !_agreed),
          onPrivacy: _openPrivacy,
          onTerms: _openTerms,
          onGoogle: _google,
          onApple: _apple,
          onSubmit: _submitLogin,
          onSkip: () => Navigator.of(context).pop(),
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
          allowSkip: widget.allowSkip,
          onTogglePass: () => setState(() => _hidePass = !_hidePass),
          onToggleAgree: () => setState(() => _agreed = !_agreed),
          onPrivacy: _openPrivacy,
          onTerms: _openTerms,
          onSubmit: _submitRegister,
          onSkip: () => Navigator.of(context).pop(),
          onBack: () => setState(() => _stage = _AuthStage.pick),
          onLogin: () => setState(() => _stage = _AuthStage.login),
        );
    }
  }
}

class _Pick extends StatelessWidget {
  const _Pick({
    required this.register,
    required this.promote,
    required this.allowSkip,
    required this.busy,
    required this.agreed,
    required this.error,
    required this.onToggleAgree,
    required this.onPrivacy,
    required this.onTerms,
    required this.onGoogle,
    required this.onApple,
    required this.onEmail,
    required this.onSkip,
  });

  final bool register;
  final bool promote;
  final bool allowSkip;
  final bool busy;
  final bool agreed;
  final String? error;
  final VoidCallback onToggleAgree;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onEmail;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = promote
        ? l10n.authPromoteTitle
        : register
            ? l10n.createYourAccount
            : l10n.welcomeBack;
    final subtitle = promote
        ? l10n.authPromoteBody
        : register
            ? l10n.createYourAccountBody
            : l10n.welcomeBackBody;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 22),
        _AgreeLine(
          agreed: agreed,
          onToggle: onToggleAgree,
          onPrivacy: onPrivacy,
          onTerms: onTerms,
        ),
        const SizedBox(height: 16),
        if (_showAppleSignIn) ...[
          _AppleButton(busy: busy, enabled: agreed, onTap: onApple),
          const SizedBox(height: 10),
        ],
        _AuthButton(
          label: l10n.continueWithGoogle,
          icon: Icons.g_mobiledata_rounded,
          filled: false,
          busy: busy,
          enabled: agreed,
          onTap: onGoogle,
        ),
        const SizedBox(height: 10),
        _AuthButton(
          label: l10n.continueWithEmail,
          icon: Icons.mail_outline_rounded,
          filled: true,
          enabled: agreed,
          onTap: onEmail,
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
        ],
        if (allowSkip) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: Text(
              AppLocalizations.of(context).skipForNow,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
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
    required this.onTerms,
    required this.onGoogle,
    required this.onApple,
    required this.onSubmit,
    required this.onBack,
    required this.onRegister,
    this.allowSkip = false,
    this.onSkip,
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
  final VoidCallback onTerms;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onRegister;
  final bool allowSkip;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetBack(label: AppLocalizations.of(context).login, onBack: onBack),
        const SizedBox(height: 16),
        _Field(controller: email, label: AppLocalizations.of(context).email, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _Field(
          controller: password,
          label: AppLocalizations.of(context).password,
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
        _AgreeLine(
          agreed: agreed,
          onToggle: onToggleAgree,
          onPrivacy: onPrivacy,
          onTerms: onTerms,
        ),
        const SizedBox(height: 16),
        _AuthButton(
          label: AppLocalizations.of(context).login,
          filled: true,
          busy: busy,
          enabled: agreed,
          onTap: onSubmit,
        ),
        const SizedBox(height: 10),
        if (_showAppleSignIn) ...[
          _AppleButton(busy: busy, enabled: agreed, onTap: onApple),
          const SizedBox(height: 10),
        ],
        _AuthButton(
          label: AppLocalizations.of(context).signInWithGoogle,
          icon: Icons.g_mobiledata_rounded,
          filled: false,
          busy: busy,
          enabled: agreed,
          onTap: onGoogle,
        ),
        const SizedBox(height: 14),
        _SwitchLine(
          prompt: AppLocalizations.of(context).newHere,
          action: AppLocalizations.of(context).createAccount,
          onTap: onRegister,
        ),
        if (allowSkip && onSkip != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: onSkip,
            child: Text(
              AppLocalizations.of(context).skipForNow,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
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
    required this.onTerms,
    required this.onSubmit,
    required this.onBack,
    required this.onLogin,
    this.allowSkip = false,
    this.onSkip,
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
  final VoidCallback onTerms;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onLogin;
  final bool allowSkip;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetBack(label: AppLocalizations.of(context).createAccount, onBack: onBack),
        const SizedBox(height: 16),
        _Field(controller: name, label: AppLocalizations.of(context).name, textCapitalization: TextCapitalization.words),
        const SizedBox(height: 10),
        _Field(controller: email, label: AppLocalizations.of(context).email, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _Field(
          controller: password,
          label: AppLocalizations.of(context).password,
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
        _Field(controller: confirm, label: AppLocalizations.of(context).confirmPassword, obscure: hidePass),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        _AgreeLine(
          agreed: agreed,
          onToggle: onToggleAgree,
          onPrivacy: onPrivacy,
          onTerms: onTerms,
        ),
        const SizedBox(height: 16),
        _AuthButton(
          label: AppLocalizations.of(context).createAccount,
          filled: true,
          busy: busy,
          enabled: agreed,
          onTap: onSubmit,
        ),
        const SizedBox(height: 14),
        _SwitchLine(prompt: AppLocalizations.of(context).alreadyHaveAccount, action: AppLocalizations.of(context).login, onTap: onLogin),
        if (allowSkip && onSkip != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: onSkip,
            child: Text(
              AppLocalizations.of(context).skipForNow,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AgreeLine extends StatelessWidget {
  const _AgreeLine({
    required this.agreed,
    required this.onToggle,
    required this.onPrivacy,
    required this.onTerms,
  });

  final bool agreed;
  final VoidCallback onToggle;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const linkStyle = TextStyle(
      color: AppColors.gold,
      fontWeight: FontWeight.w800,
      fontSize: 13,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.gold,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    l10n.agreeTermsPrefix,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: onTerms,
                    child: Text(l10n.termsOfUse, style: linkStyle),
                  ),
                  Text(
                    l10n.agreeAnd,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: onPrivacy,
                    child: const Text(AppLegal.privacyLabel, style: linkStyle),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            l10n.termsNoAbuse,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
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

class _AppleButton extends StatelessWidget {
  const _AppleButton({
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy || !enabled ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: busy || !enabled,
        child: SizedBox(
          height: 50,
          child: SignInWithAppleButton(
            text: AppLocalizations.of(context).continueWithApple,
            height: 50,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            style: SignInWithAppleButtonStyle.black,
            onPressed: onTap,
          ),
        ),
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
    this.enabled = true,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final IconData? icon;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: busy || !enabled ? null : onTap,
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
