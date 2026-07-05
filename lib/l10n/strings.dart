/// Перевод ключей справочника трекинга (категории/опции), хранящихся в БД
/// как titleKey. Весь остальной UI-текст — русские литералы в экранах.
abstract final class L {
  static const _ru = <String, String>{
    // ---- категории ----
    'cat_flow': 'Месячные',
    'cat_discharge': 'Выделения',
    'cat_mood': 'Настроение',
    'cat_cravings': 'Желания',
    'cat_symptoms': 'Симптомы',
    'cat_digestion': 'Пищеварение',
    'cat_sex': 'Секс',
    'cat_activity': 'Активность',
    'cat_lifestyle': 'Образ жизни',
    'cat_pills': 'Оральные контрацептивы',
    'cat_ovulation_test': 'Тест на овуляцию',
    'cat_pregnancy_test': 'Тест на беременность',
    'cat_weight': 'Вес',
    'cat_bbt': 'Базальная температура',
    'cat_water': 'Вода',

    // ---- месячные ----
    'flow_spotting': 'Мажущие',
    'flow_light': 'Скудные',
    'flow_medium': 'Умеренные',
    'flow_heavy': 'Обильные',
    'flow_clots': 'Сгустки',

    // ---- выделения ----
    'discharge_none': 'Нет',
    'discharge_creamy': 'Кремовые',
    'discharge_eggwhite': 'Как белок',
    'discharge_sticky': 'Липкие',
    'discharge_watery': 'Водянистые',
    'discharge_spotting': 'Мажущие',
    'discharge_unusual': 'Необычные',

    // ---- настроение ----
    'mood_calm': 'Спокойствие',
    'mood_happy': 'Радость',
    'mood_playful': 'Игривость',
    'mood_loving': 'Нежность',
    'mood_energetic': 'Энергия',
    'mood_tired': 'Усталость',
    'mood_apathy': 'Апатия',
    'mood_sad': 'Грусть',
    'mood_anxious': 'Тревога',
    'mood_irritated': 'Раздражение',
    'mood_angry': 'Всё бесит',
    'mood_tearful': 'Плаксивость',
    'mood_swings': 'Перепады',
    'mood_vulnerable': 'Уязвимость',
    'mood_confident': 'Уверенность',

    // ---- желания ----
    'craving_sweet': 'Сладкое',
    'craving_salty': 'Солёное',
    'craving_carbs': 'Углеводы',
    'craving_cry': 'Поплакать',
    'craving_affection': 'Ласки',
    'craving_sex': 'Секса',
    'craving_solitude': 'Одиночества',
    'craving_coffee': 'Кофе',
    'craving_alcohol': 'Алкоголя',
    'craving_nothing': 'Ничего',

    // ---- симптомы ----
    'symptom_cramps': 'Тянет живот',
    'symptom_headache': 'Головная боль',
    'symptom_breast': 'Болит грудь',
    'symptom_bloating': 'Вздутие',
    'symptom_backache': 'Болит спина',
    'symptom_acne': 'Прыщи',
    'symptom_weakness': 'Слабость',
    'symptom_drowsy': 'Сонливость',
    'symptom_insomnia': 'Бессонница',
    'symptom_nausea': 'Тошнота',
    'symptom_dizzy': 'Головокружение',
    'symptom_appetite_up': 'Аппетит выше',
    'symptom_appetite_down': 'Аппетит ниже',
    'symptom_hot_flash': 'Приливы',

    // ---- пищеварение ----
    'digestion_normal': 'Норма',
    'digestion_constipation': 'Запор',
    'digestion_diarrhea': 'Диарея',
    'digestion_gas': 'Газы',

    // ---- секс ----
    'sex_had': 'Был секс',
    'sex_protected': 'С защитой',
    'sex_unprotected': 'Без защиты',
    'sex_masturbation': 'Мастурбация',
    'sex_orgasm': 'Оргазм',
    'sex_high_drive': 'Сильное желание',
    'sex_low_drive': 'Низкое желание',

    // ---- активность ----
    'activity_rest': 'Отдых',
    'activity_walk': 'Прогулка',
    'activity_cardio': 'Кардио',
    'activity_strength': 'Силовая',
    'activity_yoga': 'Йога',
    'activity_swim': 'Плавание',

    // ---- образ жизни ----
    'life_stress': 'Стресс',
    'life_sick': 'Болею',
    'life_travel': 'Путешествие',
    'life_alcohol': 'Алкоголь',
    'life_meditation': 'Медитация',
    'life_good_sleep': 'Выспалась',
    'life_poor_sleep': 'Мало сна',

    // ---- оральные контрацептивы ----
    'pills_taken': 'Приняла',
    'pills_missed': 'Пропустила',

    // ---- тест на овуляцию ----
    'ovtest_positive': 'Положительный',
    'ovtest_negative': 'Отрицательный',
    'ovtest_unclear': 'Сомнительный',

    // ---- тест на беременность ----
    'pregtest_positive': 'Положительный',
    'pregtest_negative': 'Отрицательный',
    'pregtest_unclear': 'Сомнительный',
  };

  static String t(String key) => _ru[key] ?? key;
}
