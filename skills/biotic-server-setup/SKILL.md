---
name: biotic-server-setup
description: Download, install, update, or maintain the IMR Biotic DuckDB database with BioticExplorerServer's compileDatabase(). Use when the user wants to set up the database, refresh/update it to newer data, fix a missing or outdated database, or check its location. Handles the intranet check, runs the long download as a monitored background job with a log, and swaps the database safely.
---

# Set up & maintain the Biotic database

The database is a **DuckDB** file built by
[BioticExplorerServer](https://github.com/DeepWaterIMR/BioticExplorerServer). Default
location: `~/IMR_biotic_BES_database/bioticexplorer.duckdb` (>2 GB). Use the chosen
`bes_db_path` from `~/.bait/config.json` if BAIT was installed with `bait-install`.

## 0. Pre-flight (do this before downloading)

1. **🔒 Location check (download = first-time or update).** The database must **not** live at a
   filesystem root or system dir (`/`, `C:\`, `C:\Program Files`, …). If asked to put it
   there, **refuse and suggest a user-space location**. Prefer the default
   `~/IMR_biotic_BES_database/`; avoid cloud-synced/backup folders (large + sensitive).
2. **🌐 Intranet required (download only).** Building/updating downloads from the **IMR
   intranet** — the user must be on **VPN or HI-Adm Wi-Fi**.
   - Best-effort check: try to reach an IMR-internal endpoint the download uses (not the public
     `hi.no`). If unreachable, **ask the user to connect to VPN / HI-Adm before continuing.**
   - Note: intranet is needed **only** for downloading (initial setup and updates). Once the
     `.duckdb` exists, querying it is fully offline/local.
3. **⏱️ Set expectations.** Tell the user the download can take **up to several hours**
   depending on connection. **Do not** run it over **mobile internet or Starlink** (e.g. on
   research vessels) — use a stable cable/Wi-Fi intranet connection.
4. **📦 Package up-to-date check.** Always confirm BioticExplorerServer matches the latest on
   GitHub before a download or update — do **Step 1** first.

## 1. Install / update the package — REQUIRED before any download or update

Before a **first download (Step 2)** or an **update (Step 3)**, ensure the locally installed
**BioticExplorerServer matches the latest on GitHub**. The download/compile logic — and the DB
schema (e.g. the `taxaindex` table) — change over time, so running an old version against the
live data can produce a broken or out-of-date database.

```r
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
# remotes compares the installed git SHA against GitHub and reinstalls ONLY if there is a
# newer commit — so this single call *is* the up-to-date check:
remotes::install_github("DeepWaterIMR/BioticExplorerServer")
```

To explicitly report whether an update was available (e.g. to tell the user):
```r
local_ver  <- as.character(utils::packageVersion("BioticExplorerServer"))
remote_ver <- read.dcf(url(
  "https://raw.githubusercontent.com/DeepWaterIMR/BioticExplorerServer/master/DESCRIPTION"
))[, "Version"]
utils::compareVersion(remote_ver, local_ver)   # 1 = GitHub newer, 0 = same, -1 = local ahead
```

- Needs **general internet / GitHub** access (separate from the IMR intranet used for the data).
- **Compile in a fresh R session after an update.** Steps 2–3 launch the download in a new
  background `Rscript`, so they automatically pick up the just-installed version — don't call
  `compileDatabase()` in a session that already loaded the old package.
- Keep `duckdb` current too (see Maintenance).

## 2. First-time download — as a monitored background job with a log

> ⚠️ Do **Step 1** (package up-to-date check) first.

Run the download **detached** so it survives the terminal/agent session, and **log** it next
to the database as `bes_download_log.log`.

**macOS / Linux (screen; or tmux/nohup if screen is absent):**
```bash
DB="$HOME/IMR_biotic_BES_database"; mkdir -p "$DB"
LOG="$DB/bes_download_log.log"
screen -dmS bes_download bash -lc \
  "Rscript -e 'library(BioticExplorerServer); compileDatabase(dbPath=\"$DB\")' > \"$LOG\" 2>&1"
```

**Windows (PowerShell, background process):**
```powershell
$DB = "$HOME\IMR_biotic_BES_database"; New-Item -ItemType Directory -Force $DB | Out-Null
$LOG = Join-Path $DB "bes_download_log.log"
Start-Process -WindowStyle Hidden -FilePath "Rscript" `
  -ArgumentList '-e','library(BioticExplorerServer); compileDatabase(dbPath="~/IMR_biotic_BES_database")' `
  -RedirectStandardOutput $LOG -RedirectStandardError "$DB\bes_download_err.log"
```

**Monitor it** (the job runs for a long time — check in, don't block):
```bash
tail -n 30 "$LOG"     # progress; screen -ls shows the session; reattach with: screen -r bes_download
```
Tell the user it's running, roughly how long, and that they can keep working / close the
terminal. Check the log periodically and report progress or errors. Verify on completion:
```r
file.exists(path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"))
```

## 3. Update the database (fresh data)

No change-timestamps upstream ⇒ update = full re-download. Repeat the **pre-flight** first —
especially **Step 1 (ensure BioticExplorerServer is up to date on GitHub)** and the intranet
check. **Safe pattern** — build alongside, then swap, so a failed download never destroys the
working database. Run this in the background with logging exactly as in Step 2:

```r
library(BioticExplorerServer)
compileDatabase(dbPath = "~/IMR_biotic_BES_database",
                dbName = "bioticexplorer-next")          # download to a temp name

unlink(normalizePath("~/IMR_biotic_BES_database/bioticexplorer.duckdb"))
file.rename(
  normalizePath("~/IMR_biotic_BES_database/bioticexplorer-next.duckdb"),
  normalizePath("~/IMR_biotic_BES_database/bioticexplorer.duckdb", mustWork = FALSE))
```

Only run the `unlink`/`file.rename` swap **after** the log shows the `-next` download finished
successfully. Quicker but riskier in-place option: `compileDatabase(..., overwrite = TRUE)`.

## 4. Maintenance & troubleshooting

- **Close other connections first.** R sessions / BioticExplorer holding the file block an
  update. `DBI::dbDisconnect(con, shutdown = TRUE)`.
- **Keep `duckdb` current.** The file format is tied to the writing `duckdb` version;
  mismatches cause open errors. `install.packages("duckdb")`, then rebuild.
- **Disk hygiene.** Remove stale `*-next.duckdb` / `*.wal` and old logs after a successful swap.
- **Download failed / stalled?** Read `bes_download_log.log`: a connection error usually means
  the intranet dropped (reconnect VPN/HI-Adm and re-run); disk-full means free space (>2 GB).

## After setup

Verify with [`../biotic-connect/SKILL.md`](../biotic-connect/SKILL.md) and remind the user of
the privacy pre-flight in [`../biotic-privacy/SKILL.md`](../biotic-privacy/SKILL.md). Updates
to BAIT itself: [`../bait-update/SKILL.md`](../bait-update/SKILL.md).
