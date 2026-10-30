---
name: biotic-server-setup
description: Download, install, update, or maintain the IMR Biotic DuckDB database with BioticExplorerServer. Use compileDatabase() for first-time setup and updateDatabase() for routine refreshes. Use when the user wants to set up the database, update it to newer data, fix a missing or outdated database, or check its location. Handles intranet checks, monitored background jobs, incremental changed-year updates, and safe full rebuilds when schemas change.
---

<!-- pack-resources:start -->
**Pack resources:** the `BAIT` root is `~/.bait/config.json` → `bait_path`, else `~/.fiskwise/config.json` →
`components.BAIT.path`, else the checkout containing this skill. Paths such as `knowledge/`
and `project-template/` are relative to that root, never `../../` from a skills folder; resolve
links that leave this skill's folder against the source skill there. Use absolute paths.
<!-- pack-resources:end -->


# Set up & maintain the Biotic database

The database is a **DuckDB** file built by
[BioticExplorerServer](https://github.com/DeepWaterIMR/BioticExplorerServer). Default
location: `~/IMR_biotic_BES_database/bioticexplorer.duckdb` (>2 GB). On Windows the default
is `%USERPROFILE%\IMR_biotic_BES_database\bioticexplorer.duckdb`, because R may expand `~` to
the user's Documents folder, which OneDrive often redirects. BioticExplorerServer >= 0.8.7
resolves this itself (`defaultDbPath()`), but keep passing an explicit path so setup behaves
the same on older versions. Use the chosen `bes_db_path` from `~/.bait/config.json` if BAIT
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

In Fiskwise-managed mode, R package checks and changes must go through the consent-aware
Fiskwise package-management workflow. Respect its saved R-install consent, disabled install
environment variables, project `renv.lock`, and version pins; do not install or update a
package a second time. If package installation/update is not permitted, report that the
database operation cannot proceed until the user chooses an allowed package setup. Standalone
use continues below with the user's authorization.

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
  "LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 Rscript -e 'library(BioticExplorerServer); compileDatabase(dbPath=\"$DB\")' > \"$LOG\" 2>&1"
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

Run it as a monitored background job, as for the initial download. The job brackets the
update with BAIT's `scripts/db-update-report.R`: a **snapshot** of the database before the
update, and a **report** afterwards that counts what changed and flags suspicious entries in
the new data (see "After the update" below). `BAIT` is `bait_path` from `~/.bait/config.json`.

**macOS/Linux:**

```bash
DB="$HOME/IMR_biotic_BES_database"; mkdir -p "$DB"
BAIT="<bait_path>"
LOG="$DB/bes_download_log.log"
REPORT="$BAIT/scripts/db-update-report.R"
screen -dmS bes_update bash -lc \
  "export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8; { Rscript \"$REPORT\" snapshot \"$DB/bioticexplorer.duckdb\"; \
     Rscript -e 'library(BioticExplorerServer); updateDatabase(dbPath=\"$DB\")' && \
     Rscript \"$REPORT\" report \"$DB/bioticexplorer.duckdb\"; } > \"$LOG\" 2>&1"
```

**Windows (PowerShell, after resolving `$Rscript` as in Step 2):**

```powershell
$DB = Join-Path $env:USERPROFILE "IMR_biotic_BES_database"
New-Item -ItemType Directory -Force $DB | Out-Null
$DB_R = $DB -replace "\\", "/"
$LOG = Join-Path $DB "bes_download_log.log"
$ERR = Join-Path $DB "bes_download_err.log"
$Script = Join-Path $env:TEMP "bes_update.R"
$Report = (Join-Path "<bait_path>" "scripts/db-update-report.R") -replace "\\", "/"
@"
db_file <- file.path("$DB_R", "bioticexplorer.duckdb")
report <- function(mode) system2(file.path(R.home("bin"), "Rscript"),
                                 c(shQuote("$Report"), mode, shQuote(db_file)))
if (file.exists(db_file)) report("snapshot")
library(BioticExplorerServer)
updateDatabase(dbPath = "$DB_R")
report("report")
"@ | Out-File -FilePath $Script -Encoding utf8
Start-Process -WindowStyle Hidden -FilePath $Rscript `
  -ArgumentList $Script `
  -RedirectStandardOutput $LOG -RedirectStandardError $ERR
```

Monitor `bes_download_log.log`. The first update after either a legacy database or a fresh
`compileDatabase()` build creates the API delivery manifest. It compares API timestamps with
the database build time, so it refreshes only data published since the build instead of
re-downloading unchanged years. Malformed API inventory years outside the supported
1900–current-year range are ignored automatically. A small aggregate warning about deliveries
that disappeared between inventory and metadata lookup is safe: those deliveries are skipped
for that run and can be checked again by the next update. If the log says the schema is
incompatible, a full rebuild is expected and the active database remains usable until the
validated replacement is ready. On successful completion, `updateDatabase()` and
`compileDatabase()` print stable start, finish, and elapsed-minute messages. Read the final
`Update took ... minutes.` or `Compilation took ... minutes.` line from the log and report it
to the user; the matching `finished successfully` line confirms that the duration is final.

### After the update: report what changed and what looks wrong

When the job has finished, read `<DB>/bait_update_report.md` (also at the end of the log) and
tell the user, in plain words:

1. **What is new.** The headline counts (new/changed/removed missions; net stations, catch rows,
   individuals, age readings) and which surveys or mission types the new data come from (the
   "Missions with the largest changes" and "By mission type" tables). Name surveys by cruise
   series name where `cruiseseriescode` is set (`csindex`).
2. **Suspicious entries.** Go through each finding in the report: what it is, how many records,
   which survey/vessel/years, and the consequence for analyses. Use the explanation printed
   under each heading. Separate the three kinds:
   - **Database bugs** (byte-escaped text, duplicated catch samples or individuals): act on
     them, following [`../../knowledge/data-quality.md`](../../knowledge/data-quality.md):
     repair if a repair exists, otherwise draft a BioticExplorerServer bug report.
   - **Source-data errors** (impossible or outlying values, unit slips such as grams entered as
     kg, missing positions, double-encoded text, new spellings of an existing species name):
     name the records (vessel, serial number, specimen) so the user can pass them to the cruise
     leader or the NMD data managers. Do not edit the database to "fix" them.
   - **Notes** (checklist rows without weight or count, new taxa): explain what they mean for
     analyses; they are not errors.
3. If the report says **"No snapshot found"**, the checks ran on the whole database and changes
   could not be counted; say so. The snapshot is taken automatically at the start of the next
   update.

The snapshot and report contain station-level details: keep them local (see `biotic-privacy`).
To run the report by hand (e.g. after a first download, without a snapshot):

```bash
Rscript "<bait_path>/scripts/db-update-report.R" report "$DB/bioticexplorer.duckdb"
```

Routine updates also refresh the `csindex`, `gearindex`, `taxaindex`, and `codeindex`
reference tables before processing changed years. Fresh cruise-series and gear mappings are
therefore applied immediately to any annual data replaced during that run.

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
- **`utils::menu()` failed in background Rscript?** Fixed in BioticExplorerServer >= 0.8.7,
  which creates a missing database folder without prompting in non-interactive sessions. On
  older versions the target directory was probably not created at the same path that
  `compileDatabase()` received: pre-create `%USERPROFILE%\IMR_biotic_BES_database\` and pass
  that exact absolute path.
- **Text shows `<c3><a5>` instead of `å`?** (e.g. `bl<c3><a5>kveite`.) Years written by
  BioticExplorerServer <= 0.8.8 under a non-UTF-8 locale. Fixed in >= 0.8.9, which also forces a
  UTF-8 locale during compile/update and warns after an update if escaped text remains. Repair
  in place with `BioticExplorerServer::repairDatabaseEncoding()` (`dryRun = TRUE` only checks),
  or rebuild with `compileDatabase(overwrite = TRUE)`. Detection query, decision steps and the
  bug-report template:
  [`../../knowledge/data-quality.md`](../../knowledge/data-quality.md#text-encoding-corruption).

## After setup

Verify with [`../biotic-connect/SKILL.md`](../biotic-connect/SKILL.md) and, if helpful, give a
brief privacy reminder via [`../biotic-privacy/SKILL.md`](../biotic-privacy/SKILL.md) rather
than re-blocking on a fresh confirmation each time. Updates to BAIT itself:
[`../bait-update/SKILL.md`](../bait-update/SKILL.md).
