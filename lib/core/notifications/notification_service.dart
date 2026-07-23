import 'dart:convert';
import 'package:flutter/foundation.dart' show ValueNotifier;

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
    this.follicularEnabled = false,
    this.lutealEnabled = false,
    this.follicularText = 'Началась фолликулярная фаза',
    this.lutealText = 'Началась лютеиновая фаза',
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

  /// Уведомления о наступлении фаз. По умолчанию ВЫКЛЮЧЕНЫ — пользователь
  /// включает сам. Текст нейтральный: сообщаем ФАКТ наступления фазы, а не
  /// то, что человек «почувствует» (см. PhaseInfo — почему это важно).
  /// Менструация и овуляция не дублируются: для них есть отдельные
  /// напоминания выше.
  final bool follicularEnabled;
  final bool lutealEnabled;
  final String follicularText;
  final String lutealText;

  /// Напоминания о воде (таблетки переехали в раздел «Лекарства»).
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
    bool? follicularEnabled,
    bool? lutealEnabled,
    String? follicularText,
    String? lutealText,
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
        follicularEnabled: follicularEnabled ?? this.follicularEnabled,
        lutealEnabled: lutealEnabled ?? this.lutealEnabled,
        follicularText: follicularText ?? this.follicularText,
        lutealText: lutealText ?? this.lutealText,
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
        'follicular': follicularEnabled,
        'luteal': lutealEnabled,
        'follicularText': follicularText,
        'lutealText': lutealText,
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
        follicularEnabled: j['follicular'] as bool? ?? false,
        lutealEnabled: j['luteal'] as bool? ?? false,
        follicularText: j['follicularText'] as String? ??
            'Началась фолликулярная фаза',
        lutealText:
            j['lutealText'] as String? ?? 'Началась лютеиновая фаза',
        waters: (j['waters'] as List? ?? const [])
            .map((e) => TimedReminder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String encode() => jsonEncode(toJson());
  static NotificationSettings decode(String s) =>
      NotificationSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class NotificationService {
  /// Средняя длительность менструации (Mihm et al. 2011 — около 5 дней).
  /// Используется только для уведомления о начале фолликулярной фазы.
  static const int _avgMenstruationDays = 5;

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

    const android = AndroidInitializationSettings('@mipmap/ic_launcher_cream');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Приложение могли открыть ТАПОМ по уведомлению, когда оно было закрыто —
    // тогда onDidReceiveNotificationResponse не сработает, и payload надо
    // забрать отдельно.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final resp = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && resp != null) {
      _onTap(resp);
    }

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

    // --- Уведомления о наступлении фаз (по умолчанию выключены) ---
    // Сообщаем ФАКТ наступления фазы, без обещаний самочувствия.
    // Менструация/овуляция не дублируются — для них напоминания выше.
    if (s.follicularEnabled) {
      // Фолликулярная фаза «ощутимо» начинается после менструации.
      // Длина менструации в прогнозе не хранится, берём среднюю (~5 дней,
      // Mihm et al. 2011) — для уведомления-факта этого достаточно.
      final when = prediction.nextPeriodStart
          .add(const Duration(days: _avgMenstruationDays));
      await _scheduleOnce(
        id: 10,
        date: when,
        hour: s.hour,
        minute: s.minute,
        body: s.follicularText,
      );
    }
    if (s.lutealEnabled) {
      // Лютеиновая начинается сразу после овуляции.
      final when =
          prediction.ovulationWindow.end.add(const Duration(days: 1));
      await _scheduleOnce(
        id: 11,
        date: when,
        hour: s.hour,
        minute: s.minute,
        body: s.lutealText,
      );
    }
    // Лекарства планируются отдельно — см. scheduleMedications().
    // Здесь их нет, потому что они живут в БД, а не в настройках уведомлений.
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
  /// Запланировать напоминания о приёме лекарств.
  ///
  /// Отдельно от reschedule(): лекарства живут в БД, а не в настройках
  /// уведомлений. Вызывать после любого изменения списка препаратов.
  ///
  /// id уведомлений начинаются с 1000, чтобы не пересечься с прогнозными
  /// (1, 2), фазовыми (10, 11) и напоминаниями о воде.
  Future<void> scheduleMedications(
    List<({int id, String name, String times, bool remind})> meds,
  ) async {
    // Снимаем прошлые напоминания о лекарствах.
    for (var i = _medIdBase; i < _medIdBase + _medIdRange; i++) {
      await _plugin.cancel(i);
    }

    var slot = 0;
    for (final m in meds) {
      if (!m.remind) continue;
      for (final t in m.times.split(',')) {
        final parts = t.trim().split(':');
        if (parts.length != 2) continue;
        final h = int.tryParse(parts[0]);
        final min = int.tryParse(parts[1]);
        if (h == null || min == null) continue;
        if (slot >= _medIdRange) return; // защита от переполнения диапазона
        await _scheduleDaily(
          id: _medIdBase + slot,
          hour: h,
          minute: min,
          body: m.name.isEmpty ? 'Время принять лекарство' : m.name,
          // По тапу откроем дневник сегодняшнего дня, где можно отметить приём.
          payload: 'med:${m.id}',
        );
        slot++;
      }
    }
  }

  static const int _medIdBase = 1000;
  static const int _medIdRange = 200;

  /// Payload уведомления, по которому открыли приложение.
  ///
  /// Полноценная кнопка «Принял» прямо в шторке потребовала бы записи в БД
  /// из фонового изолята. У нас БД зашифрована ключом из Keystore, а он
  /// может быть недоступен при заблокированном экране; плюс SQLCipher в двух
  /// изолятах одновременно рискует повреждением данных. Поэтому уведомление
  /// не пишет в БД само, а ОТКРЫВАЕТ приложение на нужном дне — один тап
  /// вместо трёх, и никакого риска для данных.
  static final ValueNotifier<String?> lastPayload =
      ValueNotifier<String?>(null);

  static void _onTap(NotificationResponse r) {
    final p = r.payload;
    if (p != null && p.isNotEmpty) lastPayload.value = p;
  }

  /// Можно ли планировать ТОЧНЫЕ будильники (Android 12+ может запретить).
  /// Кэшируется, чтобы не дёргать платформу на каждое уведомление.
  bool? _exactAllowed;

  Future<bool> canScheduleExact() async {
    if (_exactAllowed != null) return _exactAllowed!;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      _exactAllowed = true; // iOS/др. — точность не ограничивается так
      return true;
    }
    try {
      _exactAllowed = await android.canScheduleExactNotifications() ?? true;
    } catch (_) {
      _exactAllowed = false;
    }
    return _exactAllowed!;
  }

  /// Сбросить кэш (после того как пользователь мог выдать разрешение).
  void invalidateExactCache() => _exactAllowed = null;

  /// Режим планирования: точный, если разрешён; иначе неточный (лучше
  /// приблизительное уведомление, чем отсутствие уведомления на EMUI/MIUI).
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    final exact = await canScheduleExact();
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

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
      androidScheduleMode: await _resolveScheduleMode(),
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
    String? payload,
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
      androidScheduleMode: await _resolveScheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // повтор каждый день
      payload: payload,
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
