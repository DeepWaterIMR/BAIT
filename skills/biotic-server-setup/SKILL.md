---
name: biotic-server-setup
description: Download, install, update, or maintain the IMR Biotic DuckDB database with BioticExplorerServer. Use compileDatabase() for first-time setup and updateDatabase() for routine refreshes. Use when the user wants to set up the database, update it to newer data, fix a missing or outdated database, or check its location. Handles intranet checks, monitored background jobs, incremental changed-year updates, and safe full rebuilds when schemas change.
---

# Set up & maintain the Biotic database

The database is a **DuckDB** file built by
[BioticExplorerServer](https://github.com/DeepWaterIMR/BioticExplorerServer). Default
location: `~/IMR_biotic_BES_database/bioticexplorer.duckdb` (>2 GB). On Windows, prefer an
explicit path under `%USERPROFILE%` such as
`C:/Users/<user>/IMR_biotic_BES_database/bioticexplorer.duckdb`, because R may expand `~` to
the user's Documents folder. Use the chosen `bes_db_path` from `~/.bait/config.json` if BAIT
was installed with `bait-install`.

## 0. Pre-flight (do this before downloading)

1. **🔒 Location check (download = first-time or update).** The database must **not** live at a
   filesystem root or system dir (`/`, `C:\`, `C:\Program Files`, …). If asked to put it
   there, **refuse and suggest a user-space location**. Prefer the default
   `~/IMR_biotic_BES_database/` on macOS/Linux, or
   `%USERPROFILE%\IMR_biotic_BES_database\` on Windows; avoid cloud-synced/backup folders
   such as OneDrive Documents (large + sensitive).
2. **🌐 Intranet required (download only).** Building/updating downloads from the **IMR
   intranet** — the user must be on **VPN or HI-Adm Wi-Fi**.
   - Best-effort check: try to reach `https://biotic-api.hi.no`, the IMR-internal endpoint
     used by the download (not the public `hi.no`). A 200/404-style HTTP response is enough;
     DNS/connection failure means the intranet is unreachable. If unreachable, **ask the user
     to connect to VPN / HI-Adm before continuing.**
     ```r
     httr::GET("https://biotic-api.hi.no")
     ```
   - Note: intranet is needed **only** for downloading (initial setup and updates). Once the
     `.duckdb` exists, querying it is fully offline/local.
3. **⏱️ Set expectations.** A first download or schema-triggered full rebuild can take
   **several hours**. A routine update first checks lightweight delivery metadata and downloads
   only changed years, so it is usually much faster. **Do not** download over **mobile internet
   or Starlink** (e.g. on research vessels) — use a stable cable/Wi-Fi intranet connection.
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
- **Use a fresh R session after a package update.** Steps 2–3 launch a new background
  `Rscript`, so they automatically pick up the just-installed version. Do not call
  `compileDatabase()` or `updateDatabase()` in a session that already loaded the old package.
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
$DB = Join-Path $env:USERPROFILE "IMR_biotic_BES_database"
New-Item -ItemType Directory -Force $DB | Out-Null
$LOG = Join-Path $DB "bes_download_log.log"
$ERR = Join-Path $DB "bes_download_err.log"

$Rscript = (Get-Command Rscript.exe -ErrorAction SilentlyContinue).Source
if (-not $Rscript) {
  $RPath = (Get-ItemProperty "HKLM:\SOFTWARE\R-core\R" -ErrorAction SilentlyContinue).InstallPath
  if (-not $RPath) {
    $RPath = (Get-ItemProperty "HKCU:\SOFTWARE\R-core\R" -ErrorAction SilentlyContinue).InstallPath
  }
  if ($RPath) { $Rscript = Join-Path $RPath "bin\Rscript.exe" }
}
if (-not $Rscript -or -not (Test-Path $Rscript)) {
  throw "Could not find Rscript.exe. Add R to PATH or set `$Rscript to the full path."
}

$DB_R = $DB -replace "\\", "/"
$Script = Join-Path $env:TEMP "bes_compile.R"
@"
library(BioticExplorerServer)
compileDatabase(dbPath = "$DB_R")
"@ | Out-File -FilePath $Script -Encoding utf8

Start-Process -WindowStyle Hidden -FilePath $Rscript `
  -ArgumentList $Script `
  -RedirectStandardOutput $LOG -RedirectStandardError $ERR
```

**Monitor it** (the job runs for a long time — check in, don't block):
```bash
tail -n 30 "$LOG"     # progress; screen -ls shows the session; reattach with: screen -r bes_download
```
Tell the user it's running, roughly how long, and that they can keep working / close the
terminal. Check the log periodically and report progress or errors. Verify on completion:
```r
default_db_dir <- if (.Platform$OS.type == "windows") {
  file.path(Sys.getenv("USERPROFILE"), "IMR_biotic_BES_database")
} else {
  path.expand("~/IMR_biotic_BES_database")
}
file.exists(file.path(default_db_dir, "bioticexplorer.duckdb"))
```

## 3. Update the database (incremental changed-year refresh)

Repeat the **pre-flight** first—especially **Step 1** (install the latest
BioticExplorerServer) and the intranet check. Use `updateDatabase()`, not `compileDatabase()`:

- it checks metadata for each API delivery;
- downloads and transactionally replaces only changed, added, or removed years;
- keeps the existing year if downloading, parsing, or writing fails;
- automatically calls `compileDatabase()` to build, validate, and safely swap a complete
  sibling database if the package's database schema changed.

Run it as a monitored background job, as for the initial download.

**macOS/Linux:**

```bash
DB="$HOME/IMR_biotic_BES_database"; mkdir -p "$DB"
LOG="$DB/bes_download_log.log"
screen -dmS bes_update bash -lc \
  "Rscript -e 'library(BioticExplorerServer); updateDatabase(dbPath=\"$DB\")' > \"$LOG\" 2>&1"
```

**Windows (PowerShell, after resolving `$Rscript` as in Step 2):**

```powershell
$DB = Join-Path $env:USERPROFILE "IMR_biotic_BES_database"
New-Item -ItemType Directory -Force $DB | Out-Null
$DB_R = $DB -replace "\\", "/"
$LOG = Join-Path $DB "bes_download_log.log"
$ERR = Join-Path $DB "bes_download_err.log"
$Script = Join-Path $env:TEMP "bes_update.R"
@"
library(BioticExplorerServer)
updateDatabase(dbPath = "$DB_R")
"@ | Out-File -FilePath $Script -Encoding utf8
Start-Process -WindowStyle Hidden -FilePath $Rscript `
  -ArgumentList $Script `
  -RedirectStandardOutput $LOG -RedirectStandardError $ERR
```

Monitor `bes_download_log.log`. A first update of a legacy database creates a metadata-only
delivery manifest; it may refresh years changed since the database was built. If the log says
the schema is incompatible, a full rebuild is expected and the active database remains usable
until the validated replacement is ready.

Direct foreground use is simply:

```r
library(BioticExplorerServer)
default_db_dir <- if (.Platform$OS.type == "windows") {
  file.path(Sys.getenv("USERPROFILE"), "IMR_biotic_BES_database")
} else {
  path.expand("~/IMR_biotic_BES_database")
}

updateDatabase(dbPath = default_db_dir)
```

## 4. Maintenance & troubleshooting

- **Close other connections first.** R sessions / BioticExplorer holding the file block an
  update. `DBI::dbDisconnect(con, shutdown = TRUE)`.
- **Keep `duckdb` current.** The file format is tied to the writing `duckdb` version;
  mismatches cause open errors. `install.packages("duckdb")`, then rebuild.
- **Disk hygiene.** Remove stale `*-next-*.duckdb` / `*.wal` and old logs after a successful
  update, but never while an update is running.
- **Download failed / stalled?** Read `bes_download_log.log`: a connection error usually means
  the intranet dropped (reconnect VPN/HI-Adm and re-run); disk-full means free space (>2 GB).
- **`utils::menu()` failed in background Rscript?** The target directory was probably not
  created at the same path that `compileDatabase()` received. On Windows especially, avoid
  `~`, pre-create `%USERPROFILE%\IMR_biotic_BES_database\`, and pass that exact absolute path.

## After setup

Verify with [`../biotic-connect/SKILL.md`](../biotic-connect/SKILL.md) and, if helpful, give a
brief privacy reminder via [`../biotic-privacy/SKILL.md`](../biotic-privacy/SKILL.md) rather
than re-blocking on a fresh confirmation each time. Updates to BAIT itself:
[`../bait-update/SKILL.md`](../bait-update/SKILL.md).
