# Кототиндер

Flutter-приложение для свайпа котиков с TheCatAPI. В проекте есть основной flow с лентой, породами и лайками, а также онбординг, авторизация через Firebase, регистрация с анкетой пользователя и редактируемый профиль.

## Реализованные фичи
- Лента с карточкой кота: лайк/дизлайк кнопками и свайпом.
- Переход в детали кота по тапу на карточку.
- Экран пород с переходом в детали породы.
- Экран лайков с удалением и переходом в детали.
- Выбор темы приложения: светлая, темная, системная.
- Онбординг (pager + анимации) при первом запуске.
- Регистрация и вход через Firebase Auth.
- Валидация полей входа/регистрации.
- Регистрация с заполнением анкеты пользователя: фото, описание, энергия, интеллект, ласковость, социальность.
- Сохранение состояния авторизации между перезапусками.
- Экран профиля пользователя из главного flow.
- Редактирование анкеты пользователя: фото, описание, энергия, интеллект, ласковость, социальность.
- Выход из аккаунта с экрана профиля.
- Удаленное хранение анкеты пользователя в Firebase:
  - Cloud Firestore для текстовых полей и характеристик
  - Firebase Storage для фото профиля
- Логирование auth-событий в Firebase Analytics:
  - `auth_sign_in` (`success`/`failure`)
  - `auth_sign_up` (`success`/`failure`)

## Архитектура
Проект разложен по слоям `Data / Domain / Presentation` в рамках feature-модулей:
- `lib/features/auth/`
- `lib/features/cats/`
- `lib/features/onboarding/`

Ключевые принципы:
- UI зависит от domain-абстракций/use-cases.
- Data реализует интерфейсы domain-слоя.
- Централизованная сборка зависимостей в композиционном корне:
  - `lib/core/di/app_dependencies.dart`

## Firebase конфигурация
- iOS: `ios/GoogleService-Info.plist`
- Android: `android/app/google-services.json`
- Инициализация Firebase идет через нативные конфиги платформ (`Firebase.initializeApp()` без хранения ключей в `lib/`)
- Профиль пользователя хранится в Cloud Firestore (`user_profiles/{uid}`)
- Фото профиля хранится удаленно. Основной путь: Firebase Storage (`user_profiles/{uid}/avatar_*`).
- Для совместимости предусмотрен резервный удаленный формат хранения фото в Firestore, если клиент не может получить download URL сразу после загрузки.

## Тесты
Покрытие требований:
- Unit-тесты доменной логики auth:
  - `test/features/auth/domain/auth_credentials_validator_test.dart`
  - `test/features/auth/domain/sign_in_use_case_test.dart`
  - `test/features/auth/domain/sign_up_use_case_test.dart`
- Widget-тесты auth-сценариев:
  - `test/features/auth/presentation/auth_flow_widget_test.dart`
  - `test/features/auth/presentation/sign_up_page_widget_test.dart`

Запуск:
```bash
flutter analyze
flutter test
```

## CI/CD
Добавлен GitHub Actions workflow:
- `.github/workflows/flutter_ci.yml`

На каждый `push` и `pull_request` workflow запускает:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`

При ошибке анализатора или тестов пайплайн падает.

## APK
Актуальная релизная сборка:
- https://drive.google.com/file/d/1_FkTodzw7BvO5FaW2tGRQgGW8UWOGDHG/view?usp=drive_link

Локальный файл появляется после сборки:
- `build/app/outputs/flutter-apk/app-release.apk`

Сборка локально:
```bash
flutter build apk --release
```

## Скриншоты
### Темная тема
- Онбординг:
  - `docs/screenshots/dark/onboarding1.png`
  - `docs/screenshots/dark/onboarding2.png`
  - `docs/screenshots/dark/onboarding3.png`
- Авторизация:
  - `docs/screenshots/dark/singIn.png`
  - `docs/screenshots/dark/singUp1.png`
  - `docs/screenshots/dark/singUp2.png`
- Основной flow:
  - `docs/screenshots/dark/discover.png`
  - `docs/screenshots/dark/types.png`
  - `docs/screenshots/dark/likes.png`
  - `docs/screenshots/dark/description1.png`
  - `docs/screenshots/dark/description2.png`
- Профиль:
  - `docs/screenshots/dark/profile1.png`
  - `docs/screenshots/dark/profile2.png`

### Светлая тема
- Основной flow:
  - `docs/screenshots/light/discover.png`
  - `docs/screenshots/light/types.png`
  - `docs/screenshots/light/likes.png`
  - `docs/screenshots/light/description1.png`
  - `docs/screenshots/light/description2.png`
- Профиль:
  - `docs/screenshots/light/profile1.png`
  - `docs/screenshots/light/profile2.png`

Примечание:
- Онбординг и экраны авторизации следуют системной теме устройства. В репозитории они сохранены в темной теме, потому что скриншоты были сделаны на устройстве с темной системной темой.

## Запуск проекта
```bash
flutter pub get
flutter run
```
