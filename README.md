# Classifieds — Ruby on Rails Bulletin Board

**Live:** https://classifieds-web-production-9132.up.railway.app  
**Repository:** https://github.com/TheGor-365/rails-project-65  
**Production source:** pinned feature commit `e84aa68`; the same release was merged into the default `main` branch in [PR #32](https://github.com/TheGor-365/rails-project-65/pull/32).

**Origin:** educational Hexlet application, extended as a portfolio engineering case. This is not a commercial marketplace. Imported demonstration listings are not real offers.

[Русский](#русский) · [English](#english)

---

## Русский

### Назначение

Classifieds — доска объявлений с публикацией через модерацию, изображениями, авторизацией GitHub и приватными пользовательскими функциями. Реализованы серверные ограничения доступа, автоматизированные проверки и отдельный production-деплой.

### Реализовано

| Раздел | Возможности |
| --- | --- |
| Каталог | Только опубликованные объявления, поиск, категории, сортировка, пагинация |
| Объявления | Черновики, редактирование, отправка на модерацию, публикация/отклонение, архив |
| Изображения | 1 обложка + до 4 дополнительных фотографий, интерактивная галерея, миниатюры; JPEG/PNG/WebP до 5 МиБ на файл |
| Вход | GitHub OAuth, связанная identity, защищённая сессия, выход |
| Доступ | Pundit, контроль владельца, административные маршруты только для admin |
| Модерация | AASM: draft, under_moderation, published, rejected, archived |
| Избранное | Сохранение опубликованных объявлений конкретным пользователем |
| Сообщения | Приватные buyer–seller переписки по опубликованному объявлению, текстовые сообщения, пагинация |
| Непрочитанные | Индивидуальные read-маркеры и счётчики для участников |
| UI | Адаптивная верстка Bootstrap 5, светлая/тёмная тема |
| Качество | Rails integration/system tests, RuboCop, Brakeman, GitHub Actions |

**Границы реализации:** переписки не являются real-time/WebSocket-чатом; нет email/SMS/push-уведомлений, оплаты, доставки, escrow или входа через Google. Подключён именно GitHub OAuth. Учебные объявления не отражают реальные коммерческие предложения.

### Технологический стек

Ruby **3.4.12**, Rails **8.1.4**, SQLite (development/test), PostgreSQL **18** (production), Active Storage (локальный Disk и отдельный Railway S3 bucket), OmniAuth GitHub, Pundit, AASM, Ransack, Kaminari, ERB, Turbo/Stimulus, Bootstrap 5, Sass, esbuild, Docker и Railway.

### Локальный запуск

~~~bash
git clone https://github.com/TheGor-365/rails-project-65.git
cd rails-project-65
git switch feature/classifieds-p0-security
# Установите Ruby 3.4.12 через ваш менеджер версий.
bundle install
yarn install
bin/rails db:prepare
PORT=3001 bin/dev
~~~

Открыть http://localhost:3001. Для GitHub OAuth создайте собственное приложение в GitHub Developer Settings с callback **http://localhost:3001/auth/github/callback** и установите переменные **GITHUB_CLIENT_ID** и **GITHUB_CLIENT_SECRET** в локальном неотслеживаемом окружении, например .env. Файл .env.example в проекте не гарантируется.

Команда db:prepare предназначена для настройки локальной базы. **Не выполняйте db:reset и db:fixtures:load на базе с нужными данными.** Не публикуйте OAuth-секреты, ключи, клиентские файлы или дампы БД в Git.

### Проверка и тесты

~~~bash
bin/rails test
bin/rails test:system
bin/rubocop -f simple
bin/brakeman --no-pager
docker build -t classifieds:local .
~~~

По локальной проверке 31.10.2026: **71 Rails test / 440 assertions** и **16 system tests / 70 assertions**, 0 failures/errors/skips; RuboCop — **73 files, 0 offenses**, Brakeman — **0 warnings**. Отдельный production healthcheck fix прошёл GitHub CI в [PR #29](https://github.com/TheGor-365/rails-project-65/pull/29).

### Production / доступ / медиа

- **Публичный сайт:** https://classifieds-web-production-9132.up.railway.app
- Production: отдельные PostgreSQL и S3 bucket в Railway. Каталог и Active Storage не зависят от эфемерного диска Rails-контейнера.
- Конфигурация задаётся в Railway: DATABASE_URL, SECRET_KEY_BASE, GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, CLASSIFIEDS_S3_*.
- Railway healthcheck GET /up получает 200 OK, публичные страницы перенаправляются на HTTPS.
- После нового GitHub OAuth-входа пользователь **не становится администратором автоматически**. Историческая ADMIN_EMAIL migration действует только при однократном выполнении миграции. Права администратора назначаются владельцем отдельно после проверки GitHub identity.
- В production загружен ограниченный набор **учебных** объявлений. Не импортируйте публично реальные личные данные, OAuth-связки и переписки. Проверяйте права использования изображений до включения их в маркетинговые материалы.

**Состояние:** проверены локальный CI-контур, Docker-сборка, публичный каталог, перенос фото в S3 и GitHub OAuth. Отдельными шагами остаются проверка сохранности медиа после redeploy, ручная двухаккаунтная проверка приватных сообщений, админ-модерация и мобильный QA.

---

## English

### Overview

Classifieds is an **educational Hexlet Rails application**, extended as an engineering portfolio case. It demonstrates moderated listings, GitHub OAuth, image attachments, authorization, personal favorites, private conversations, automated tests and isolated production deployment. It is **not** a commercial marketplace; imported listings are demonstration data.

**Live demo:** https://classifieds-web-production-9132.up.railway.app  
**Current deployed source:** pinned feature commit `e84aa68`; the same release is now present in `main` via [PR #32](https://github.com/TheGor-365/rails-project-65/pull/32).

### Delivered functionality

| Area | Implemented |
| --- | --- |
| Public catalog | Published listings only, search, category filters, sorting, pagination |
| Listing lifecycle | Draft/edit, moderation request, publish/reject, archive via AASM |
| Images | Cover + up to 4 gallery photos; interactive thumbnails; JPEG/PNG/WebP, up to 5 MiB each |
| Authentication | GitHub OAuth identity and verified sessions, login/logout |
| Access control | Pundit owner checks; admin-only moderation routes |
| Personal features | Per-user published-listing favorites |
| Messaging | Private buyer/seller text threads, pagination, individual unread markers and counts |
| UI | Responsive Bootstrap 5 layout and light/dark appearance |
| Engineering | Rails integration/system tests, RuboCop, Brakeman, multi-stage Docker, GitHub Actions CI |

Messaging is **not** live WebSocket chat; email/SMS/push notifications, payments, shipping, escrow and Google sign-in are **not implemented**.

### Stack

Ruby **3.4.12**, Rails **8.1.4**; SQLite in development/test and PostgreSQL **18** in production; Active Storage with local disk/S3; OmniAuth GitHub, Pundit, AASM, Ransack, Kaminari, ERB, Turbo/Stimulus, Bootstrap 5, Sass, esbuild, Docker, Railway.

### Local setup

~~~bash
git clone https://github.com/TheGor-365/rails-project-65.git
cd rails-project-65
git switch feature/classifieds-p0-security
# Install Ruby 3.4.12 via your Ruby version manager.
bundle install
yarn install
bin/rails db:prepare
PORT=3001 bin/dev
~~~

Open http://localhost:3001. Create your own GitHub OAuth App with callback **http://localhost:3001/auth/github/callback**; supply GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET through an untracked local environment file. Never commit secrets. Do not reset databases containing important data.

### Quality gates

~~~bash
bin/rails test
bin/rails test:system
bin/rubocop -f simple
bin/brakeman --no-pager
docker build -t classifieds:local .
~~~

Verified on October 31, 2026: **71 Rails tests (440 assertions)** and **16 system tests (70 assertions)**, no failures/errors/skips; RuboCop inspected 73 files with no offenses; Brakeman: zero warnings. [PR #29](https://github.com/TheGor-365/rails-project-65/pull/29) passed CI for the Railway healthcheck change.

### Deployment and safeguards

Railway production runs isolated PostgreSQL and a dedicated S3-compatible bucket. Configure DATABASE_URL, SECRET_KEY_BASE, GitHub OAuth and CLASSIFIEDS_S3_* through protected service variables. GET /up returns HTTP 200 for internal platform checks while regular user traffic is HTTPS-only.

New OAuth users are **not** automatically admins; the legacy ADMIN_EMAIL migration acts only when first executed. An authorized owner must explicitly verify identity before assigning admin rights.

**Pending manual acceptance:** full two-account messaging/unread validation, admin/moderation flow, responsive screen review, image-license review and verified portfolio screenshots. These checks are not represented as complete.
