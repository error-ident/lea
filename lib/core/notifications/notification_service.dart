import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../prediction/cycle_prediction.dart';

/// Одно повторяющееся ежедневное напоминание (таблетка/вода): время + текст.
class TimedReminder {
  const TimedReminder({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  /// Уникальный id (для отмены/планирования уведомления).
  final int id;
  final String label;
  final int hour;
  final int minute;
  final bool enabled;

  TimedReminder copyWith({
    String? label,
    int? hour,
    int? minute,
    bool? enabled,
  }) =>
      TimedReminder(
        id: id,
        label: label ?? this.label,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory TimedReminder.fromJson(Map<String, dynamic> j) => TimedReminder(
        id: j['id'] as int,
        label: j['label'] as String? ?? '',
        hour: j['hour'] as int? ?? 9,
        minute: j['minute'] as int? ?? 0,
        enabled: j['enabled'] as bool? ?? true,
      );
}

class NotificationSettings {
  const NotificationSettings({
    this.periodEnabled = true,
    this.ovulationEnabled = false,
    this.daysBeforePeriod = 2,
    this.daysBeforeOvulation = 1,
    this.hour = 10,
    this.minute = 0,
    this.periodText = 'Скоро месячные',
    this.ovulationText = 'Приближается овуляция',
    this.pills = const [],
    this.waters = const [],
  });

  final bool periodEnabled;
  final bool ovulationEnabled;
  final int daysBeforePeriod;
  final int daysBeforeOvulation;
  final int hour;
  final int minute;

  /// Редактируемые тексты напоминаний.
  final String periodText;
  final String ovulationText;

  /// Списки таблеток и воды (каждое — своё время и текст).
  final List<TimedReminder> pills;
  final List<TimedReminder> waters;

  NotificationSettings copyWith({
    bool? periodEnabled,
    bool? ovulationEnabled,
    int? daysBeforePeriod,
    int? daysBeforeOvulation,
    int? hour,
    int? minute,
    String? periodText,
    String? ovulationText,
    List<TimedReminder>? pills,
    List<TimedReminder>? waters,
  }) =>
      NotificationSettings(
        periodEnabled: periodEnabled ?? this.periodEnabled,
        ovulationEnabled: ovulationEnabled ?? this.ovulationEnabled,
        daysBeforePeriod: daysBeforePeriod ?? this.daysBeforePeriod,
        daysBeforeOvulation: daysBeforeOvulation ?? this.daysBeforeOvulation,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        periodText: periodText ?? this.periodText,
        ovulationText: ovulationText ?? this.ovulationText,
        pills: pills ?? this.pills,
        waters: waters ?? this.waters,
      );

  Map<String, dynamic> toJson() => {
        'period': periodEnabled,
        'ovulation': ovulationEnabled,
        'daysBefore': daysBeforePeriod,
        'daysBeforeOvu': daysBeforeOvulation,
        'hour': hour,
        'minute': minute,
        'periodText': periodText,
        'ovulationText': ovulationText,
        'pills': pills.map((e) => e.toJson()).toList(),
        'waters': waters.map((e) => e.toJson()).toList(),
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> j) =>
      NotificationSettings(
        periodEnabled: j['period'] as bool? ?? true,
        ovulationEnabled: j['ovulation'] as bool? ?? false,
        daysBeforePeriod: j['daysBefore'] as int? ?? 2,
        daysBeforeOvulation: j['daysBeforeOvu'] as int? ?? 1,
        hour: j['hour'] as int? ?? 10,
        minute: j['minute'] as int? ?? 0,
        periodText: j['periodText'] as String? ?? 'Скоро месячные',
        ovulationText:
            j['ovulationText'] as String? ?? 'Приближается овуляция',
        pills: (j['pills'] as List? ?? const [])
            .map((e) => TimedReminder.fromJson(e as Map<String, dynamic>))
            .toList(),
        waters: (j['waters'] as List? ?? const [])
            .map((e) => TimedReminder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String encode() => jsonEncode(toJson());
  static NotificationSettings decode(String s) =>
      NotificationSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const _channelId = 'lea_reminders_v2';

  Future<void> init() async {
    tz.initializeTimeZones();
    // КРИТИЧНО: устанавливаем реальную зону устройства. Без этого tz.local =
    // UTC, и запланированные уведомления уезжают на смещение зоны (СПб +3ч)
    // — часто в прошлое, и не срабатывают.
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // на крайний случай — не падаем, останется UTC
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Явно создаём канал с высокой важностью — иначе уведомления тихие
    // (падают в шторку, но не всплывают баннером и не идут на часы).
    final android_ = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android_?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Напоминания',
        description: 'Напоминания о цикле',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // разрешение на уведомления (Android 13+). Точные будильники выданы
    // автоматически через USE_EXACT_ALARM в манифесте — просить не нужно.
    final granted = await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? true;
  }

  /// Выданы ли разрешения на уведомления (для показа баннера-подсказки).
  Future<bool> hasPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return (await android.areNotificationsEnabled()) ?? false;
    }
    return true;
  }

  /// Перепланировать все уведомления по текущему прогнозу.
  Future<void> reschedule(
    CyclePrediction prediction,
    NotificationSettings s,
  ) async {
    await _plugin.cancelAll();

    if (s.periodEnabled) {
      final when = prediction.nextPeriodStart
          .subtract(Duration(days: s.daysBeforePeriod));
      await _scheduleOnce(
        id: 1,
        date: when,
        hour: s.hour,
        minute: s.minute,
        body: s.periodText,
      );
    }
    if (s.ovulationEnabled) {
      final when = prediction.ovulationWindow.start
          .subtract(Duration(days: s.daysBeforeOvulation));
      await _scheduleOnce(
        id: 2,
        date: when,
        hour: s.hour,
        minute: s.minute,
        body: s.ovulationText,
      );
    }
    // таблетки — ежедневно в заданное время
    for (final p in s.pills) {
      if (p.enabled) {
        await _scheduleDaily(
          id: p.id,
          hour: p.hour,
          minute: p.minute,
          body: p.label.isEmpty ? 'Время принять таблетку' : p.label,
        );
      }
    }
    // вода — ежедневно
    for (final w in s.waters) {
      if (w.enabled) {
        await _scheduleDaily(
          id: w.id,
          hour: w.hour,
          minute: w.minute,
          body: w.label.isEmpty ? 'Время попить воды' : w.label,
        );
      }
    }
  }

  /// Разовое уведомление в конкретную дату/время.
  Future<void> _scheduleOnce({
    required int id,
    required DateTime date,
    required int hour,
    required int minute,
    required String body,
  }) async {
    final when = tz.TZDateTime(
        tz.local, date.year, date.month, date.day, hour, minute);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      'Лея',
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Ежедневное повторяющееся уведомление в заданное время.
  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (when.isBefore(now)) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      'Лея',
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // повтор каждый день
    );
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Напоминания',
          channelDescription: 'Напоминания о цикле',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          // showWhen выводит время; фулл-скрин не нужен, но high даёт heads-up
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  Future<void> cancelAll() => _plugin.cancelAll();
}
