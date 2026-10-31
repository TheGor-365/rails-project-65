# Classifieds — RU/EN/HY production release gate (6B)

**Prepared:** 2026-10-31. **Status: BLOCKED until verified PostgreSQL backup and owner approval.**  
**Repo:** https://github.com/TheGor-365/rails-project-65  
**Candidate main after i18n QA:** `8ede94488311bf7f5fe356bb1d3473d2bef51685` (reverify main HEAD just before release).  
**Deployed baseline:** `e6c009861caae2206da2e3052b02d71b8100e4d1`.  
**Production:** https://classifieds-web-production-9132.up.railway.app/

## 1. Confirmed Railway inventory (read-only API, 2026-10-31)

| Resource | ID / current configuration |
| --- | --- |
| Project | `classifieds-rails-project-65` / `8b19d2db-b1f4-4004-b2e6-653322aa49e1` |
| Environment | production / `ecf16233-fb99-41d7-af7f-467595c850fb` |
| Web | `classifieds-web` / `994a7daf-ad2a-492c-a833-15df99fd29b0`; source repo `main` pinned to deployed `e6c0098` |
| PostgreSQL | `Postgres` / `5f62983b-dc75-4974-a3d9-470615269f45`; image `ghcr.io/railwayapp-templates/postgres-ssl:18`; one replica |
| PostgreSQL volume | `postgres-volume` / `5ec377e6-f002-4315-a8a3-e263bf5b25df`; 5,000 MB, mounted at `/var/lib/postgresql/data` |
| S3 bucket | `classifieds-media` / `62331259-be52-4a8b-94fd-8371210a8e18` |
| Region | app/database: `europe-west4-drams3a`; bucket: `ams` |
| Staged patch | **None** (`staged=null`); no pending destructive changes |
| Deploy health | Most recent web deployment was successful but may be sleeping by policy (`sleepApplication=true`). Sleeping is not a failed deployment. |
| **Backup status** | **UNVERIFIED**. The connected Railway API cannot list volume-backup objects or their completion timestamps. A persistent volume is NOT itself a recoverable backup. |
| **PITR** | **UNVERIFIED**. Do not assume it is enabled; inspect the Postgres service Backups tab. |

No variable **values** should be copied into docs, PR descriptions, chat, CI logs or screenshots.

## 2. Critical migration behavior

The existing production build was confirmed to load the project's `Dockerfile`. Its `bin/docker-entrypoint` executes `./bin/rails db:prepare` **before** running Rails server. The candidate source includes `db/migrate/20261031181500_add_language_to_bulletins.rb`:

```ruby
add_column :bulletins, :language, :string, default: 'ru', null: false
```

This is an **additive** migration. Existing Russian rows receive `ru` through the DB default; titles, descriptions, AASM state, owners and image attachments are not rewritten. **However, the migration will run automatically during deployment.** There is no safe "deploy now, back up later" option.

Never run `db:reset`, `db:drop`, `db:seed`, `db:schema:load`, `db:rollback`, or `rails db:prepare` manually against production as a preflight.

## 3. Owner's backup action — required BEFORE deploy

1. Railway dashboard -> project `classifieds-rails-project-65` -> `production` -> **Postgres** service -> **Backups** tab.
2. Confirm whether manual backups and Daily/Weekly schedule exist. If a completed backup from before the migration exists, note its timestamp. Otherwise create one **manual backup** (only after reviewing any indicated charge). Wait for status **Completed/Success**, not just `Starting`.
3. Share a screenshot showing the **Postgres service** and **latest completed backup timestamp**, hiding any sensitive variables or connection URLs. Record screenshot date and backup timestamp here before release.
4. Prefer enabling a periodic schedule after checking Railway plan and storage costs; do not assume a schedule already exists.

Official docs: https://docs.railway.com/volumes/backups . Manual backup size limits apply. Railway restore creates a **replacement volume as a staged change**, leaving the previous volume unattached; it does **not** instantly revert application code. Restores are only supported within the same Railway project/environment. **Do not click Restore for a rehearsal on the working production service.**

Optional stronger recovery is PITR: https://docs.railway.com/volumes/point-in-time-recovery . PITR must first archive a complete base backup; enabling it is a new chargeable/possibly redeploying operation and is not a prerequisite for this single additive migration. Do not enable without consent.

## 4. Preflight counts (read-only; do not expose user details)

**After** backup proof, connect to the currently deployed `classifieds-web` container using Railway CLI (requires local SSH setup; run on user's Linux Mint). Official usage: https://docs.railway.com/cli/ssh .

```bash
railway ssh --project 8b19d2db-b1f4-4004-b2e6-653322aa49e1 \
  --service 994a7daf-ad2a-492c-a833-15df99fd29b0 \
  --environment production -- \
  bin/rails runner 'puts({bulletins: Bulletin.count, published: Bulletin.where(state: "published").count, archived: Bulletin.where(state: "archived").count, categories: Category.count, users: User.count, conversations: Conversation.count, messages: Message.count, favorites: Favorite.count, blobs: ActiveStorage::Blob.count, attachments: ActiveStorage::Attachment.count, language_column_present: Bulletin.column_names.include?("language")}.to_json)'
```

The command performs only SELECT-like count/schema introspection and prints aggregate counts; **do not** share any environment variables, passwords, URLs containing credentials, personal emails, or content of messages.

Expected **historical QA snapshot**, NOT a fresh DB verification: 18 bulletins (17 published, one archived QA), 3 canonical categories, 20 S3 objects according to earlier audit. A fresh snapshot may differ; record actual data instead of overwriting it. Database `ActiveStorage::Blob.count` is **not** equivalent to S3 object count; variants/unattached blobs may differ.

Optional S3 check (read-only HEAD, may have provider request costs; no raw keys in output):

```bash
railway ssh --project 8b19d2db-b1f4-4004-b2e6-653322aa49e1 \
  --service 994a7daf-ad2a-492c-a833-15df99fd29b0 \
  --environment production -- \
  bin/rails runner 'blobs=ActiveStorage::Blob.all; missing=0; blobs.find_each { |b| missing+=1 unless b.service.exist?(b.key) }; puts({blobs_checked:blobs.count, missing_s3_keys:missing}.to_json)'
```

Do not delete or rewrite any blob or bucket to make counts match. In case of error, preserve exact nonsecret error text and stop.

## 5. Authorization and deployment gate

Proceed only when the owner explicitly approves the actual production deployment **after**:
- A real completed backup is verified (timestamp and service).
- Live preflight aggregate counts and `missing_s3_keys=0` (or a documented exception) are recorded.
- Target commit HEAD is confirmed, and CI for candidate commit is green.
- Railway has **no staged changes**, and backup/volume/bucket are in a healthy state.
- Owner accepts any backup/restore/volume cost and potential brief downtime.
- A non-destructive rollback action and verification checklist is ready.

The web service is currently pinned to `e6c0098`. Do not remove the pin or switch to HEAD blindly; deploy a known validated target SHA through an explicit, reviewed service change. Review staged changes before applying them. Avoid changing Postgres, volumes or bucket in the same deploy.

## 6. Post-deploy smoke (after explicit approval, not now)

1. /up HTTP 200; home catalog, one bulletin show/gallery (existing images), language selector RU/EN/HY and dark/light themes at desktop + 390px; no horizontal overflow.
2. Auth GitHub OAuth callback; signed-in profile, admin moderation, favorite and new draft on current locale. Test listing create with deliberately named QA draft; do **not** publish/alter any non-QA listing.
3. Confirm `bulletins.language` exists and all preexisting rows have `ru`; current UI locale sets the initial language for **new** drafts; editing retains persisted language. No unexpected `Translation missing` or mixed UI copy.
4. Repeat preflight counts and S3 checks. Differences must be explained by intentionally created QA records (do not normalize/delete real data to match an old expected count).
5. Before making any public marketing screenshots, check image usage rights; never include private users' email addresses.

## 7. Rollback policy

- **UI/code regression, data intact:** redeploy known-good `e6c0098` application build. Existing added `language` column is backward compatible and can remain in DB. This is safer than rolling back a schema change while new data may exist.
- **Actual DB corruption:** stop any write-heavy traffic, preserve incident evidence and newest available DB state first, then inspect Railway Backups -> Restore. **Restore can replace the running DB volume and lose writes made after the backup.** Only do it with owner approval and an explicit recovery point.
- **S3 issue:** Railway Postgres backup does not include `classifieds-media`; inspect bucket/object availability separately. Do not reset bucket credentials or delete objects for an i18n release.
- Never claim disaster recovery was *tested* until a real isolated restore exercise has been completed.

## Status checkpoint

As of 2026-10-31: read-only Railway inventory confirmed; production backup completion **unknown**, current row counts **not sampled**, S3 object count **not rechecked**, no restoration tested, no production deploy requested or performed. Next step: Postgres Backups tab screenshot, then aggregate preflight counts, then separate explicit deployment approval.
