import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_session.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../data/app_legal.dart';
import 'auth_sheet.dart';
import 'in_app_browser_screen.dart';
import 'life_screen.dart';
import 'profile_edit_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthSession.instance,
      builder: (context, _) {
        final user = AuthSession.instance.user;
        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              title: Text('Profile'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: user == null
                    ? const _GuestCard()
                    : _SignedInCard(user: user),
              ),
            ),
            const SliverToBoxAdapter(child: PrayerLifeBody()),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.stroke),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE8B84A),
                    Color(0xFFC45C4A),
                    Color(0xFF4C8DFF),
                    Color(0xFF2BB673),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      _AccentAvatar(letter: 'G', color: Color(0xFFC9842A)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guest',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Browsing KSA 360',
                              style: TextStyle(
                                color: Color(0xFFC9842A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Create an account for a lighter profile — just your name when you need it.',
                    style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _GhostButton(
                          label: 'Create account',
                          filled: true,
                          onTap: () => showAuthSheet(context, register: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _GhostButton(
                          label: 'Log in',
                          filled: false,
                          onTap: () => showAuthSheet(context, register: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => openInAppBrowser(
                        context,
                        url: AppLegal.privacyUrl,
                        title: AppLegal.privacyLabel,
                      ),
                      child: const Text(
                        AppLegal.privacyLabel,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.stroke),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE8B84A),
                        Color(0xFFC45C4A),
                        Color(0xFF4C8DFF),
                        Color(0xFF2BB673),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFF4E4C4),
                    backgroundImage:
                        user.avatar.isEmpty ? null : NetworkImage(user.avatar),
                    child: user.avatar.isEmpty
                        ? Text(
                            user.initials,
                            style: const TextStyle(
                              color: Color(0xFF8A5E2E),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.isGoogle ? 'Signed in with Google' : 'Signed in with email',
                          style: const TextStyle(
                            color: AppColors.goldSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (user.needsDetails) ...[
                const SizedBox(height: 14),
                const Text(
                  'Add your mobile, date of birth, and gender to finish this profile.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          showProfileEditSheet(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC9842A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Manage profile'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      AuthSession.instance.signOut();
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _QuietCard(
          children: [
            _RowTile(
              icon: Icons.person_outline_rounded,
              title: 'Name',
              subtitle: user.name,
              accent: const Color(0xFFC9842A),
              onTap: () => showProfileEditSheet(context),
            ),
            _RowTile(
              icon: Icons.phone_outlined,
              title: 'Mobile',
              subtitle: user.phoneLabel,
              accent: const Color(0xFFC45C4A),
              onTap: () => showProfileEditSheet(context),
            ),
            _RowTile(
              icon: Icons.cake_outlined,
              title: 'Date of birth',
              subtitle: user.dateOfBirthLabel,
              accent: const Color(0xFF4C8DFF),
              onTap: () => showProfileEditSheet(context),
            ),
            _RowTile(
              icon: Icons.wc_outlined,
              title: 'Gender',
              subtitle: user.genderLabel,
              accent: const Color(0xFF6B4C9A),
              onTap: () => showProfileEditSheet(context),
            ),
            _RowTile(
              icon: Icons.mail_outline_rounded,
              title: 'Email',
              subtitle: user.email,
              accent: const Color(0xFF2BB673),
            ),
            _RowTile(
              icon: Icons.policy_outlined,
              title: AppLegal.privacyLabel,
              subtitle: 'How we use your data',
              accent: const Color(0xFF1B1916),
              last: true,
              onTap: () => openInAppBrowser(
                context,
                url: AppLegal.privacyUrl,
                title: AppLegal.privacyLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuietCard extends StatelessWidget {
  const _QuietCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(children: children),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentAvatar extends StatelessWidget {
  const _AccentAvatar({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: filled ? const Color(0xFFC9842A) : Colors.transparent,
          foregroundColor: filled ? Colors.white : AppColors.navy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: filled ? Colors.transparent : AppColors.stroke,
            ),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ),
    );
  }
}
