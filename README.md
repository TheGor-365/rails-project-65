# Rails Project 65 — Доска объявлений

### Hexlet tests and linter status:
[![Actions Status](https://github.com/TheGor-365/rails-project-65/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/TheGor-365/rails-project-65/actions)
[![CI](https://github.com/TheGor-365/rails-project-65/actions/workflows/ci.yml/badge.svg)](https://github.com/TheGor-365/rails-project-65/actions/workflows/ci.yml)

## Ссылка на сайт (Render)
https://rails-project-65-5ykr.onrender.com

---

## Описание

Демо-приложение «Доска объявлений» на Ruby on Rails:
- Объявления (Bulletins) с изображением, категорией и владельцем.
- Состояния объявлений через конечный автомат (AASM): `draft → under_moderation → published`, а также `rejected`, `archived`.
- Публичная главная страница показывает **только опубликованные** объявления.
- Личный кабинет `/profile` для управления своими объявлениями (отправка на модерацию, архив).
- Админ-панель `/admin` (категории, объявления; публикация/отклонение/архивирование).
- Вход через GitHub (OmniAuth).
- Авторизация через Pundit.

---

## Технологии

- Ruby 3.2.2
- Rails 7.2.2.2
- PostgreSQL
- Active Storage (локальное хранение в деве)
- OmniAuth GitHub (`user:email`)
- Pundit
- AASM
- Bootstrap 5, esbuild, Sass

---

## Быстрый старт (локально)

```bash
# 1) Клонирование
git clone https://github.com/TheGor-365/rails-project-65.git
cd rails-project-65

# 2) Ruby & зависимости
bundle install

# 3) Node/Yarn зависимости
yarn install

# 4) Переменные окружения (создай .env по образцу ниже)
cp .env.example .env
# отредактируй .env и впиши свои ключи GitHub OAuth и email админа

# 5) База данных
bin/rails db:prepare  # создаст БД и прогонит миграции

# 6) (по желанию) залить фикстуры для демо-данных
bin/rails db:fixtures:load

# 7) Запуск в режиме разработки (Procfile.dev: web + js + css)
bin/dev


# GitHub OAuth App (см. Settings → Developer settings → OAuth Apps)
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret

# Этот email будет повышен до admin через миграцию
ADMIN_EMAIL=you@example.com
```


## Аутентификация

Кнопка «Войти через GitHub» — в шапке.

После входа отображается приветствие с именем/почтой и кнопка «Выйти».

Роли и доступ

Пользователь — может создавать объявления (черновики), отправлять их на модерацию и убирать в архив (в /profile).

Администратор — видит админ-раздел /admin, может публиковать/отклонять и архивировать объявления, управлять категориями.


## Как сделать себя админом

В проекте есть миграция, которая помечает пользователя из ADMIN_EMAIL как админа:

```bash
ADMIN_EMAIL="you@example.com" bin/rails db:migrate
```
Проверка в консоли:

```bash
User.where(email: 'you@example.com').pluck(:email, :admin)
# => [["you@example.com", true]]
```


## Состояния объявлений (AASM)


Колонка: state (string), значение по умолчанию — draft.

Состояния:

draft — начальное состояние.
under_moderation — отправлено на модерацию.
published — опубликовано (возможно только из under_moderation).
rejected — отклонено (нужна доработка).
archived — архив.

События:

to_moderate: draft → under_moderation
publish: under_moderation → published
reject: under_moderation → rejected
archive: [under_moderation | published | rejected] → archived

Главная страница (/) выводит только published.


## Основные маршруты

Публичная часть:

GET / — список опубликованных объявлений.
GET /bulletins/new, POST /bulletins — создание объявления (нужна авторизация).
PATCH /bulletins/:id/to_moderate — отправить своё объявление на модерацию.
PATCH /bulletins/:id/archive — отправить своё объявление в архив.
GET /profile — список своих объявлений и действия над ними.

Админ-панель:

GET /admin/categories — CRUD категорий.
GET /admin/bulletins — список объявлений.
PATCH /admin/bulletins/:id/publish — публикация.
PATCH /admin/bulletins/:id/reject — отклонение.
PATCH /admin/bulletins/:id/archive — архив.

Аутентификация:

POST /auth/:provider — запрос на вход через GitHub.
GET /auth/:provider/callback — коллбэк.
DELETE /signout — выход.


## Запуск тестов и качество кода

```bash
# Юнит-тесты
bin/rails test

# (если подключены линтеры) RuboCop / Slim-Lint и т.п.
bundle exec rubocop
bundle exec slim-lint app/views
```

## Деплой


Проект развёрнут на Render: https://rails-project-65-5ykr.onrender.com

Ключевые моменты деплоя:

Прогон миграций на проде обязателен (включая миграцию промоушена админа):

```bash
ADMIN_EMAIL="you@example.com" rails db:migrate
```
