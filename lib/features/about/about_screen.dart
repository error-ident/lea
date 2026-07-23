import 'package:flutter/material.dart';
import 'package:lea_design/lea_design.dart';
import 'package:url_launcher/url_launcher.dart';
import '../splash/lea_mark.dart';

/// Экран «О приложении»: философия, приватность, методика прогноза,
/// научные источники и атрибуция материалов.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('О приложении')),
      body: ListView(
        padding: const EdgeInsets.all(LeaSpace.xl),
        children: [
          // шапка с логотипом
          Center(
            child: Column(
              children: [
                LeaMark(size: 88, dark: dark),
                const SizedBox(height: LeaSpace.md),
                Text('Лея',
                    style: LeaType.display.copyWith(
                        color: lea.textPrimary, fontWeight: FontWeight.w900)),
                const SizedBox(height: LeaSpace.xs),
                Text('Тихий дневник цикла',
                    style: LeaType.caption
                        .copyWith(color: lea.textSecondary)),
                const SizedBox(height: LeaSpace.xs),
                Text('Версия 1.0.0',
                    style: LeaType.caption
                        .copyWith(color: lea.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: LeaSpace.xxl),

          _Section(
            title: 'О Лее',
            child: Text(
              'Лея — спокойный офлайн-дневник менструального цикла. '
              'Без облака, без рекламы, без лишнего шума. Только вы и ваши '
              'наблюдения, бережно сохранённые на вашем устройстве.',
              style: LeaType.body.copyWith(color: lea.textSecondary),
            ),
          ),

          _Section(
            title: 'Приватность',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Лея не собирает и не передаёт ваши данные. Всё, что вы '
                  'записываете — циклы, симптомы, заметки — хранится только '
                  'на вашем устройстве, в зашифрованной базе данных.',
                  style: LeaType.body.copyWith(color: lea.textSecondary),
                ),
                const SizedBox(height: LeaSpace.md),
                _Bullet('У приложения нет серверов, аккаунтов, рекламы и '
                    'аналитики. Разработчик не имеет доступа к вашим '
                    'записям и не может их видеть.', lea),
                _Bullet('Интернет используется только если вы сами решите '
                    'сделать резервную копию на свой Яндекс.Диск. Копия '
                    'шифруется, доступ к ней есть только у вас.', lea),
                _Bullet('Разрешения запрашиваются только по необходимости: '
                    'уведомления — для напоминаний, биометрия — для защиты '
                    'входа (по вашему выбору).', lea),
                _Bullet('Вы в любой момент можете удалить все данные, '
                    'очистив данные приложения в настройках телефона. '
                    'После этого не остаётся ничего.', lea),
                const SizedBox(height: LeaSpace.xs),
                Text(
                  'Лея создана как приватное пространство: ваши записи '
                  'принадлежат только вам.',
                  style: LeaType.body.copyWith(color: lea.textSecondary),
                ),
              ],
            ),
          ),

          _Section(
            title: 'Как считается прогноз',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Прогноз строится по вашим прошлым циклам, а не по '
                  'усреднённым «28 дням».',
                  style: LeaType.body.copyWith(color: lea.textSecondary),
                ),
                const SizedBox(height: LeaSpace.sm),
                _Bullet('Длина цикла — медиана последних 6 циклов. Прогноз '
                    'работает и с одним циклом, но чем больше истории, тем '
                    'уже интервал.', lea),
                _Bullet('Овуляция — не фиксированные «−14», а лютеиновая '
                    'фаза по длине цикла (13–15 дней).', lea),
                _Bullet('Фертильное окно — 5 дней до овуляции и день овуляции '
                    '(классическое окно, Mihm 2011). Лея добавляет ещё один '
                    'день после: момент овуляции мы вычисляем по календарю, '
                    'а не измеряем, и он может сдвинуться. Этот день — '
                    'поправка на погрешность оценки, а не расширение '
                    'фертильного периода.', lea),
                _Bullet('Прогноз — интервал, а не одна дата. Ширина считается '
                    'по вашему разбросу длин циклов (устойчивая мера — MAD): '
                    'ровные циклы дают узкое окно, нерегулярные — широкое. '
                    'Это не перестраховка: у 46% женщин, считающих свои циклы '
                    'регулярными, разброс составляет 7 дней и больше '
                    '(Creinin, 2004).', lea),
                _Bullet('Пропущенные отметки распознаются: цикл, близкий к '
                    'удвоенной вашей медиане, считается «склейкой» из-за '
                    'забытой отметки и не искажает прогноз.', lea),
                _Bullet('Если цикл вышел за прогнозное окно, Лея честно '
                    'говорит о задержке, а не продолжает обещать «со дня '
                    'на день».', lea),
                const SizedBox(height: LeaSpace.md),
                Container(
                  padding: const EdgeInsets.all(LeaSpace.md),
                  decoration: BoxDecoration(
                    color: lea.surface,
                    borderRadius: LeaRadius.cardBR,
                    border: Border.all(color: lea.border),
                  ),
                  child: Text(
                    'Прогноз — это оценка, а не медицинский совет и не метод '
                    'контрацепции. При вопросах о здоровье обращайтесь '
                    'к врачу.',
                    style: LeaType.caption
                        .copyWith(color: lea.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          _Section(
            title: 'Научные материалы',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Методика прогноза опирается на открытые исследования '
                  'на больших когортах реальных данных. Нажмите, чтобы '
                  'открыть источник:',
                  style: LeaType.body.copyWith(color: lea.textSecondary),
                ),
                const SizedBox(height: LeaSpace.md),
                _Ref(
                  'Grieger & Norman (2020). Menstrual Cycle Length and '
                  'Patterns in a Global Cohort of Women Using a Mobile '
                  'Phone App.',
                  'JMIR · doi:10.2196/17109',
                  'https://www.jmir.org/2020/6/e17109/',
                  lea,
                ),
                _Ref(
                  'Sohda, Suzuki & Igari (2017). Relationship Between the '
                  'Menstrual Cycle and Timing of Ovulation Revealed by New '
                  'Protocols.',
                  'JMIR · doi:10.2196/jmir.7468',
                  'https://www.jmir.org/2017/11/e391/',
                  lea,
                ),
                _Ref(
                  'Bull et al. (2019). Real-world menstrual cycle '
                  'characteristics of more than 600,000 menstrual cycles.',
                  'npj Digital Medicine · doi:10.1038/s41746-019-0152-7',
                  'https://www.nature.com/articles/s41746-019-0152-7',
                  lea,
                ),
                _Ref(
                  'Symul et al. (2019). Assessment of menstrual health '
                  'status and evolution through mobile apps.',
                  'npj Digital Medicine · doi:10.1038/s41746-019-0139-4',
                  'https://www.nature.com/articles/s41746-019-0139-4',
                  lea,
                ),
                _Ref(
                  'Li et al. (2021). A predictive, generative model for '
                  'menstrual cycle lengths (Clue / Columbia). Модель учитывает '
                  'пропущенные отметки — на этой идее основан фильтр «склеек».',
                  'arXiv:2102.12439',
                  'https://arxiv.org/abs/2102.12439',
                  lea,
                ),
                _Ref(
                  'Creinin, Keverline & Meyn (2004). How regular is regular? '
                  'An analysis of menstrual cycle regularity. Обоснование '
                  'того, почему прогноз — интервал, а не одна дата.',
                  'Contraception · doi:10.1016/j.contraception.2004.04.012',
                  'https://doi.org/10.1016/j.contraception.2004.04.012',
                  lea,
                ),
                _Ref(
                  'Mihm, Gangooly & Muttukrishna (2011). The normal menstrual '
                  'cycle in women. Физиология фаз цикла — основа описаний '
                  'фаз в приложении.',
                  'Anim Reprod Sci · doi:10.1016/j.anireprosci.2010.08.030',
                  'https://doi.org/10.1016/j.anireprosci.2010.08.030',
                  lea,
                ),
              ],
            ),
          ),

          _Section(
            title: 'Материалы и атрибуция',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bullet('Анимированные эмодзи — Google Noto Emoji '
                    '(Animated), лицензия CC BY 4.0.', lea),
                _Bullet('Шрифты — Nunito и Golos Text, лицензия '
                    'SIL Open Font License 1.1.', lea),
                _Bullet('Хранение данных — SQLCipher (шифрование), '
                    'drift.', lea),
              ],
            ),
          ),

          const SizedBox(height: LeaSpace.xl),
          Center(
            child: Text('Сделано с заботой 🌸',
                style: LeaType.caption.copyWith(color: lea.textTertiary)),
          ),
          const SizedBox(height: LeaSpace.xl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Padding(
      padding: const EdgeInsets.only(bottom: LeaSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: LeaType.sectionLabel
                  .copyWith(color: lea.textTertiary)),
          const SizedBox(height: LeaSpace.md),
          child,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, this.lea);
  final String text;
  final dynamic lea;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LeaSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: LeaSpace.sm),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: lea.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(text,
                style: LeaType.body.copyWith(color: lea.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _Ref extends StatelessWidget {
  const _Ref(this.title, this.source, this.url, this.lea);
  final String title;
  final String source;
  final String url;
  final dynamic lea;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LeaSpace.md),
      child: InkWell(
        borderRadius: LeaRadius.cardBR,
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: LeaType.caption.copyWith(
                      color: lea.textSecondary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.link, size: 13, color: lea.accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(source,
                        style: LeaType.caption
                            .copyWith(color: lea.accent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
