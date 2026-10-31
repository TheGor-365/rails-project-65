# Classifieds — RU/EN/HY production release checkpoint

**Checkpoint (Armenia local date):** 2026-11-01. **Release event:** 2026-10-31 21:10–21:12 UTC.
**Release:** successful; **manual authenticated acceptance remains outstanding**.
**Project:** Railway `classifieds-rails-project-65`, environment `production`.
**Service:** `classifieds-web` (`994a7daf-ad2a-492c-a833-15df99fd29b0`).
**Website:** https://classifieds-web-production-9132.up.railway.app/

## Verified deployment

- **Previous production SHA:** `e6c009861caae2206da2e3052b02d71b8100e4d1`; historical deployment `0e49b18b-3bb0-4174-a20f-fcfd6e4136cc` (retained as a Railway rollback candidate).
- **New production SHA (pinned):** `3153b6be6d80daef08c51284e538000b65053b88`; deployment `fe160e9f-5b3e-43f4-ba77-0c22e155c990`.
- **Approval:** project owner explicitly authorized the production release and necessary automatic operations in CAREER chat.
- **Staged Railway patch:** one change only: `classifieds-web.source.commitSha` from old SHA to new SHA; `destructive=false`. Applied using Railway `accept_deploy`. PostgreSQL, S3, volumes and runtime settings unchanged.
- **Railway deployment state:** `SUCCESS`. The old deployment is `REMOVED` from serving, but listed as `canRollback=true`.
- **Migration:** runtime logs show `20261031181500 AddLanguageToBulletins` executed successfully as `add_column :bulletins, :language, :string, default: "ru", null: false` (0.0035 seconds). **No post-deploy direct SQL schema-migration query performed through this chat.**
- **Runtime:** Ruby 3.4.12, Rails 8.1.4, Puma 7.0.3. `/up` healthcheck returned `200 OK`.
- **HTTP metrics:** a sampled 1-hour Railway window after release reported 23 requests: 23 × 2xx, 0 × 4xx, 0 × 5xx; error rate 0%. This is an observation window, not an uptime SLA.

## Read-only public smoke test

- `/` default RU: title `Classifieds · Объявления`; 17 published listings.
- `/?locale=en`: `Classifieds · Listings`; `Catalog`, `Found: 17`; categories and dates translated.
- `/?locale=hy`: `Classifieds · Հայտարարություններ`; `Կատալոգ`, `Գտնվել է՝ 17`; categories and dates translated.
- `/bulletins/17?locale=en` and `/bulletins/17?locale=hy`: served a detail page for an existing listing and included five gallery image references. Gallery image bytes and responsive layout were **not independently browser-verified**.
- Published listing title/body remain in their original Russian on EN/HY pages **by design**; this is stored user content, not a localization regression.
- No login, admin permission, favorite mutation, new listing, or messaging workflow was performed against production.

## Backup and recovery

- Before deployment, user-owned Railway PostgreSQL custom-format dump `~/Backups/classifieds/classifieds_pre_i18n_20261031.dump` had SHA-256
  `a24a7f51bcbb99e3adfabc4f915083cbe56012fe190abdd544345ea2525f286a`, verified after SCP to Linux Mint.
- The same backup restored successfully into isolated Docker PostgreSQL 18 with `--network none`; database counts matched read-only production baseline: 18 total bulletins (17 published, 1 archived), 3 categories, 1 user, 21 Active Storage blobs and 21 attachments. Test DDL assigned language `ru` to 18/18 rows, then `ROLLBACK` was verified. Temporary restore container was removed.
- Before deployment, live Active Storage S3 HEAD checks: `S3_BLOBS_CHECKED=21`, `S3_MISSING=0`.
- **Limitations:** No standalone S3 byte backup; Railway native volume backups require plan upgrade, so do not claim Railway snapshot/PITR. Database dump includes a point-in-time snapshot, not later writes. Pre-deploy S3 HEAD checks are not a post-deploy proof of all object bytes.
- Safe code rollback: redeploy previous `e6c0098` image/build on `classifieds-web`. Additive `language` column can remain; do not roll back the schema or replace the production DB automatically. Database recovery would require separate PG18 instance, isolated restore, validation, and approval before cutover.

## Unverified acceptance and follow-up

1. On the owner's browser, inspect RU/EN/HY language switcher, dark/light theme, gallery images, mobile layout (390 px), OAuth sign-in, authorized private pages and moderation controls. Avoid mutating non-QA listings.
2. Read-only production SQL and S3 recheck after deployment (from the owner's Railway CLI); the automatic migration is confirmed by runtime logs but aggregate post-deploy SQL has not yet been rerun.
3. Arrange a separate encrypted/off-device PostgreSQL backup and consider a proper S3 objects backup. Do not treat Active Storage metadata as image bytes.
4. Investigate Rails 8.2 future deprecation: `ActiveSupport::Configurable`; it did not block the release.

**Source of truth:** Railway deployment/runtime logs, Railway HTTP metrics, public read-only page checks, owner Linux command output, and GH PR #47. **No secrets or private row content recorded.**

**Git note:** `feature/classifieds-p0-security` is fully behind `main` with 0 ahead commits (remote). Owner's older local checkout remains on `5566195` and contains untracked `classifieds_demo_transfer.rb`; it was not changed or uploaded in this release.
