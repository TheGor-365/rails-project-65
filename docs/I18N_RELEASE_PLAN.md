# Classifieds — RU / EN / HY internationalization release plan

Last updated: 2026-10-31. Source branch for audit: `main` at `e6c0098`. Current production uses Railway and 17 public demo listings. **Do not deploy incomplete translations or migrate production data without a DB backup.**

## Goals and invariants
- Supported UI languages: Russian (`ru`), English (`en`), Armenian (`hy`). Default `ru` preserves today's deployed UI. A user selects a locale explicitly; do **not** infer identity/location from IP.
- Every existing user-visible system string must resolve in all three languages: pages, partials, headers, buttons, confirmation prompts, form help, placeholder/ARIA/title, flash, validation and image-upload error messages, status labels, pagination, JS-controlled theme labels and model attributes.
- For each page/feature and language, own YAML file, e.g. `config/locales/en/pages/bulletins/index.yml`, `config/locales/ru/pages/bulletins/show.yml`, `config/locales/hy/pages/bulletins/new.yml`; separately `shared/header.yml`, `models.yml`, `flash.yml`.
- Locale selector: small Bootstrap dropdown in header beside theme toggle, on desktop and mobile. Show one current-language flag icon plus language label in menu. Native buttons/links; full keyboard/ARIA support; actual focus/close/locale preservation on Turbo pages. Ensure no navbar overflow at 390px.
- Existing routes, OAuth callback and `/up` healthcheck must continue to work. Locale choice should survive internal links, POST redirects and login/logout.
- Listing input language: **separate persisted `bulletins.language` property** (enum-like `ru/en/hy` with model validation); form preselects current I18n.locale, retains submitted selection on error and edit, cannot be changed unintentionally by admin update. Existing Russian demo rows explicitly backfilled `ru`. Require a PostgreSQL backup before migration.
- Distinguish *UI translations* from *user-submitted content*. A listing title/description stays as authored; do not pretend auto-translation exists. Existing 17 Russian demo listings stay Russian unless separately provided and reviewed translations are stored.
- Category names: seeded database values are Russian. Public labels for the three canonical categories must be localized via stable keys; do not automatically translate arbitrary admin-entered category names or rename stored categories. Decide how to support admin-created category translations in a later isolated change.
- No Devise or Simple Form exists here. Existing form helpers are Rails `form_with`. Do not add those gems. `rails-i18n ~> 8.1.0` is a candidate for Rails formats/pluralization and standard errors; add with lockfile in its own stage if verified. `i18n-tasks` can be used dev/test for missing-key audits.
- All developer messages and README factual content must match implementation and be translated where user-facing. Never publish third-party gallery screenshots as portfolio art without rights.

## Small, individually reviewable stages

1. **Foundation — PR #34, no dropdown:** configure locale allowlist/default `ru`, request-scoped `I18n.with_locale`, allowlisted URL param + session preference, nondefault locale route-link propagation, dynamic HTML lang, baseline flash translations RU/EN/HY, integration tests. Do not merge/deploy until CI and compatibility checks pass.
2. **Header and shared UI:** local flag icons, Bootstrap dropdown, a11y, mobile layout and theme-toggle JS labels, shared footer and flash, base `title`, pagination labels. Test keyboard/navigation/Turbo and OAuth roundtrip.
3. **Catalog and bulletin view:** `index`, `_bulletin_card`, `show`, category selector/filter/sort, gallery ALT/aria, favorite CTA, model state labels. Each page owns YAML by locale; check all prompts in RU/EN/HY.
4. **Listing create/edit + validation:** `new`, `edit`, `_form`, upload help and error strings, Rails `activerecord` attribute/error localization, controller messages. Add a separate migration for `Bulletin.language` with safe backfill & rollback tests and current-locale default. No automatic translation of user-entered title/description.
5. **Authenticated and admin pages:** profile, favorites, auth/link flow, category admin and bulletin moderation pages, messages/conversations even if the owner excludes manual 2-account QA; **UI translation is still required**. Include empty states, labels, confirmations, error messages, pagination and ARIA.
6. **Audit, tests and release:** automated missing-key/identical-hardcoded-Russian sweeps, model tests, multi-locale integration/system tests, accessibility at 390px, dark/light/desktop/mobile screenshots, OAuth and Railway smoke. Reviewer bilingual QA (especially Armenian). Only after ALL keys, CI, backup, migration and manual QA pass merge into main and deploy. Confirm /up, catalog=17, S3=20, images intact.
7. **Portfolio evidence:** replace old screenshots with real screenshots across representative locales. Store verified originals with English names in the existing Drive `02_SCREENSHOTS_VERIFIED` folder. Avoid personal email in admin views and copyrighted third-party media in marketing composites.

## Acceptance gate per PR
- Narrow diff, no unrelated code refactor, no destructive DB tasks or production resource changes.
- CI success (Rails tests + system tests, RuboCop, Brakeman). Before deployment: local Ruby 3.4.12 smoke, including OAuth, pagination, form submissions, themed mobile header.
- Every introduced `t()` reference has all three locale values; no runtime “Translation missing”, English UI containing unintentional Russian strings, or locale leakage across requests.
- Confirmed proof and checkpoint before moving to the next PR.

## Current audit findings
- Current `en.yml` originally contained Russian messages, with missing flash entries. `ru.yml` existed with partial keys; `hy.yml` missing.
- Most ERB headings, placeholders, ARIA labels, status badges, and model validation errors are hardcoded Russian.
- `app/javascript/controllers/theme_controller.js` builds Russian accessibility titles at runtime.
- `config/routes.rb` contains unprefixed routes with stable GitHub OAuth callback.
- Category labels come from Russian names in the database, and `Bulletin` currently has no language column.
- No `devise` or `simple_form` in Gemfile; Rails form_with is used.
