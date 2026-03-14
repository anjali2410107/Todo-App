import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todoappp/core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionLabel('Appearance', subColor),
          _buildCard(
            cardColor: cardColor,
            child: _buildToggleTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: isDark ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B),
              title: 'Dark Mode',
              subtitle: isDark ? 'Dark theme is on' : 'Light theme is on',
              textColor: textColor,
              subColor: subColor,
              value: isDark,
              onChanged: (_) =>
                  context.read<ThemeProvider>().toggleTheme(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('About', subColor),
          _buildCard(
            cardColor: cardColor,
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Version',
                  trailing: '1.0.0',
                  textColor: textColor,
                  subColor: subColor,
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _buildInfoTile(
                  icon: Icons.code_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Built with Flutter',
                  trailing: '💙',
                  textColor: textColor,
                  subColor: subColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildCard({required Color cardColor, required Widget child}) =>
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textColor)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: subColor)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF6366F1),
            ),
          ],
        ),
      );

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailing,
    required Color textColor,
    required Color subColor,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor)),
            ),
            Text(trailing,
                style: TextStyle(fontSize: 14, color: subColor)),
          ],
        ),
      );
}