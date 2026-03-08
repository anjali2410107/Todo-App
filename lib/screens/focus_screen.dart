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