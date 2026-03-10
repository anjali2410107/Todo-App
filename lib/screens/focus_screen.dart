import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:todoappp/core/services/notification_service.dart';

enum FocusPhase { idle, focusing, onBreak, finished }

class SessionRecord {
  final int sessionMinutes;
  final int breakMinutes;
  final DateTime completedAt;
  final bool skippedBreak;

  SessionRecord({
    required this.sessionMinutes,
    required this.breakMinutes,
    required this.completedAt,
    required this.skippedBreak,
  });

  Map<String, dynamic> toJson() => {
    'sessionMinutes': sessionMinutes,
    'breakMinutes': breakMinutes,
    'completedAt': completedAt.toIso8601String(),
    'skippedBreak': skippedBreak,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    sessionMinutes: json['sessionMinutes'],
    breakMinutes: json['breakMinutes'],
    completedAt: DateTime.parse(json['completedAt']),
    skippedBreak: json['skippedBreak'],
  );
}


const List<String> _quotes = [
  "Deep work is the superpower of the 21st century.",
  "Focus is the art of knowing what to ignore.",
  "One task at a time. You've got this.",
  "Small steps every day lead to big results.",
  "The secret of getting ahead is getting started.",
  "Your future self is watching. Make them proud.",
  "Concentrate all your thoughts upon the work at hand.",
  "It's not about having time, it's about making time.",
  "Success is the sum of small efforts repeated daily.",
  "Stay focused, go after your dreams.",
];

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  int _sessionMinutes = 25;
  int _breakMinutes = 5;

  FocusPhase _phase = FocusPhase.idle;

  int _secondsLeft = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  DateTime? _timerStartTime;
  int _secondsAtPause = 0;


  final List<SessionRecord> _history = [];
  int _pomodoroCount = 0;


  SessionRecord? _lastSession;


  String _currentQuote = _quotes[0];


  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _pickQuote();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }


  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('focus_history') ?? [];
    final count = prefs.getInt('pomodoro_count') ?? 0;
    setState(() {
      _history.addAll(raw
          .map((e) => SessionRecord.fromJson(jsonDecode(e)))
          .toList()
          .reversed
          .toList());
      _pomodoroCount = count;
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('focus_history', raw);
    await prefs.setInt('pomodoro_count', _pomodoroCount);
  }


  void _pickQuote() {
    final r = Random();
    setState(() => _currentQuote = _quotes[r.nextInt(_quotes.length)]);
  }

  int _calculateBreak(int sessionMins) {
    if (sessionMins <= 30) return 5;
    if (sessionMins <= 60) return 10;
    if (sessionMins <= 90) return 15;
    return 20;
  }

  void _onSessionChanged(int mins) {
    setState(() {
      _sessionMinutes = mins;
      _breakMinutes = _calculateBreak(mins);
    });
  }


  void _startDriftFreeTimer(int totalSeconds) {
    _timer?.cancel();
    _timerStartTime = DateTime.now();
    _secondsAtPause = totalSeconds;
    _totalSeconds = totalSeconds;
    _secondsLeft = totalSeconds;

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final elapsed =
          DateTime.now().difference(_timerStartTime!).inSeconds;
      final remaining = _secondsAtPause - elapsed;

      if (remaining <= 0) {
        setState(() => _secondsLeft = 0);
        if (_phase == FocusPhase.focusing) {
          _startBreak();
        } else if (_phase == FocusPhase.onBreak) {
          _finishSession(skippedBreak: false);
        }
        return;
      }
      setState(() => _secondsLeft = remaining);
    });
  }

  void _startFocus() {
    _pickQuote();
    setState(() => _phase = FocusPhase.focusing);
    _startDriftFreeTimer(_sessionMinutes * 60);
  }

  void _startBreak() {
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    NotificationService.showImmediateNotification(
      id: 9001,
      title: "Break Time! 🎉",
      body: "Great work! Take a ${_breakMinutes}-minute break.",
    );
    setState(() => _phase = FocusPhase.onBreak);
    _startDriftFreeTimer(_breakMinutes * 60);
  }

  void _skipBreak() => _finishSession(skippedBreak: true);

  void _finishSession({required bool skippedBreak}) {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    NotificationService.showImmediateNotification(
      id: 9002,
      title: skippedBreak ? "Break Skipped" : "Break Over! 💪",
      body: skippedBreak
          ? "Break skipped. Ready for another session?"
          : "Break's done! Ready to focus again?",
    );

    final record = SessionRecord(
      sessionMinutes: _sessionMinutes,
      breakMinutes: skippedBreak ? 0 : _breakMinutes,
      completedAt: DateTime.now(),
      skippedBreak: skippedBreak,
    );

    setState(() {
      _history.insert(0, record);
      _lastSession = record;
      if (!skippedBreak) _pomodoroCount++;
      _phase = FocusPhase.finished;
      _secondsLeft = 0;
    });
    _saveHistory();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _phase = FocusPhase.idle;
      _secondsLeft = 0;
      _totalSeconds = 0;
      _timerStartTime = null;
    });
  }

  void _pauseResume() {
    if (_timer?.isActive == true) {
      _secondsAtPause = _secondsLeft;
      _timer?.cancel();
      setState(() {});
    } else {
      _timerStartTime = DateTime.now();
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        final elapsed =
            DateTime.now().difference(_timerStartTime!).inSeconds;
        final remaining = _secondsAtPause - elapsed;

        if (remaining <= 0) {
          setState(() => _secondsLeft = 0);
          if (_phase == FocusPhase.focusing) {
            _startBreak();
          } else if (_phase == FocusPhase.onBreak) {
            _finishSession(skippedBreak: false);
          }
          return;
        }
        setState(() => _secondsLeft = remaining);
      });
      setState(() {});
    }
  }

  bool get _isPaused =>
      (_phase == FocusPhase.focusing || _phase == FocusPhase.onBreak) &&
          _timer?.isActive != true;

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get _todayFocusMinutes {
    final today = DateTime.now();
    return _history
        .where((r) =>
    r.completedAt.year == today.year &&
        r.completedAt.month == today.month &&
        r.completedAt.day == today.day)
        .fold(0, (sum, r) => sum + r.sessionMinutes);
  }

  static const _phaseColors = {
    FocusPhase.focusing: Colors.deepPurple,
    FocusPhase.onBreak: Colors.teal,
    FocusPhase.finished: Colors.green,
    FocusPhase.idle: Colors.grey,
  };

  Color get _phaseColor => _phaseColors[_phase]!;

  String get _phaseLabel {
    switch (_phase) {
      case FocusPhase.focusing:
        return 'Focus Session';
      case FocusPhase.onBreak:
        return 'Break Time';
      case FocusPhase.finished:
        return 'Session Complete!';
      case FocusPhase.idle:
        return 'Ready to Focus';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatsBar(),
            const SizedBox(height: 20),

            _buildTimer(),
            const SizedBox(height: 16),

            if (_phase == FocusPhase.focusing) _buildQuoteCard(),

            if (_isPaused) _buildPausedBadge(),

            const SizedBox(height: 16),


            if (_phase == FocusPhase.idle || _phase == FocusPhase.finished)
              _buildSetupCard(),

            if (_phase == FocusPhase.finished && _lastSession != null)
              _buildSummaryCard(),

            const SizedBox(height: 20),
            _buildControls(),
            const SizedBox(height: 28),
            if (_history.isNotEmpty) _buildHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statChip(Icons.local_fire_department, '$_pomodoroCount', 'Pomodoros',
            Colors.orange),
        _statChip(Icons.access_time_filled, '${_todayFocusMinutes}m',
            'Today', Colors.deepPurple),
        _statChip(
            Icons.history, '${_history.length}', 'Sessions', Colors.teal),
      ],
    );
  }

  Widget _statChip(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final progress =
    _totalSeconds > 0 ? _secondsLeft / _totalSeconds : 0.0;

    Widget circle = SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CustomPaint(
              painter: _CircleTimerPainter(
                progress: progress,
                color: _phaseColor,
                isPaused: _isPaused,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _phase == FocusPhase.idle
                    ? _formatTime(_sessionMinutes * 60)
                    : _formatTime(_secondsLeft),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: _phaseColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _phaseLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: _phaseColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (_phase == FocusPhase.focusing && !_isPaused) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _pulseAnimation.value, child: child),
        child: circle,
      );
    }
    return circle;
  }

  Widget _buildPausedBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.pause_circle_outline, color: Colors.orange, size: 18),
          SizedBox(width: 6),
          Text('Paused',
              style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.format_quote, color: Colors.deepPurple, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentQuote,
                style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final s = _lastSession!;
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, color: Colors.green, size: 36),
            const SizedBox(height: 8),
            const Text('Great Work!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(height: 12),
            _summaryRow(Icons.timer, 'Session', '${s.sessionMinutes} min'),
            _summaryRow(
                Icons.coffee,
                'Break',
                s.skippedBreak ? 'Skipped' : '${s.breakMinutes} min'),
            _summaryRow(Icons.today, 'Total today',
                '${_todayFocusMinutes} min'),
            _summaryRow(Icons.local_fire_department, 'Pomodoros',
                '$_pomodoroCount completed'),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text('$label:',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: TextStyle(color: Colors.green.shade700)),
        ],
      ),
    );
  }

  Widget _buildSetupCard() {
    final hours = _sessionMinutes ~/ 60;
    final minutes = _sessionMinutes % 60;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Session Duration',
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeUnit(
                  label: 'HH',
                  value: hours,
                  onIncrement: () =>
                      _onSessionChanged(_sessionMinutes + 60),
                  onDecrement: () {
                    if (_sessionMinutes - 60 >= 5)
                      _onSessionChanged(_sessionMinutes - 60);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(':',
                      style: TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold)),
                ),
                _buildTimeUnit(
                  label: 'MM',
                  value: minutes,
                  onIncrement: () =>
                      _onSessionChanged(_sessionMinutes + 5),
                  onDecrement: () {
                    if (_sessionMinutes - 5 >= 5)
                      _onSessionChanged(_sessionMinutes - 5);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.coffee, size: 16, color: Colors.teal),
                const SizedBox(width: 6),
                Text(
                  'Auto break: $_breakMinutes min',
                  style: const TextStyle(
                      color: Colors.teal, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 32),
          color: Colors.deepPurple,
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style:
          const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
        ),
        Text(label,
            style:
            TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        IconButton(
          onPressed: onDecrement,
          icon:
          const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          color: Colors.deepPurple,
        ),
      ],
    );
  }

  Widget _buildControls() {
    if (_phase == FocusPhase.idle || _phase == FocusPhase.finished) {
      return ElevatedButton.icon(
        onPressed: _startFocus,
        icon: const Icon(Icons.play_arrow),
        label: Text(_phase == FocusPhase.finished
            ? 'Start New Session'
            : 'Start Focus Session'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _pauseResume,
          icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
          label: Text(_isPaused ? 'Resume' : 'Pause'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _phaseColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
        ),
        const SizedBox(width: 12),
        if (_phase == FocusPhase.onBreak)
          OutlinedButton.icon(
            onPressed: _skipBreak,
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip Break'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _reset,
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset',
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Session History',
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ..._history.map((record) {
          final time =
              '${record.completedAt.hour.toString().padLeft(2, '0')}:${record.completedAt.minute.toString().padLeft(2, '0')}';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                child: const Icon(Icons.timer, color: Colors.deepPurple),
              ),
              title: Text('${record.sessionMinutes} min session'),
              subtitle: Text(record.skippedBreak
                  ? 'Break skipped · $time'
                  : 'Break: ${record.breakMinutes} min · $time'),
              trailing: record.skippedBreak
                  ? const Icon(Icons.skip_next,
                  color: Colors.orange, size: 18)
                  : const Icon(Icons.check_circle,
                  color: Colors.green, size: 18),
            ),
          );
        }),
      ],
    );
  }
}

class _CircleTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPaused;

  _CircleTimerPainter(
      {required this.progress,
        required this.color,
        this.isPaused = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = isPaused ? color.withOpacity(0.45) : color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleTimerPainter old) =>
      old.progress != progress ||
          old.color != color ||
          old.isPaused != isPaused;
}