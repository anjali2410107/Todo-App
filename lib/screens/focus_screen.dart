import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:todoappp/core/services/notification_service.dart';

enum FocusPhase { idle, focusing, onBreak, finished }

class SessionChunk {
  final bool isFocus;
  final int minutes;
  bool isCompleted;
  bool isActive;

  SessionChunk({
    required this.isFocus,
    required this.minutes,
    this.isCompleted = false,
    this.isActive = false,
  });
}

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
  int _sessionMinutes = 52;
  int _breakMinutes = 17;

  FocusPhase _phase = FocusPhase.idle;
  int _secondsLeft = 0;
  int _totalSeconds = 0;
  Timer? _uiTimer;

  List<SessionChunk> _chunks = [];
  int _currentChunkIndex = 0;

  final List<SessionRecord> _history = [];
  int _pomodoroCount = 0;
  String _currentQuote = _quotes[0];
  String _techniqueLabel = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _pickQuote();
    _buildChunks();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  List<SessionChunk> _calculateChunks(int totalMins) {
    List<SessionChunk> chunks = [];

    if (totalMins <= 30) {
      _techniqueLabel = 'Single Focus';
      chunks.add(SessionChunk(isFocus: true, minutes: totalMins));
      chunks.add(SessionChunk(isFocus: false, minutes: 5));
    } else if (totalMins <= 60) {
      _techniqueLabel = 'Pomodoro Extended';
      final half = totalMins ~/ 2;
      final remainder = totalMins - half;
      chunks.add(SessionChunk(isFocus: true, minutes: half));
      chunks.add(SessionChunk(isFocus: false, minutes: 5));
      chunks.add(SessionChunk(isFocus: true, minutes: remainder));
      chunks.add(SessionChunk(isFocus: false, minutes: 5));
    } else if (totalMins <= 90) {
      _techniqueLabel = '45/10 Rule';
      int remaining = totalMins;
      while (remaining > 0) {
        final focus = remaining >= 45 ? 45 : remaining;
        chunks.add(SessionChunk(isFocus: true, minutes: focus));
        remaining -= focus;
        if (remaining > 0) {
          chunks.add(SessionChunk(isFocus: false, minutes: 10));
        }
      }
      chunks.add(SessionChunk(isFocus: false, minutes: 10));
    } else if (totalMins <= 120) {
      _techniqueLabel = '52/17 Rule';
      int remaining = totalMins;
      while (remaining > 0) {
        final focus = remaining >= 52 ? 52 : remaining;
        chunks.add(SessionChunk(isFocus: true, minutes: focus));
        remaining -= focus;
        if (remaining > 0) {
          chunks.add(SessionChunk(isFocus: false, minutes: 17));
        }
      }
      chunks.add(SessionChunk(isFocus: false, minutes: 17));
    } else {
      _techniqueLabel = 'Ultradian Rhythm';
      int remaining = totalMins;
      while (remaining > 0) {
        final focus = remaining >= 90 ? 90 : remaining;
        chunks.add(SessionChunk(isFocus: true, minutes: focus));
        remaining -= focus;
        if (remaining > 0) {
          chunks.add(SessionChunk(isFocus: false, minutes: 20));
        }
      }
      chunks.add(SessionChunk(isFocus: false, minutes: 20));
    }

    return chunks;
  }

  void _buildChunks() {
    setState(() {
      _chunks = _calculateChunks(_sessionMinutes);
      _breakMinutes = _chunks
          .where((c) => !c.isFocus)
          .map((c) => c.minutes)
          .fold(0, (a, b) => a + b);
    });
  }

  void _startFocus() {
    _pickQuote();
    _chunks = _calculateChunks(_sessionMinutes);
    _currentChunkIndex = 0;
    _chunks[0].isActive = true;

    final firstChunk = _chunks[0];
    final totalSecs = firstChunk.minutes * 60;

    setState(() {
      _phase = FocusPhase.focusing;
      _secondsLeft = totalSecs;
      _totalSeconds = totalSecs;
    });
    _startUiTimer();
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _uiTimer?.cancel();
        _uiTimer = null;
        setState(() => _secondsLeft = 0);
        _onChunkComplete();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _onChunkComplete() {
    HapticFeedback.mediumImpact();

    setState(() {
      _chunks[_currentChunkIndex].isCompleted = true;
      _chunks[_currentChunkIndex].isActive = false;
    });

    final nextIndex = _currentChunkIndex + 1;

    if (nextIndex >= _chunks.length) {
      _finishSession(skippedBreak: false);
      return;
    }

    _currentChunkIndex = nextIndex;
    final nextChunk = _chunks[_currentChunkIndex];

    setState(() {
      nextChunk.isActive = true;
      _phase = nextChunk.isFocus ? FocusPhase.focusing : FocusPhase.onBreak;
      _secondsLeft = nextChunk.minutes * 60;
      _totalSeconds = _secondsLeft;
    });

    if (!nextChunk.isFocus) {
      NotificationService.showImmediateNotification(
        id: 9001,
        title: "Break Time! 🎉",
        body: "Great work! Take a ${nextChunk.minutes}-minute break.",
      );
    } else {
      NotificationService.showImmediateNotification(
        id: 9002,
        title: "Back to Focus! 💪",
        body: "Break's over. Let's get back to it!",
      );
    }

    _startUiTimer();
  }

  void _skipBreak() {
    if (_phase != FocusPhase.onBreak) return;
    _uiTimer?.cancel();
    _uiTimer = null;

    setState(() {
      _chunks[_currentChunkIndex].isCompleted = true;
      _chunks[_currentChunkIndex].isActive = false;
    });

    final nextIndex = _currentChunkIndex + 1;

    if (nextIndex >= _chunks.length) {
      _finishSession(skippedBreak: true);
      return;
    }

    _currentChunkIndex = nextIndex;
    final nextChunk = _chunks[_currentChunkIndex];

    setState(() {
      nextChunk.isActive = true;
      _phase = nextChunk.isFocus ? FocusPhase.focusing : FocusPhase.onBreak;
      _secondsLeft = nextChunk.minutes * 60;
      _totalSeconds = _secondsLeft;
    });

    _startUiTimer();
  }

  void _finishSession({required bool skippedBreak}) {
    _uiTimer?.cancel();
    HapticFeedback.heavyImpact();

    final totalFocusMinutes = _chunks
        .where((c) => c.isFocus && c.isCompleted)
        .fold(0, (sum, c) => sum + c.minutes);

    final totalBreakMinutes = _chunks
        .where((c) => !c.isFocus && c.isCompleted)
        .fold(0, (sum, c) => sum + c.minutes);

    final record = SessionRecord(
      sessionMinutes: totalFocusMinutes,
      breakMinutes: totalBreakMinutes,
      completedAt: DateTime.now(),
      skippedBreak: skippedBreak,
    );

    setState(() {
      _history.insert(0, record);
      if (!skippedBreak) _pomodoroCount++;
      _phase = FocusPhase.finished;
      _secondsLeft = 0;
    });
    _saveHistory();
  }

  void _reset() {
    _uiTimer?.cancel();
    setState(() {
      _phase = FocusPhase.idle;
      _secondsLeft = 0;
      _totalSeconds = 0;
      _currentChunkIndex = 0;
    });
    _buildChunks();
  }

  void _pauseResume() {
    if (_uiTimer?.isActive == true) {
      _uiTimer?.cancel();
      setState(() {});
    } else {
      _startUiTimer();
      setState(() {});
    }
  }

  bool get _isPaused =>
      (_phase == FocusPhase.focusing || _phase == FocusPhase.onBreak) &&
          _uiTimer?.isActive != true;

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('focus_history') ?? [];
    final count = prefs.getInt('pomodoro_count') ?? 0;
    setState(() {
      _history.addAll(raw.map((e) => SessionRecord.fromJson(jsonDecode(e))));
      _pomodoroCount = count;
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'focus_history', _history.map((e) => jsonEncode(e.toJson())).toList());
    await prefs.setInt('pomodoro_count', _pomodoroCount);
  }

  void _pickQuote() =>
      setState(() => _currentQuote = _quotes[Random().nextInt(_quotes.length)]);

  void _onSessionChanged(int mins) {
    setState(() => _sessionMinutes = mins);
    _buildChunks();
  }

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

  Color get _phaseColor {
    switch (_phase) {
      case FocusPhase.focusing:
        return const Color(0xFF6366F1);
      case FocusPhase.onBreak:
        return const Color(0xFF10B981);
      case FocusPhase.finished:
        return const Color(0xFF10B981);
      case FocusPhase.idle:
        return Colors.grey;
    }
  }

  String get _phaseLabel {
    if (_phase == FocusPhase.focusing) {
      final focusChunks = _chunks.where((c) => c.isFocus).toList();
      final currentFocusNum = _chunks
          .sublist(0, _currentChunkIndex + 1)
          .where((c) => c.isFocus)
          .length;
      return 'Focus $currentFocusNum of ${focusChunks.length}';
    }
    if (_phase == FocusPhase.onBreak) return 'Break Time ☕';
    if (_phase == FocusPhase.finished) return 'Session Complete!';
    return 'Ready to Focus';
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        elevation: 0,
        title: const Text(
          'Focus Timer',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B)),
        ),
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
            if (_phase == FocusPhase.focusing && !_isPaused) _buildQuoteCard(),
            if (_isPaused) _buildPausedBadge(),
            const SizedBox(height: 8),
            _buildTimeline(),
            const SizedBox(height: 16),
            if (_phase == FocusPhase.idle || _phase == FocusPhase.finished)
              _buildSetupCard(),
            const SizedBox(height: 20),
            _buildControls(),
            const SizedBox(height: 28),
            if (_history.isNotEmpty) _buildHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _statChip(Icons.local_fire_department, '$_pomodoroCount', 'Sessions',
          const Color(0xFFEF4444)),
      _statChip(Icons.access_time_filled, '${_todayFocusMinutes}m', 'Today',
          const Color(0xFF6366F1)),
      _statChip(Icons.history, '${_history.length}', 'Total',
          const Color(0xFF10B981)),
    ],
  );

  Widget _statChip(IconData icon, String value, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ]),
      );

  Widget _buildTimer() {
    final progress = _totalSeconds > 0 ? _secondsLeft / _totalSeconds : 0.0;

    Widget circle = SizedBox(
      width: 220,
      height: 220,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(
          child: CustomPaint(
            painter: _CircleTimerPainter(
              progress: progress,
              color: _phaseColor,
              isPaused: _isPaused,
            ),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            _phase == FocusPhase.idle
                ? _formatTime(_sessionMinutes * 60)
                : _formatTime(_secondsLeft),
            style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: _phaseColor),
          ),
          const SizedBox(height: 4),
          Text(
            _phaseLabel,
            style: TextStyle(
                fontSize: 13,
                color: _phaseColor.withOpacity(0.8),
                fontWeight: FontWeight.w500),
          ),
          if (_phase != FocusPhase.idle && _phase != FocusPhase.finished)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_chunks[_currentChunkIndex].minutes} min chunk',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ]),
      ]),
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

  Widget _buildTimeline() {
    if (_chunks.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded,
                  size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                _techniqueLabel.isNotEmpty ? _techniqueLabel : 'Session Plan',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              const Spacer(),
              Text(
                '${_chunks.where((c) => c.isFocus).length} focus · ${_chunks.where((c) => !c.isFocus).length} breaks',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_chunks.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final chunkIndex = i ~/ 2;
                  final isCompleted = chunkIndex < _chunks.length &&
                      _chunks[chunkIndex].isCompleted;
                  return Container(
                    width: 20,
                    height: 2,
                    color: isCompleted
                        ? const Color(0xFF6366F1)
                        : Colors.grey.shade200,
                  );
                }
                final chunkIndex = i ~/ 2;
                final chunk = _chunks[chunkIndex];
                return _buildTimelineDot(chunk, chunkIndex);
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _timelineLegend(
                  const Color(0xFF6366F1), Icons.bolt_rounded, 'Focus'),
              const SizedBox(width: 16),
              _timelineLegend(
                  const Color(0xFF10B981), Icons.coffee_rounded, 'Break'),
              const SizedBox(width: 16),
              _timelineLegend(Colors.grey.shade300, Icons.circle, 'Upcoming'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDot(SessionChunk chunk, int index) {
    final isActive = chunk.isActive;
    final isCompleted = chunk.isCompleted;
    final isFocus = chunk.isFocus;

    Color dotColor;
    if (isCompleted || isActive) {
      dotColor = isFocus ? const Color(0xFF6366F1) : const Color(0xFF10B981);
    } else {
      dotColor = Colors.grey.shade300;
    }

    Widget dot = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 40 : 32,
          height: isActive ? 40 : 32,
          decoration: BoxDecoration(
            color:
            isCompleted || isActive ? dotColor : dotColor.withOpacity(0.3),
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: dotColor, width: 2) : null,
            boxShadow: isActive
                ? [
              BoxShadow(
                color: dotColor.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ]
                : [],
          ),
          child: Center(
            child: Icon(
              isCompleted
                  ? Icons.check_rounded
                  : isFocus
                  ? Icons.bolt_rounded
                  : Icons.coffee_rounded,
              size: isActive ? 20 : 16,
              color: isCompleted || isActive
                  ? Colors.white
                  : Colors.grey.shade500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${chunk.minutes}m',
          style: TextStyle(
            fontSize: 10,
            color: isActive ? dotColor : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );

    if (isActive && _phase != FocusPhase.idle) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _pulseAnimation.value, child: child),
        child: dot,
      );
    }

    return dot;
  }

  Widget _timelineLegend(Color color, IconData icon, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ]);

  Widget _buildSetupCard() {
    final hours = _sessionMinutes ~/ 60;
    final minutes = _sessionMinutes % 60;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Session Duration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildTimeUnit(
              label: 'HH',
              value: hours,
              onIncrement: () => _onSessionChanged(_sessionMinutes + 60),
              onDecrement: () {
                if (_sessionMinutes - 60 >= 5)
                  _onSessionChanged(_sessionMinutes - 60);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(':',
                  style:
                  TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            ),
            _buildTimeUnit(
              label: 'MM',
              value: minutes,
              onIncrement: () => _onSessionChanged(_sessionMinutes + 5),
              onDecrement: () {
                if (_sessionMinutes - 5 >= 5)
                  _onSessionChanged(_sessionMinutes - 5);
              },
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 14, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                _techniqueLabel,
                style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildTimeUnit({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) =>
      Column(children: [
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 32),
          color: const Color(0xFF6366F1),
        ),
        Text(value.toString().padLeft(2, '0'),
            style:
            const TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          color: const Color(0xFF6366F1),
        ),
      ]);

  Widget _buildQuoteCard() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.07),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.format_quote, color: Color(0xFF6366F1), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_currentQuote,
              style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF6366F1))),
        ),
      ]),
    ),
  );

  Widget _buildPausedBadge() => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.orange.withOpacity(0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: const [
      Icon(Icons.pause_circle_outline, color: Colors.orange, size: 18),
      SizedBox(width: 6),
      Text('Paused',
          style: TextStyle(
              color: Colors.orange, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildControls() {
    if (_phase == FocusPhase.idle || _phase == FocusPhase.finished) {
      return ElevatedButton.icon(
        onPressed: _startFocus,
        icon: const Icon(Icons.play_arrow),
        label: Text(_phase == FocusPhase.finished
            ? 'Start New Session'
            : 'Start Focus Session'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
            foregroundColor: const Color(0xFF10B981),
            side: const BorderSide(color: Color(0xFF10B981)),
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
    ]);
  }

  Widget _buildHistory() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Session History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              child:
              const Icon(Icons.timer, color: Color(0xFF6366F1)),
            ),
            title: Text('${record.sessionMinutes} min focused'),
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

class _CircleTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPaused;

  _CircleTimerPainter(
      {required this.progress, required this.color, this.isPaused = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(0.12)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = isPaused ? color.withOpacity(0.45) : color
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CircleTimerPainter old) =>
      old.progress != progress ||
          old.color != color ||
          old.isPaused != isPaused;
}