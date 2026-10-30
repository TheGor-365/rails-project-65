# Classifieds — Frontend Foundation & Delivery Contract
Date: 2026-10-30 · Status: PROPOSED / NOT IMPLEMENTED
Source: read-only audit of `feature/classifieds-p0-security` at `4113a601`.
Scope: presentation and additive, low-risk UX improvements only.

## Product intent
Transform a Rails bulletin board into a credible social-marketplace portfolio
application, not a visual copy of Facebook/X and not a separate SPA. Preserve
existing business rules, OAuth, AASM moderation, upload validation, URLs, and
development data. Never copy a visual concept into production blindly.

## Baseline evidence
- Ruby 3.4.12 / Rails 8.1.4; Bootstrap 5.3.8; Turbo 8; Stimulus 3.2.
- `app/assets/stylesheets/application.bootstrap.scss` only imports Bootstrap and
  Bootstrap Icons. No application design token system exists.
- `app/javascript/controllers` contains only the sample hello controller.
- App layout, guest catalog/details, owner profile, moderation and category
  administration use different density, spacing and navigation conventions.
- Existing CI: 39 Rails tests and 8 browser tests on the P0 feature branch.
- No theme switcher or automated dual-theme contrast/visual regression coverage.
- No browser-verified screenshots of this new design yet.

## Design direction: Modern Social Marketplace
One brand and one visual language for ALL routes:
- "Porcelain/Cobalt" light and "Graphite/Cobalt" dark; same spacing, hierarchy,
  typography, icons, information architecture, and components.
- Neutral surfaces, restrained blue accent, concise content-forward card grid;
  no heavy gradients, glass gimmicks, huge empty hero blocks or newspaper density.
- User outcomes prioritized: browse / search / open / create / manage / moderate.
- Default responsive desktop shell and accessible mobile navigation.

## Styling contract
- Bootstrap remains the only CSS framework. Avoid Tailwind/shadcn and parallel
  global CSS frameworks; MagicPath mockups are references, not drop-in React.
- Bootstrap `data-bs-theme` at documentElement is the single color-mode source.
- Add semantically named CSS custom properties `--cl-*` for semantic colors,
  spacing, radii, elevations, content widths; map to Bootstrap variables where
  possible. Token definitions for both modes must be centralized, not repeated
  per page.
- Suggested SCSS structure:
  ```
  app/assets/stylesheets/
    application.bootstrap.scss       # ordered import entrypoint
    foundation/_tokens.scss          # semantic tokens, light/dark
    foundation/_base.scss            # typography, global focus, body
    foundation/_layout.scss          # app shell/grid/responsive breakpoints
    components/_button.scss
    components/_card.scss
    components/_form.scss
    components/_status.scss
    components/_empty_state.scss
    components/_filter_bar.scss
    pages/_catalog.scss
    pages/_bulletin.scss
    pages/_profile.scss
    pages/_admin.scss
  ```
- Prefix application-owned classes `cl-` or `c-` consistently and avoid
  styling generic `.card`, `.navbar`, `.btn` across the site. No duplicate
  selectors across files, no blanket `!important`, and no inline overrides.
- Keep Sass overrides in documented order and avoid Bootstrap/light hard-coded
  `bg-light`, `text-dark`, `navbar-light` on themable surfaces.
- Prefer existing Bootstrap Icons for iconography: one coherent icon family.

## Theme behavior contract
- Exactly ONE visible icon button: moon in light mode (switch to dark), sun in
  dark mode (switch to light). Accessible `aria-label`, `title`, and clear focus.
- Default to OS `prefers-color-scheme` when there is no saved choice; after a
  manual toggle persist an explicit light/dark preference in localStorage.
- Resolve the preference before CSS paints (minimal prepaint boot script with
  CSP-compatible delivery); avoid theme flash and invalid localStorage crashes.
- Single `theme_controller.js` owns click behavior, icon/label/pressed-state UI,
  preference persistence and theme-change events. No duplicate listeners on
  `turbo:load`. Separate early prepaint INITIALIZATION is not a second click
  handler.
- Keep mode during Turbo visits/reload and on category/admin/profile pages.
- If OS theme changes, follow it only until a manual preference exists.
- Color is not the only carrier of status; ensure form, focus, alert, link,
  image fallback and pagination surfaces work in BOTH themes.
- Do not introduce a second theme toggle in mobile/offcanvas navigation.

## View composition and behavior ownership
- `app/views/shared/_app_header.html.erb`, `_app_footer.html.erb`,
  `_flash.html.erb`, `_theme_toggle.html.erb`, `_empty_state.html.erb`.
- `app/views/web/bulletins/_bulletin_card.html.erb`, `_filter_bar.html.erb`,
  `_form.html.erb`, and a shared status badge for profile/admin.
- One canonical form partial for new/edit where feasible; preserve route
  authorization and admin-specific fields. Any semantic difference is an
  explicit parameter, not duplicated form markup.
- One owner per event: Stimulus for interactive behavior, server/Pundit/AASM
  for auth and transitions, Turbo for navigation, CSS for presentation.
  Do not add parallel DOMContentLoaded + turbo:load + Stimulus handlers.
- Review every admin/control/fixture state, including guest, owner and moderator.

## Delivery sequence and merge gates
0. Foundation contract and audit (this document, NO runtime changes).
1. Tokens + theme controller + one shell theme toggle and theme tests.
2. Unified app shell: header, mobile nav, flash, footer and page framing.
3. Catalog: responsive filters, sorting, card image/fallback, count, empty
   states, pagination and real click-through, preserving query params.
4. Detail: image, metadata, actions, safe owner/admin contextual navigation.
5. Forms: validation, image constraints, consistent control spacing,
   accessible feedback; no direct-upload route restoration.
6. Owner + admin: same shell, state badges, responsive management actions,
   filter consistency and accessible dangerous-action confirmation.
7. Optional low-risk UX improvements (separately scoped):
   sort newest/oldest, active-filter chips, clear filters, no-results guidance,
   back-to-results, photo thumbnail variants with verified storage support.
8. Production readiness: CI, browser QA, security, perf/a11y, visual approval,
   release in isolated Railway only after separate cost and storage approval.

## Regression/quality gates for EVERY PR
- Baseline Rails tests 39 PASS (the count may grow), RuboCop zero offenses,
  Brakeman zero security warnings, CI green.
- Browser suite and new targeted regressions: guest, owner, admin, OAuth,
  moderation, image upload, mobile and desktop.
- Viewports: 320, 360, 390, 430, 768, 1024, 1440; check both color modes.
- No horizontal document overflow; no occluded sticky UI; click targets,
  keyboard focus, labels, screen-reader names, tab order and forms checked.
- WCAG 2.2 AA as goal: body contrast at least 4.5:1; large text and UI
  indicators at least 3:1 where applicable; visible focus. Automated tests
  supplement, NOT replace manual review.
- Visual diff / screenshots for all core routes and both themes; verify
  layout and CSS interactions, not just unit/response tests.
- Keep performance measurable: target p75 LCP <=2.5s, CLS <=0.1 and
  INP <=200ms on a deployed, realistically seeded site; not asserted yet.
- Security/behavior: authorization unchanged, owner/admin routes unchanged,
  false OAuth identity not elevated, upload constraints unchanged, no
  unrelated changes to data/migrations/deployed services.
- PR description includes before/after, files changed, test evidence,
  intentional exclusions, rollback path and actual approval.

## Defer / do not introduce without separate specification
- New pricing/location/message/favorites/schema, payments, chats, social feeds,
  maps, AI features, infinite scrolling, WebSockets, Next.js, React and Vue.
- Additional component libraries or paid subscriptions unless justified by
  concrete saved engineering work and integration test.
- Editing production Railway or merging `main` as a side effect of UI work.

## Tools
- GitHub: source of truth, small PRs, CI, review and rollback.
- MagicPath: separate Classifieds concept project; reference/visual drafts
  only. React/Tailwind output must be translated to ERB/Bootstrap tokens.
- tldraw: customer/admin flow mapping and navigation diagrams.
- Canva: cover/social collateral AFTER real UI screenshot validation.
- Product Design: UX audit/prototype workflow is intended for ChatGPT Work;
  do not claim it was run in this chat.
- Existing GitHub Quality mockups are inspirations, NOT Classifieds source
  assets or proof of Classifieds production behavior.

## Acceptance and economics
- Preserve local 21 existing bulletin records and images; development data
  never overwritten by seeds, previews or visual plugins.
- Rollback by reverting the relevant isolated PR (mind any later dependencies).
- Do not market this as a commercial client project: educational origin and
  independently added engineering work must both be clear.
- Main KPI: understandable, credible, navigable live demo and truthful
  evidence for Rails freelance portfolio; aesthetics alone are not success.
