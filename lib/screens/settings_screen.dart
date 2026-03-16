import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todoappp/core/services/streak_services.dart';
import 'package:todoappp/core/theme/app_colors.dart';
import 'package:todoappp/core/theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  StreakData? _streakData;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final data = await StreakService.getStreakData();
    if (mounted) setState(() => _streakData = data);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.title(context);
    final subColor = AppColors.greyText(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_streakData != null) ...[
            _buildSectionLabel('Streak', subColor),
            _buildStreakCard(),
            const SizedBox(height: 24),
          ],
          _buildSectionLabel('Appearance', subColor),
          _buildCard(
            child: _buildToggleTile(
              icon: isDark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              iconColor: isDark
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFFF59E0B),
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
            child: Column(children: [
              _buildInfoTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primary,
                title: 'Version',
                trailing: '1.0.0',
                textColor: textColor,
                subColor: subColor,
              ),
              Divider(height: 1, color: AppColors.divider(context)),
              _buildInfoTile(
                icon: Icons.code_rounded,
                iconColor: AppColors.success,
                title: 'Built with Flutter',
                trailing: '💙',
                textColor: textColor,
                subColor: subColor,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final streak = _streakData!;
    final isActive = streak.currentStreak > 0;
    final color = isActive ? const Color(0xFFF59E0B) : AppColors.greyText(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                  : [AppColors.greyLight(context), AppColors.greyLight(context)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Text(streak.streakEmoji,
                style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive
                        ? '${streak.currentStreak} Day Streak!'
                        : 'No Active Streak',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : AppColors.greyText(context)),
                  ),
                  Text(
                    streak.streakMessage,
                    style: TextStyle(
                        fontSize: 13,
                        color: isActive
                            ? Colors.white.withOpacity(0.85)
                            : AppColors.greyText(context)),
                  ),
                ],
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _buildStreakStat(
                '${streak.bestStreak}',
                'Best Streak',
                Icons.emoji_events_rounded,
                const Color(0xFFF59E0B)),
            _verticalDivider(),
            _buildStreakStat(
                '${streak.totalCompleted}',
                'Total Done',
                Icons.check_circle_rounded,
                AppColors.success),
            _verticalDivider(),
            _buildStreakStat(
                streak.lastActiveDate != null
                    ? _formatDate(streak.lastActiveDate!)
                    : 'Never',
                'Last Active',
                Icons.calendar_today_rounded,
                AppColors.primary),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStreakStat(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.title(context))),
        Text(label,
            style: TextStyle(fontSize: 10, color: AppColors.greyText(context))),
      ]),
    );
  }

  Widget _verticalDivider() => Container(
    width: 1, height: 40,
    color: AppColors.divider(context),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  Widget _buildSectionLabel(String label, Color color) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(label.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2)),
  );

  Widget _buildCard({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.cardShadow(context),
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
        child: Row(children: [
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: subColor)),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ]),
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
        child: Row(children: [
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
          Text(trailing, style: TextStyle(fontSize: 14, color: subColor)),
        ]),
      );
}