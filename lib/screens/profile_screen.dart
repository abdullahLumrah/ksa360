import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_session.dart';
import '../data/content_repository.dart';
import '../data/life_settings.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import 'auth_sheet.dart';
import 'profile_edit_sheet.dart';
import 'city_picker_screen.dart';
import 'explore_screen.dart';
import 'life_screen.dart';
import 'lifestyle_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AuthSession.instance,
        LifeSettings.instance,
        ContentRepository.instance,
      ]),
      builder: (context, _) {
        final session = AuthSession.instance;
        final user = session.user;
        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              title: Text('Profile'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: Column(
                  children: [
                    if (user == null)
                      const _GuestCard()
                    else
                      _SignedInCard(user: user),
                    const SizedBox(height: 18),
                    _QuietCard(
                      children: [
                        _RowTile(
                          icon: Icons.mosque_rounded,
                          title: 'Prayer times',
                          subtitle: LifeSettings.instance.locationLabel,
                          onTap: () => openCard(context, const LifeScreen()),
                        ),
                        _RowTile(
                          icon: Icons.location_on_outlined,
                          title: 'City',
                          subtitle: LifeSettings.instance.city.name,
                          onTap: () => openCard(context, const CityPickerScreen()),
                        ),
                        _RowTile(
                          icon: Icons.tune_rounded,
                          title: 'Lifestyle',
                          subtitle: LifeSettings.instance.lifestyle == Lifestyle.family
                              ? 'Family'
                              : 'Bachelor',
                          onTap: () => openCard(context, const LifestyleScreen()),
                        ),
                        _RowTile(
                          icon: Icons.bookmark_outline_rounded,
                          title: 'Saved guides',
                          subtitle: '${ContentRepository.instance.savedIds.length} saved',
                          last: true,
                          onTap: () => openCard(context, const SavedScreen()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143D2C), Color(0xFF1E7A4C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onDark.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.goldBright.withValues(alpha: 0.55)),
                ),
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest',
                      style: TextStyle(
                        color: AppColors.onDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Browsing KSA 360',
                      style: TextStyle(color: AppColors.goldBright, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Keep saved guides and a lighter profile with you. No clutter — just your name when you need it.',
            style: TextStyle(color: Color(0xD9F7F2E8), height: 1.4, fontSize: 13.5),
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
        ],
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.stroke),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFE4F0E8),
                    backgroundImage:
                        user.avatar.isEmpty ? null : NetworkImage(user.avatar),
                    child: user.avatar.isEmpty
                        ? Text(
                            user.initials,
                            style: const TextStyle(
                              color: AppColors.greenDeep,
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
                Text(
                  'Add your date of birth and gender to finish this profile.',
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
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
                        child: const Text('Edit profile'),
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
        const SizedBox(height: 14),
        _QuietCard(
          children: [
            _RowTile(
              icon: Icons.person_outline_rounded,
              title: 'Name',
              subtitle: user.name,
              onTap: () => showProfileEditSheet(context),
            ),
            _RowTile(
              icon: Icons.cake_outlined,
              title: 'Date of birth',
              subtitle: user.dateOfBirthLabel,
              onTap: () => showProfileEditSheet(context),
            ),
            _RowTile(
              icon: Icons.wc_outlined,
              title: 'Gender',
              subtitle: user.genderLabel,
              onTap: () => showProfileEditSheet(context),
            ),
            _RowTile(
              icon: Icons.mail_outline_rounded,
              title: 'Email',
              subtitle: user.email,
              last: true,
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
    this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
              Icon(icon, color: AppColors.goldSoft, size: 22),
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
          backgroundColor: filled ? AppColors.onDark : Colors.transparent,
          foregroundColor: filled ? AppColors.greenDeep : AppColors.onDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: filled ? Colors.transparent : AppColors.onDark.withValues(alpha: 0.28),
            ),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ),
    );
  }
}
