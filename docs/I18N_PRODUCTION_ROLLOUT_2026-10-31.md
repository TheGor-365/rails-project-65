# Classifieds — RU/EN/HY production release gate (6B)

**Prepared:** 2026-10-31. **Status: backup verified via isolated logical restore; deployment still requires explicit owner approval.**  
**Repo:** https://github.com/TheGor-365/rails-project-65  
**Candidate application main after i18n QA:** `69ea5dcc9f872421d982caea2b10f7e6ec8c6822` (reverify main HEAD and CI just before release; later commits may change the exact SHA).  
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
| **Backup status** | **VERIFIED manual logical backup**: `~/Backups/classifieds/classifieds_pre_i18n_20261031.dump` (Linux Mint), SHA-256 verified, successfully restored to separate Docker PostgreSQL 18 and count-checked. Railway **native volume backups unavailable on current plan** (Backups UI: Upgrade to Pro). |
| **PITR** | Not available under the currently shown Backups tab without upgrading to Pro; no PITR backup or restore is claimed. |

No variable **values** should be copied into docs, PR descriptions, chat, CI logs or screenshots.

## 2. Critical migration behavior

The existing production build was confirmed to load the project's `Dockerfile`. Its `bin/docker-entrypoint` executes `./bin/rails db:prepare` **before** running Rails server. The candidate source includes `db/migrate/20261031181500_add_language_to_bulletins.rb`:

```ruby
add_column :bulletins, :language, :string, default: 'ru', null: false
```

This is an **additive** migration. Existing Russian rows receive `ru` through the DB default; titles, descriptions, AASM state, owners and image attachments are not rewritten. **However, the migration will run automatically during deployment.** There is no safe "deploy now, back up later" option.

Never run `db:reset`, `db:drop`, `db:seed`, `db:schema:load`, `db:rollback`, or `rails db:prepare` manually against production as a preflight.

## 3. Completed manual logical backup — proof and limitations

1. **31 October 2026, user terminal:** Railway PostgreSQL 18.6 `pg_dump -Fc --no-owner --no-acl` completed as `/tmp/classifieds_pre_i18n_20261031.dump` inside Railway Postgres. `scp` copied it to `~/Backups/classifieds/classifieds_pre_i18n_20261031.dump` on Linux Mint.
2. **Checksum:** `a24a7f51bcbb99e3adfabc4f915083cbe56012fe190abdd544345ea2525f286a`, verified locally (`sha256sum -c` reported **ЦЕЛ**). `pg_restore --list` and `pg_restore --file=/dev/null` passed.
3. **Full isolated restore:** Docker `postgres:18` with `--network none`, no exposed ports and dump mounted read-only; `pg_restore --exit-on-error --single-transaction --no-owner --no-acl` returned **RESTORE OK**. All checked table counts matched read-only production SQL. The temporary container was subsequently stopped/removed; the host dump remains.
4. **SQL migration rehearsal:** inside restored copy, `ALTER TABLE bulletins ADD COLUMN language varchar DEFAULT 'ru' NOT NULL` assigned Russian to all **18/18** rows with **0 NULLs**. `ROLLBACK` succeeded and subsequent schema query confirmed **`language` absent**.
5. **S3 HEAD audit:** Rails runner in the live Railway app checked all **21** Active Storage blobs and returned **`S3_BLOBS_CHECKED=21`, `S3_MISSING=0`**. This proves referenced object availability at check time; it **does not** produce a backup of S3 object bytes.
6. **Railway dashboard:** Postgres Backups tab showed **No Backups / Upgrade to Pro**. Native volume backup and PITR are not available on current plan. The usable recovery copy is the user-owned logical `.dump`, not a Railway snapshot.

**Recovery protection:** Keep the local `.dump` private and, before deployment, preferably make a second encrypted off-device copy. Do not share its contents, secrets or credentials. This backup is a single point-in-time copy; changes after its creation are not included. No independent S3 backup has been made.

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

**Verified 2026-10-31 snapshot:** 18 bulletins (17 published, 1 archived), 3 categories, 1 user, 0 conversations, 0 messages, 0 favorites, 21 Active Storage blobs, 21 attachments and `bulletins.language` absent. Backup and production agreed on all shared aggregate checks. S3 storage reported 21/21 referenced blobs present. Recheck counts if production changes before deployment; row counts alone are not a byte-for-byte verification.

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
- The completed manual logical dump is retained, has verified checksum, and has been successfully restored to a separate PG18 instance (done 2026-10-31).
- Live preflight aggregate counts and `missing_s3_keys=0` are recorded (done 2026-10-31); recheck if there is new production traffic.
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
- **Actual DB corruption:** since Railway native backups are unavailable on this plan, **do not assume Backups -> Restore can help**. Preserve the current DB first, provision a separate PostgreSQL 18 recovery database, restore the private logical dump with `pg_restore`, verify integrity, then explicitly approve connection-string cutover after understanding data written since the backup will be lost. Never restore the dump over the live database as a first action.
- **S3 issue:** Railway Postgres backup does not include `classifieds-media`; inspect bucket/object availability separately. Do not reset bucket credentials or delete objects for an i18n release.
- **Isolated `pg_restore` drill completed on 2026-10-31**. This verifies archive restore to a separate PostgreSQL 18, not full application cutover or S3 recovery.

## Status checkpoint

As of 2026-10-31: manual logical backup **created / checksum-verified / restored on isolated PostgreSQL 18**; production vs backup aggregates matched; **S3 referenced objects 21/21 exist**; migration's SQL backfill and `ROLLBACK` tested on recovered copy; test Docker container removed. Remote `feature/classifieds-p0-security` is an ancestor of `main` (**0 unique remote commits; 197 commits behind main**); uncommitted local branch changes remain unverified. Current `main` at time of checkpoint: `69ea5dc`; Railway app remains pinned to `e6c0098`; no staged patch. **No production deploy requested or performed. Next gate: inspect local uncommitted changes, then seek explicit owner approval for a pinned production source update.**
