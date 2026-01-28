import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/spacing.dart';

/// Settings screen with high-fidelity Pulse Loop aesthetic.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          _buildBackgroundGlows(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
              physics: const BouncingScrollPhysics(),
              children: [
                // Large Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile card
                _buildProfileCard(context),
                const SizedBox(height: 32),

                const _SectionHeader(title: 'Playback'),
                const SizedBox(height: 12),
                const _SettingsTile(
                  icon: Icons.speed_rounded,
                  title: 'Default Speed',
                  subtitle: 'Normal',
                ),
                const _SettingsTile(
                  icon: Icons.timer_rounded,
                  title: 'Loop Count',
                  subtitle: 'Infinite',
                ),
                const SizedBox(height: 24),

                const _SectionHeader(title: 'Preferences'),
                const SizedBox(height: 12),
                const _SettingsTile(
                  icon: Icons.palette_rounded,
                  title: 'Theme',
                  subtitle: 'Amoled Dark',
                ),
                const _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Enabled',
                ),
                const SizedBox(height: 24),

                const _SectionHeader(title: 'System'),
                const SizedBox(height: 12),
                const _SettingsTile(
                  icon: Icons.download_rounded,
                  title: 'Export Favorites',
                ),
                const _SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Clear Cache',
                  isDestructive: true,
                ),
                const SizedBox(height: 32),

                // Logout button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => _showLogoutDialog(context),
                    child: const Text(
                      'LOG OUT',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Pulse Loop v${AppConfig.appVersion}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlows() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: const Color(0xFF0F0F0F)),
          _GlowBlob(
            top: 150,
            left: -150,
            color: Colors.blue.withValues(alpha: 0.08),
            size: 400,
          ),
          _GlowBlob(
            bottom: 100,
            right: -100,
            color: Colors.purple.withValues(alpha: 0.08),
            size: 350,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                width: 2,
              ),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/a/ACg8ocL-f_Xm_k_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T_Z_T=s96-c',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alex Pulse',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PREMIUM MEMBER',
                    style: TextStyle(
                      color: Color(0xFF1DB954),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white54,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of Pulse Loop?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text(
              'Log out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Color color;
  final double size;

  const _GlowBlob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDestructive ? Colors.redAccent : Colors.white).withValues(
              alpha: 0.05,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.redAccent : Colors.white70,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white24,
          size: 20,
        ),
        onTap: () {},
      ),
    );
  }
}
