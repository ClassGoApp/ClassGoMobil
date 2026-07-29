import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_design.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

class StatsBar extends StatefulWidget {
  const StatsBar({super.key});

  @override
  State<StatsBar> createState() => _StatsBarState();
}

class _StatsBarState extends State<StatsBar> {
  int _users = 0;
  int _tutors = 0;
  int _students = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await fetchStats();
      if (!mounted) return;
      setState(() {
        _users = data['total_users'] ?? 0;
        _tutors = data['total_tutors'] ?? 0;
        _students = data['total_students'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.dividerLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(child: _StatColumn(label: l10n.users, count: _users, icon: Icons.people_rounded, isCenter: false)),
            SizedBox(
              height: 50,
              child: VerticalDivider(width: 1, color: AppColors.dividerLight),
            ),
            Expanded(child: _StatColumn(label: l10n.tutors, count: _tutors, icon: Icons.school_rounded, isCenter: true)),
            SizedBox(
              height: 50,
              child: VerticalDivider(width: 1, color: AppColors.dividerLight),
            ),
            Expanded(child: _StatColumn(label: l10n.students, count: _students, icon: Icons.person_rounded, isCenter: false)),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatefulWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool isCenter;

  const _StatColumn({
    required this.label,
    required this.count,
    required this.icon,
    required this.isCenter,
  });

  @override
  State<_StatColumn> createState() => _StatColumnState();
}

class _StatColumnState extends State<_StatColumn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _displayCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addListener(() {
      setState(() {
        _displayCount = (_animation.value * widget.count).round();
      });
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isCenter ? AppColors.brandOrange : AppColors.brandCyan;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: accent, size: 16),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _formatNumber(_displayCount),
            style: const TextStyle(
              fontFamily: AppFonts.heading,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.brandBlue,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.isCenter ? accent : AppColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) => n.toString();
}
