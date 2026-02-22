import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen>
    with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = _TripTheme(isDark: isDark);

    return Scaffold(
      backgroundColor: theme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: StreamBuilder<List<TripModel>>(
          stream: _tripService.getTripHistory(),
          builder: (context, snapshot) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(theme),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: _LoadingState(),
                  )
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    child: _ErrorState(error: '${snapshot.error}', theme: theme),
                  )
                else if ((snapshot.data ?? []).isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(theme: theme),
                  )
                else
                  _buildContent(snapshot.data!, theme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(_TripTheme theme) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: theme.background,
      expandedHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        title: Text(
          'Trip History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: theme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        background: Container(color: theme.background),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8),
          child: Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list_rounded, color: theme.textSecondary, size: 20),
              onPressed: () {},
              tooltip: 'Filter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(List<TripModel> trips, _TripTheme theme) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        20, 8, 20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _SummaryBanner(trips: trips, theme: theme),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'RECENT TRIPS',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...List.generate(trips.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TripCard(trip: trips[i], theme: theme, index: i),
            );
          }),
        ]),
      ),
    );
  }
}

// ─── Summary Banner ────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final List<TripModel> trips;
  final _TripTheme theme;

  const _SummaryBanner({required this.trips, required this.theme});

  @override
  Widget build(BuildContext context) {
    final totalKm = trips.fold(0.0, (s, t) => s + t.distance);
    final totalSecs = trips.fold(0, (s, t) => s + t.duration);
    final avgSafety = trips.isEmpty
        ? 0.0
        : trips.fold(0.0, (s, t) => s + t.safetyScore) / trips.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
              : [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Overall Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${trips.length} trips',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatCell(
                value: '${totalKm.toStringAsFixed(1)} km',
                label: 'Total Distance',
              ),
              _StatDivider(),
              _StatCell(
                value: _formatDuration(totalSecs),
                label: 'Drive Time',
              ),
              _StatDivider(),
              _StatCell(
                value: '${avgSafety.toStringAsFixed(0)}',
                label: 'Avg Safety',
                highlight: true,
                score: avgSafety,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;
  final double score;

  const _StatCell({
    required this.value,
    required this.label,
    this.highlight = false,
    this.score = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: highlight ? _scoreColor(score) : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 80) return const Color(0xFF4ADE80);
    if (s >= 60) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2));
  }
}

// ─── Trip Card ─────────────────────────────────────────────────────────────

class TripCard extends StatelessWidget {
  final TripModel trip;
  final _TripTheme theme;
  final int index;

  const TripCard({
    super.key,
    required this.trip,
    required this.theme,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d · HH:mm');
    final score = trip.safetyScore;
    final scoreColor = _scoreColor(score);
    final scoreLabel = score >= 80 ? 'Excellent' : score >= 60 ? 'Fair' : 'Poor';

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDark ? 0.2 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                // Trip number bubble
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(trip.startTime),
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.route_rounded, size: 13, color: theme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${trip.distance.toStringAsFixed(1)} km',
                            style: TextStyle(color: theme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.timer_outlined, size: 13, color: theme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(trip.duration),
                            style: TextStyle(color: theme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Safety badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scoreColor.withOpacity(0.4), width: 1),
                      ),
                      child: Text(
                        score.toStringAsFixed(0),
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: theme.separator),

          // Warnings row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WarningChip(
                  icon: Icons.speed_rounded,
                  count: trip.speedWarnings,
                  label: 'Speed',
                  theme: theme,
                ),
                _WarningChip(
                  icon: Icons.bedtime_rounded,
                  count: trip.drowsinessWarnings,
                  label: 'Drowsy',
                  theme: theme,
                ),
                _WarningChip(
                  icon: Icons.car_crash_rounded,
                  count: trip.collisionWarnings,
                  label: 'Collision',
                  theme: theme,
                ),
                _WarningChip(
                  icon: Icons.warning_rounded,
                  count: trip.potholeDetections,
                  label: 'Potholes',
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _WarningChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final _TripTheme theme;

  const _WarningChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasWarning = count > 0;
    final color = hasWarning ? const Color(0xFFF59E0B) : theme.textMuted;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasWarning
                ? const Color(0xFFF59E0B).withOpacity(0.12)
                : theme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              if (hasWarning)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── States ────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: Color(0xFF3B82F6),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final _TripTheme theme;

  const _ErrorState({required this.error, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: TextStyle(color: theme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _TripTheme theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.route_rounded,
                color: Color(0xFF3B82F6), size: 44),
          ),
          const SizedBox(height: 20),
          Text(
            'No trips yet',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your trip history will appear\nhere after your first drive.',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Theme & Helpers ───────────────────────────────────────────────────────

class _TripTheme {
  final bool isDark;
  const _TripTheme({required this.isDark});

  Color get background => isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF1F5F9);
  Color get surface => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get surfaceVariant => isDark ? const Color(0xFF253147) : const Color(0xFFF1F5F9);
  Color get textPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get textMuted => isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
  Color get separator => isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0);
}

String _formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}