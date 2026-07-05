import 'tables.dart';

/// Описание встроенной категории для сидинга при первом запуске.
class SeedCategory {
  const SeedCategory({
    required this.code,
    required this.titleKey,
    required this.type,
    required this.iconRef,
    required this.sortOrder,
    this.options = const [],
  });

  final String code;
  final String titleKey;
  final TrackingType type;
  final String iconRef;
  final int sortOrder;
  final List<SeedOption> options;
}

class SeedOption {
  const SeedOption({
    required this.code,
    required this.titleKey,
    this.iconRef, // имя анимированного эмодзи (AnimatedEmojis.<iconRef>)
    this.colorHex,
  });

  final String code;
  final String titleKey;
  final String? iconRef;
  final String? colorHex;
}

/// Встроенные категории. iconRef у опций = имя эмодзи из пакета animated_emoji.
/// Каждый эмодзи подобран осмысленно; на основных экранах — без повторов.
const kSeedCategories = <SeedCategory>[
  // ---- Месячные ----
  SeedCategory(
    code: 'flow',
    titleKey: 'cat_flow',
    type: TrackingType.singleChoice,
    iconRef: 'rose',
    sortOrder: 10,
    options: [
      SeedOption(code: 'spotting', titleKey: 'flow_spotting', iconRef: 'snail', colorHex: '#F3B7A4'),
      SeedOption(code: 'light', titleKey: 'flow_light', iconRef: 'pinch'),
      SeedOption(code: 'medium', titleKey: 'flow_medium', iconRef: 'sunrise'),
      SeedOption(code: 'heavy', titleKey: 'flow_heavy', iconRef: 'volcano'),
      SeedOption(code: 'clots', titleKey: 'flow_clots', iconRef: 'debris'),
    ],
  ),
  // ---- Выделения ----
  SeedCategory(
    code: 'discharge',
    titleKey: 'cat_discharge',
    type: TrackingType.singleChoice,
    iconRef: 'bubbles',
    sortOrder: 20,
    options: [
      SeedOption(code: 'none', titleKey: 'discharge_none', iconRef: 'crossMark'),
      SeedOption(code: 'creamy', titleKey: 'discharge_creamy', iconRef: 'iceCream'),
      SeedOption(code: 'eggwhite', titleKey: 'discharge_eggwhite', iconRef: 'cooking'),
      SeedOption(code: 'sticky', titleKey: 'discharge_sticky', iconRef: 'pancakes'),
      SeedOption(code: 'watery', titleKey: 'discharge_watery', iconRef: 'ocean'),
      SeedOption(code: 'unusual', titleKey: 'discharge_unusual', iconRef: 'flyingSaucer'),
    ],
  ),
  // ---- Настроение ----
  SeedCategory(
    code: 'mood',
    titleKey: 'cat_mood',
    type: TrackingType.multiChoice,
    iconRef: 'smile',
    sortOrder: 30,
    options: [
      SeedOption(code: 'calm', titleKey: 'mood_calm', iconRef: 'relieved'),
      SeedOption(code: 'happy', titleKey: 'mood_happy', iconRef: 'smile'),
      SeedOption(code: 'playful', titleKey: 'mood_playful', iconRef: 'winkyTongue'),
      SeedOption(code: 'loving', titleKey: 'mood_loving', iconRef: 'heartFace'),
      SeedOption(code: 'energetic', titleKey: 'mood_energetic', iconRef: 'starStruck'),
      SeedOption(code: 'tired', titleKey: 'mood_tired', iconRef: 'yawn'),
      SeedOption(code: 'apathy', titleKey: 'mood_apathy', iconRef: 'expressionless'),
      SeedOption(code: 'sad', titleKey: 'mood_sad', iconRef: 'sad'),
      SeedOption(code: 'anxious', titleKey: 'mood_anxious', iconRef: 'anxiousWithSweat'),
      SeedOption(code: 'irritated', titleKey: 'mood_irritated', iconRef: 'unamused'),
      SeedOption(code: 'angry', titleKey: 'mood_angry', iconRef: 'rage'),
      SeedOption(code: 'tearful', titleKey: 'mood_tearful', iconRef: 'pleading'),
      SeedOption(code: 'swings', titleKey: 'mood_swings', iconRef: 'rollerCoaster'),
      SeedOption(code: 'vulnerable', titleKey: 'mood_vulnerable', iconRef: 'woozy'),
      SeedOption(code: 'confident', titleKey: 'mood_confident', iconRef: 'sunglassesFace'),
    ],
  ),
  // ---- Желания / тяга ----
  SeedCategory(
    code: 'cravings',
    titleKey: 'cat_cravings',
    type: TrackingType.multiChoice,
    iconRef: 'birthdayCake',
    sortOrder: 40,
    options: [
      SeedOption(code: 'sweet', titleKey: 'craving_sweet', iconRef: 'doughnut'),
      SeedOption(code: 'salty', titleKey: 'craving_salty', iconRef: 'popcorn'),
      SeedOption(code: 'carbs', titleKey: 'craving_carbs', iconRef: 'spaghetti'),
      SeedOption(code: 'cry', titleKey: 'craving_cry', iconRef: 'loudlyCrying'),
      SeedOption(code: 'affection', titleKey: 'craving_affection', iconRef: 'kissingHeart'),
      SeedOption(code: 'sex', titleKey: 'craving_sex', iconRef: 'fire'),
      SeedOption(code: 'solitude', titleKey: 'craving_solitude', iconRef: 'hairyCreature'),
      SeedOption(code: 'coffee', titleKey: 'craving_coffee', iconRef: 'hotBeverage'),
      SeedOption(code: 'alcohol', titleKey: 'craving_alcohol', iconRef: 'wineGlass'),
      SeedOption(code: 'nothing', titleKey: 'craving_nothing', iconRef: 'dottedLineFace'),
    ],
  ),
  // ---- Симптомы ----
  SeedCategory(
    code: 'symptoms',
    titleKey: 'cat_symptoms',
    type: TrackingType.multiChoice,
    iconRef: 'thermometerFace',
    sortOrder: 50,
    options: [
      SeedOption(code: 'cramps', titleKey: 'symptom_cramps', iconRef: 'electricity'),
      SeedOption(code: 'headache', titleKey: 'symptom_headache', iconRef: 'thermometerFace'),
      SeedOption(code: 'breast', titleKey: 'symptom_breast', iconRef: 'cherries'),
      SeedOption(code: 'bloating', titleKey: 'symptom_bloating', iconRef: 'balloon'),
      SeedOption(code: 'backache', titleKey: 'symptom_backache', iconRef: 'bone'),
      SeedOption(code: 'acne', titleKey: 'symptom_acne', iconRef: 'splatter'),
      SeedOption(code: 'weakness', titleKey: 'symptom_weakness', iconRef: 'weary'),
      SeedOption(code: 'drowsy', titleKey: 'symptom_drowsy', iconRef: 'sleepy'),
      SeedOption(code: 'insomnia', titleKey: 'symptom_insomnia', iconRef: 'moonFaceLastQuarter'),
      SeedOption(code: 'nausea', titleKey: 'symptom_nausea', iconRef: 'vomit'),
      SeedOption(code: 'dizzy', titleKey: 'symptom_dizzy', iconRef: 'dizzyFace'),
      SeedOption(code: 'appetite_up', titleKey: 'symptom_appetite_up', iconRef: 'steamingBowl'),
      SeedOption(code: 'appetite_down', titleKey: 'symptom_appetite_down', iconRef: 'crossMark'),
      SeedOption(code: 'hot_flash', titleKey: 'symptom_hot_flash', iconRef: 'hotFace'),
    ],
  ),
  // ---- Пищеварение ----
  SeedCategory(
    code: 'digestion',
    titleKey: 'cat_digestion',
    type: TrackingType.multiChoice,
    iconRef: 'steamingBowl',
    sortOrder: 60,
    options: [
      SeedOption(code: 'normal', titleKey: 'digestion_normal', iconRef: 'greenSalad'),
      SeedOption(code: 'constipation', titleKey: 'digestion_constipation', iconRef: 'weary'),
      SeedOption(code: 'diarrhea', titleKey: 'digestion_diarrhea', iconRef: 'poop'),
      SeedOption(code: 'gas', titleKey: 'digestion_gas', iconRef: 'exhale'),
    ],
  ),
  // ---- Секс ----
  SeedCategory(
    code: 'sex',
    titleKey: 'cat_sex',
    type: TrackingType.multiChoice,
    iconRef: 'redHeart',
    sortOrder: 70,
    options: [
      SeedOption(code: 'had_sex', titleKey: 'sex_had', iconRef: 'redHeart'),
      SeedOption(code: 'protected', titleKey: 'sex_protected', iconRef: 'checkMark'),
      SeedOption(code: 'unprotected', titleKey: 'sex_unprotected', iconRef: 'warning'),
      SeedOption(code: 'masturbation', titleKey: 'sex_masturbation', iconRef: 'bitingLip'),
      SeedOption(code: 'orgasm', titleKey: 'sex_orgasm', iconRef: 'fireworks'),
      SeedOption(code: 'high_drive', titleKey: 'sex_high_drive', iconRef: 'fire'),
      SeedOption(code: 'low_drive', titleKey: 'sex_low_drive', iconRef: 'coldFace'),
    ],
  ),
  // ---- Активность ----
  SeedCategory(
    code: 'activity',
    titleKey: 'cat_activity',
    type: TrackingType.multiChoice,
    iconRef: 'muscle',
    sortOrder: 80,
    options: [
      SeedOption(code: 'rest', titleKey: 'activity_rest', iconRef: 'sleep'),
      SeedOption(code: 'walk', titleKey: 'activity_walk', iconRef: 'footprints'),
      SeedOption(code: 'cardio', titleKey: 'activity_cardio', iconRef: 'fire'),
      SeedOption(code: 'strength', titleKey: 'activity_strength', iconRef: 'muscle'),
      SeedOption(code: 'yoga', titleKey: 'activity_yoga', iconRef: 'bug'),
      SeedOption(code: 'swim', titleKey: 'activity_swim', iconRef: 'fish'),
    ],
  ),
  // ---- Образ жизни ----
  SeedCategory(
    code: 'lifestyle',
    titleKey: 'cat_lifestyle',
    type: TrackingType.multiChoice,
    iconRef: 'sparkles',
    sortOrder: 90,
    options: [
      SeedOption(code: 'stress', titleKey: 'life_stress', iconRef: 'anxiousWithSweat'),
      SeedOption(code: 'sick', titleKey: 'life_sick', iconRef: 'sick'),
      SeedOption(code: 'travel', titleKey: 'life_travel', iconRef: 'airplaneDeparture'),
      SeedOption(code: 'alcohol', titleKey: 'life_alcohol', iconRef: 'wineGlass'),
      SeedOption(code: 'meditation', titleKey: 'life_meditation', iconRef: 'halo'),
      SeedOption(code: 'good_sleep', titleKey: 'life_good_sleep', iconRef: 'blush'),
      SeedOption(code: 'poor_sleep', titleKey: 'life_poor_sleep', iconRef: 'tired'),
    ],
  ),
  // ---- Оральные контрацептивы ----
  SeedCategory(
    code: 'pills',
    titleKey: 'cat_pills',
    type: TrackingType.singleChoice,
    iconRef: 'checkMark',
    sortOrder: 100,
    options: [
      SeedOption(code: 'taken', titleKey: 'pills_taken', iconRef: 'checkMark'),
      SeedOption(code: 'missed', titleKey: 'pills_missed', iconRef: 'crossMark'),
    ],
  ),
  // ---- Тест на овуляцию ----
  SeedCategory(
    code: 'ovulation_test',
    titleKey: 'cat_ovulation_test',
    type: TrackingType.singleChoice,
    iconRef: 'sparkles',
    sortOrder: 110,
    options: [
      SeedOption(code: 'positive', titleKey: 'ovtest_positive', iconRef: 'plusSign'),
      SeedOption(code: 'negative', titleKey: 'ovtest_negative', iconRef: 'crossMark'),
      SeedOption(code: 'unclear', titleKey: 'ovtest_unclear', iconRef: 'shakingFace'),
    ],
  ),
  // ---- Тест на беременность ----
  SeedCategory(
    code: 'pregnancy_test',
    titleKey: 'cat_pregnancy_test',
    type: TrackingType.singleChoice,
    iconRef: 'sparkles',
    sortOrder: 120,
    options: [
      SeedOption(code: 'positive', titleKey: 'pregtest_positive', iconRef: 'plusSign'),
      SeedOption(code: 'negative', titleKey: 'pregtest_negative', iconRef: 'crossMark'),
      SeedOption(code: 'unclear', titleKey: 'pregtest_unclear', iconRef: 'thinkingFace'),
    ],
  ),
  // ---- Числовые ----
  SeedCategory(
    code: 'weight',
    titleKey: 'cat_weight',
    type: TrackingType.numeric,
    iconRef: 'balanceScale',
    sortOrder: 130,
  ),
  SeedCategory(
    code: 'bbt',
    titleKey: 'cat_bbt',
    type: TrackingType.numeric,
    iconRef: 'thermometerFace',
    sortOrder: 140,
  ),
  SeedCategory(
    code: 'water',
    titleKey: 'cat_water',
    type: TrackingType.numeric,
    iconRef: 'ocean',
    sortOrder: 150,
  ),
];
