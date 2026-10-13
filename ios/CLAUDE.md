# CLAUDE.md — брифінг для Claude на Mac

> Цей файл — інструкція для Claude (Claude Code / Claude desktop), коли власник відкриє цю папку на Mac.
> Якщо ти Claude і читаєш це — спершу прочитай файл повністю, потім привітайся й коротко скажи, на якому етапі проєкт і що пропонуєш зробити далі (див. розділ «Що робити далі»).

## Правила спілкування

- **Розмовляй з власником виключно українською.** Коментарі в коді — теж українською.
- Власник — не професійний iOS-розробник. Пояснюй кроки в Xcode і App Store Connect простими словами, по одному кроку, з назвами кнопок і меню так, як вони звучать в інтерфейсі (англійською, бо Xcode англійський).
- Не змінюй дизайн і поведінку застосунку без прохання — він ретельно скопійований з вебверсії.
- Перед суттєвими змінами коду запускай збірку й тести (команди нижче).

## Що це за проєкт

**«Мій МЯУдень»** — котячий планувальник дня для iPhone. Нативний застосунок на **SwiftUI**, переписаний з вебверсії (один `index.html`):
- вебверсія: https://sergiushp.github.io/daynest-planner/
- репозиторій: `SergiusHp/daynest-planner` на GitHub; iOS-код — у гілці **`ios`**, папка `ios/` (вміст цієї папки = вміст `ios/`).

Параметри:
| | |
|---|---|
| Назва на екрані | Мій МЯУдень |
| Bundle ID | `com.sergiushp.myauden` (можна змінити, якщо зайнятий) |
| Версія | 1.0 (build 1) |
| Мінімальна iOS | 17.0 |
| Пристрої | лише iPhone, лише портретна орієнтація |
| Мова | Swift 5, SwiftUI, Observation (`@Observable`) |
| Xcode | 16 або новіший (формат проєкту 77 із синхронізованими папками) |
| Team (DEVELOPMENT_TEAM) | **порожній** — власник ще не має акаунта Apple Developer |

### Стан на момент передачі
- ✅ Усі функції вебверсії перенесено.
- ✅ 10/10 UI-тестів проходять на симуляторі iPhone (GitHub Actions, macos-15, Xcode 16).
- ✅ Перевірено верстку на маленькому iPhone SE.
- ✅ Release-збірка для `generic/platform=iOS` збирається без помилок.
- ⚠️ **На справжньому iPhone ще не запускався** — це перше, що треба зробити.
- ⚠️ Не підписано (немає Team), немає облікового запису Apple Developer.

## Функції застосунку

Три сторінки, що гортаються свайпом вліво/вправо (+ крапки-індикатор унизу):
1. **План дня** — шапка з датою і сонцем (тап по сонцю → повернення на сьогодні), смужка тижня, «Список справ» з лічильником. Свайп справи **вправо** — кіт її «зацарапує» (4 стилі подряпин, тактильний відгук), справа переїжджає вниз. Тап по чекбоксу — те саме. Тап по тексту — редагування. Тап по **коту** внизу — нова справа.
2. **Тиждень / Місяць** — перемикач режимів, календар із кількістю справ, список **лише невиконаних** справ вибраного дня.
3. **Фокус** — таймер у вигляді котячої мордочки: крутиш лапку — виставляєш хвилини (з тактильним відгуком), пресети, вибір справи, «Скинути»/«Почати». Під час таймера грає фонова музика (кнопка з нотою вмикає/вимикає), наприкінці — дзвіночок, вібрація і сповіщення. Лічильник сесій за день.

Також:
- **Привітальний екран** (лише при першому запуску) → **знайомство з жестами** з 3 анімованих кроків («Далі», «Пропустити», «Почати»). Потім одразу відкривається сьогоднішній день.
- **Шторка плану**: текст, дата, необов'язковий час, нагадування (0/5/15/30/45/60 хв) — локальні сповіщення приходять, навіть коли застосунок закритий. Видалення з підтвердженням.
- Новий користувач бачить одну справу: «Ознайомитись з програмою».
- Підтримка «Зменшити рух» (Reduce Motion), VoiceOver-підписи, Dynamic Type (до xxLarge).
- Дані — лише на пристрої (JSON у Application Support + UserDefaults). Без мережі, без акаунтів, без аналітики.

## Структура папки

```
MyauDen.xcodeproj/             проєкт Xcode (згенерований tools/gen_project.py) + спільна схема MyauDen
MyauDen/
  Info.plist                   шрифти, фонове аудіо, екран запуску, ITSAppUsesNonExemptEncryption=false
  App/MyauDenApp.swift         @main, створення AppStore/FocusModel, локаль uk_UA, світла тема
  App/RootView.swift           привітання → знайомство → MainPager (3 сторінки), PageDots, шторка
  Model/AppStore.swift         плани, вибраний день, сторінка, календар, збереження, toggle з подряпинами
  Model/Plan.swift             модель плану + варіанти нагадувань
  Model/DayKey.swift           дати "yyyy-MM-dd", український календар (тиждень з понеділка)
  Model/FocusModel.swift       логіка таймера, сесії, музика
  Model/TestHooks.swift        аргументи запуску для UI-тестів
  Services/Notifier.swift      локальні сповіщення (нагадування, кінець фокусу)
  Services/AudioService.swift  MusicPlayer (дві доріжки по колу) + Chime
  Services/Haptics.swift       тактильні відгуки
  Theme/Theme.swift            кольори, шрифт Nunito, стилі кнопок
  Theme/VectorPaths.swift      векторні форми (згенеровано tools/gen_paths.py з SVG вебверсії)
  Views/Welcome/               привітальний екран
  Views/Onboarding/            3 кроки знайомства + анімовані демо
  Views/Day/                   сторінка дня, рядок справи (свайп), подряпини, зона кота
  Views/Calendar/              тиждень/місяць
  Views/Focus/                 циферблат-кіт і сторінка фокусу
  Views/Sheet/PlanSheet.swift  шторка створення/редагування
  Views/Common/Keyframes.swift помічник для анімацій, перенесених з CSS keyframes
  Resources/Assets.xcassets    ілюстрації, іконка 1024, кольори
  Resources/Audio/             focus-1.mp3, focus-2.mp3 (музика таймера), chime.wav
  Resources/Fonts/             Nunito 600/700/800 (ліцензія OFL у OFL-Nunito.txt)
  Resources/PrivacyInfo.xcprivacy  маніфест приватності (UserDefaults, причина CA92.1)
MyauDenUITests/                10 UI-тестів
tools/gen_project.py           перегенерувати .xcodeproj (python3 tools/gen_project.py)
tools/gen_paths.py             перегенерувати VectorPaths.swift
README-UA.md                   інструкція для людини (запуск, акаунт, публікація)
CLAUDE.md                      цей файл
```

Нові `.swift`-файли в папках `MyauDen/` і `MyauDenUITests/` підхоплюються Xcode автоматично (синхронізовані папки) — вручну додавати в проєкт не треба.

## Збірка і тести (термінал на Mac)

```bash
# перелік симуляторів
xcrun simctl list devices available | grep iPhone

# усі UI-тести (підстав назву наявного симулятора)
xcodebuild -project MyauDen.xcodeproj -scheme MyauDen \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO test

# один тест
xcodebuild ... -only-testing:MyauDenUITests/MyauDenUITests/testSwipeRightCompletesTask test

# Release-збірка як для App Store (без підпису)
xcodebuild -project MyauDen.xcodeproj -scheme MyauDen -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Тести: `testFirstLaunchFlow`, `testSwipeLeftOverTaskOpensCalendar`, `testVerticalScrollKeepsPage`, `testSwipeRightCompletesTask`, `testAddPlanViaCat`, `testSunReturnsToToday`, `testCalendarHidesDone`, `testFocusDialAndMusic`, `testReducedMotionOnboarding`, `testScreensOverview` (робить знімки всіх екранів).

Аргументи запуску для тестів (у звичайній роботі ігноруються): `-uitest`, `-uitest-reset`, `-uitest-skip-intro`, `-uitest-seed-many`, `-uitest-seed-sample`, `-uitest-page N`, `-uitest-reduce-motion`. У режимі `-uitest` застосунок не питає дозволу на сповіщення.

## Важливі технічні рішення (не ламати!)

- **Перемикач сторінок** — `ScrollView(.horizontal)` + `.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)`, а **не** `TabView(.page)`. TabView конфліктував зі свайпом справи. Під час свайпу справи чи обертання лапки таймера встановлюється `store.pagerLocked = true` → `.scrollDisabled(...)`.
- **Свайп справи вправо** — власний `DragGesture` у `TaskRow.swift` (поріг 70 pt, фази idle/claimed/rejected, скидання через `@GestureState`). Нативні `swipeActions` свідомо прибрані.
- **Лапка таймера** — `.highPriorityGesture(DragGesture(minimumDistance: 0))` на циферблаті; тап у центр = старт/пауза.
- **Подряпини** — процедурні, перенесені з JS: `SeededRandom` з UInt32-арифметикою з переповненням (`&+`, `&*`), щоб малюнок збігався з вебверсією. `AppStore.settling` тримає справу на місці, поки кіт «дозацарапує».
- Невидимі сторінки приховані від VoiceOver (`accessibilityHidden(store.page != i)`).
- Цілі числа в `Text` (рік тощо) — через `Text(verbatim:)`, інакше локаль вставляє пробіл: «2 026».
- Пари кнопок «Скасувати / Додати» та «Скинути / Почати» — у пропорції 1:2 через `GeometryReader`, щоб не стискалися.

## Що робити далі (план для Claude)

Проведи власника крок за кроком:

1. **Перевірити середовище**: `xcodebuild -version` (потрібен Xcode 16+). Якщо Xcode немає — допомогти встановити з Mac App Store і запустити його раз (прийняти ліцензію, встановити компоненти iOS).
2. **Зібрати й прогнати тести на симуляторі** (команди вище). Якщо все зелене — переходити далі.
3. **Запуск на iPhone власника (безкоштовно, без платного акаунта)**:
   - Xcode → Settings → Accounts → «+» → Apple ID.
   - Відкрити `MyauDen.xcodeproj` → таргет **MyauDen** → вкладка **Signing & Capabilities** → увімкнути «Automatically manage signing» → **Team** = особистий (Personal Team).
   - Якщо Bundle ID зайнятий — змінити на унікальний, напр. `com.<імʼя>.myauden`.
   - Підключити iPhone кабелем, на iPhone увімкнути **Developer Mode** (Settings → Privacy & Security), вибрати iPhone вгорі Xcode → ▶ Run.
   - На iPhone: Settings → General → VPN & Device Management → довіритися розробнику.
   - Разом з власником перевірити на живому телефоні: свайпи, вібрацію, музику (і у фоні), нагадування, знайомство.
4. **Виправити все, що знайдеться на реальному пристрої** (після кожної зміни — тести).
5. **Підготовка до App Store** (коли власник оформить Apple Developer Program, $99/рік, https://developer.apple.com/programs/):
   - Змінити Team на платний акаунт.
   - Замінити тимчасову іконку `AppIcon.appiconset/appicon-1024.png` (1024×1024, без прозорості) на фінальну.
   - Вирішити питання з **музикою** (див. нижче).
   - App Store Connect → My Apps → «+» New App: назва, мова (Ukrainian), Bundle ID, SKU.
   - Заповнити: опис, ключові слова, категорію (Productivity), скриншоти 6.9" і 6.5" (можна взяти з симулятора iPhone 16 Pro Max / 11 Pro Max), URL політики приватності (потрібна сторінка; застосунок не збирає даних — «Data Not Collected»), вікова категорія.
   - Xcode → Product → Archive → Distribute App → App Store Connect → Upload. Потім у App Store Connect вибрати збірку і «Submit for Review».
   - Для кожної наступної збірки збільшувати Build (CURRENT_PROJECT_VERSION).
6. За бажанням — TestFlight для тестування на кількох пристроях.

## Відомі обмеження / відкриті питання

- **Музика** (`focus-1.mp3`, `focus-2.mp3`) згенерована ШІ-сервісом. Для App Store потрібне право на **комерційне** використання: у Suno — лише треки, створені на платному тарифі (Pro/Premier); безкоштовний тариф — тільки особисте використання. Udio — дивитися чинні умови. Зберегти докази (тариф на дату генерації, посилання на треки). Альтернатива — замінити на музику з ліцензією CC0 / Pixabay Music (просто замінити файли з тими ж іменами або оновити `AudioService.swift`).
- **Ілюстрації** взяті з вебверсії й мають невисоку роздільність — на великих екранах можуть бути злегка розмиті. Бажано отримати версії @3x.
- **Іконка** зроблена автоматично — тимчасова.
- Шрифт **Nunito** — ліцензія SIL OFL, дозволяє вбудовування (файл ліцензії лежить поруч).
- Нагадування працюють лише якщо користувач дозволить сповіщення (застосунок запитує при першому створенні нагадування / запуску таймера).
- Вебверсія і iOS-версія — окремі коди; зміни в одній автоматично не потрапляють в іншу.

## GitHub і CI

- Гілка `ios` у `SergiusHp/daynest-planner`; workflow `.github/workflows/ios.yml` (у корені репозиторію, не в цій папці) на кожен push: тести на симуляторі, iPhone SE, Release-збірка, результати й скриншоти пушить у гілку `ci-results`.
- Якщо власник хоче працювати через git: `git clone https://github.com/SergiusHp/daynest-planner.git && git checkout ios`, проєкт — у `ios/`. Ця папка на диску — копія без `.git`.
- Комітити/пушити лише коли власник просить.
