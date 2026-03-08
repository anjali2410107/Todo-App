import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
}

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _sessionMinutes = 25;
  int _breakMinutes = 5;

  FocusPhase _phase = FocusPhase.idle;
  int _secondsLeft = 0;
  int _totalSeconds = 0;
  Timer? _timer;

  final List<SessionRecord> _history = [];

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

  void _startFocus() {
    setState(() {
      _phase = FocusPhase.focusing;
      _secondsLeft = _sessionMinutes * 60;
      _totalSeconds = _secondsLeft;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_secondsLeft <= 0) {
      if (_phase == FocusPhase.focusing) {
        _startBreak();
      } else if (_phase == FocusPhase.onBreak) {
        _finishSession(skippedBreak: false);
      }
      return;
    }
    setState(() => _secondsLeft--);
  }

  void _startBreak() {
    _timer?.cancel();
    NotificationService.showImmediateNotification(
      id: 9001,
      title: "Break Time! 🎉",
      body: "Great work! Take a ${_breakMinutes}-minute break.",
    );
    setState(() {
      _phase = FocusPhase.onBreak;
      _secondsLeft = _breakMinutes * 60;
      _totalSeconds = _secondsLeft;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _skipBreak() {
    _finishSession(skippedBreak: true);
  }

  void _finishSession({required bool skippedBreak}) {
    _timer?.cancel();
    NotificationService.showImmediateNotification(
      id: 9002,
      title: skippedBreak ? "Break Skipped" : "Break Over! 💪",
      body: skippedBreak
          ? "Break skipped. Ready for another session?"
          : "Break's done! Ready to focus again?",
    );
    _history.insert(
      0,
      SessionRecord(
        sessionMinutes: _sessionMinutes,
        breakMinutes: skippedBreak ? 0 : _breakMinutes,
        completedAt: DateTime.now(),
        skippedBreak: skippedBreak,
      ),
    );
    setState(() {
      _phase = FocusPhase.finished;
      _secondsLeft = 0;
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _phase = FocusPhase.idle;
      _secondsLeft = 0;
      _totalSeconds = 0;
    });
  }

  void _pauseResume() {
    if (_timer?.isActive == true) {
      _timer?.cancel();
      setState(() {});
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
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

  Color get _phaseColor {
    switch (_phase) {
      case FocusPhase.focusing:
        return Colors.deepPurple;
      case FocusPhase.onBreak:
        return Colors.teal;
      case FocusPhase.finished:
        return Colors.green;
      case FocusPhase.idle:
        return Colors.grey;
    }
  }

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
            _buildTimer(),
            const SizedBox(height: 24),
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

  Widget _buildTimer() {
    final progress = _totalSeconds > 0 ? _secondsLeft / _totalSeconds : 0.0;
    return Center(
      child: SizedBox(
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  child: Text(':', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
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
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ..._history.map((record) {
          final time =
              '${record.completedAt.hour.toString().padLeft(2, '0')}:${record.completedAt.minute.toString().padLeft(2, '0')}';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  ? const Icon(Icons.skip_next, color: Colors.orange, size: 18)
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

  _CircleTimerPainter({required this.progress, required this.color});

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
      ..color = color
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
      old.progress != progress || old.color != color;
}