# Snapshot a BioticExplorerServer database before an update, then report what the
# update added, changed or removed, and flag suspicious entries in the new data.
#
#   Rscript db-update-report.R snapshot <bioticexplorer.duckdb> [snapshot.rds]
#   Rscript db-update-report.R report   <bioticexplorer.duckdb> [snapshot.rds] [report.md]
#
# Defaults: the snapshot is <db folder>/bait_snapshot.rds and the report
# <db folder>/bait_update_report.md. Both stay next to the database (they contain
# station-level details and must not be shared, see biotic-privacy). The report is
# also printed to stdout. Without a snapshot, the checks run on the whole database.
#
# Missions are matched on (missiontype, startyear, platform, missionnumber), because
# BioticExplorerServer's missionid is a row number that changes between downloads.

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2 || !args[1] %in% c("snapshot", "report")) {
  stop("Usage: Rscript db-update-report.R snapshot|report <db.duckdb> [snapshot.rds] [report.md]")
}
mode <- args[1]
db_file <- normalizePath(path.expand(args[2]), mustWork = TRUE)
snapshot_file <- if (length(args) >= 3) path.expand(args[3]) else file.path(dirname(db_file), "bait_snapshot.rds")
report_file <- if (length(args) >= 4) path.expand(args[4]) else file.path(dirname(db_file), "bait_update_report.md")

if (!isTRUE(l10n_info()[["UTF-8"]])) {
  for (locale in c("C.UTF-8", "en_US.UTF-8", "en_GB.UTF-8", "UTF-8")) {
    if (nzchar(suppressWarnings(Sys.setlocale("LC_CTYPE", locale)))) break
  }
}

con <- dbConnect(duckdb(), dbdir = db_file, read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
q <- function(sql) dbGetQuery(con, sql)

KEY <- c("missiontype", "startyear", "platform", "missionnumber")
key_sql <- function(alias = NULL) paste0(if (!is.null(alias)) paste0(alias, ".") else "", KEY, collapse = ", ")
key_join <- function(a, b) paste0(a, ".", KEY, " IS NOT DISTINCT FROM ", b, ".", KEY, collapse = " AND ")

# ---- Snapshot ---------------------------------------------------------------

take_snapshot <- function() {
  list(
    taken = Sys.time(),
    metadata = q("SELECT * FROM metadata"),
    year_counts = q("
      SELECT 'mission' AS tab, startyear, count(*) AS n FROM mission GROUP BY ALL
      UNION ALL SELECT 'stnall', startyear, count(*) FROM stnall GROUP BY ALL
      UNION ALL SELECT 'indall', startyear, count(*) FROM indall GROUP BY ALL
      UNION ALL SELECT 'ageall', startyear, count(*) FROM ageall GROUP BY ALL"),
    missions = q(paste0("
      SELECT ", key_sql("m"), ", m.missiontypename, m.platformname, m.cruise, m.cruiseseriescode,
             coalesce(s.stations, 0) AS stations, coalesce(s.stn_rows, 0) AS stn_rows,
             coalesce(i.ind_rows, 0) AS ind_rows
      FROM mission m
      LEFT JOIN (SELECT ", key_sql(), ", count(DISTINCT serialnumber) AS stations, count(*) AS stn_rows
                 FROM stnall GROUP BY ALL) s ON ", key_join("m", "s"), "
      LEFT JOIN (SELECT ", key_sql(), ", count(*) AS ind_rows FROM indall GROUP BY ALL) i
             ON ", key_join("m", "i"))),
    names = q("SELECT aphia, commonname, count(*) AS n FROM stnall
               WHERE commonname IS NOT NULL GROUP BY ALL")
  )
}

if (mode == "snapshot") {
  snap <- take_snapshot()
  saveRDS(snap, snapshot_file)
  cat("Snapshot written to", snapshot_file, "\n")
  cat(sprintf("Missions: %d, stnall: %d, indall: %d rows\n", nrow(snap$missions),
              sum(snap$missions$stn_rows), sum(snap$missions$ind_rows)))
  quit(save = "no", status = 0)
}

# ---- Report -----------------------------------------------------------------

out <- character()
say <- function(...) out <<- c(out, paste0(...))
fmt <- function(x) format(x, big.mark = " ", scientific = FALSE, trim = TRUE)
md_table <- function(df, max_rows = 15) {
  if (!nrow(df)) return(invisible())
  extra <- nrow(df) - max_rows
  df <- utils::head(df, max_rows)
  ids <- c("startyear", "first_year", "last_year", "serialnumber", "specimenid", "catchsampleid",
           "aphia", "example_serialnumber", "example_specimenid", "worst_serialnumber", "worst_specimenid", "cruiseseriescode", "age")
  df[] <- lapply(names(df), function(v) {
    x <- df[[v]]
    x <- if (is.numeric(x) && !v %in% ids) fmt(round(x, 3)) else as.character(x)
    x[is.na(x)] <- "NA"
    gsub("\\|", "/", substr(x, 1, 60))
  })
  say("| ", paste(names(df), collapse = " | "), " |")
  say("|", paste(rep("---", ncol(df)), collapse = "|"), "|")
  for (i in seq_len(nrow(df))) say("| ", paste(unlist(df[i, ]), collapse = " | "), " |")
  if (extra > 0) say("\n*… and ", fmt(extra), " more.*")
  say("")
}

now <- take_snapshot()
has_snapshot <- file.exists(snapshot_file)
old <- if (has_snapshot) readRDS(snapshot_file) else NULL

say("# Biotic database update report")
say("")
say("- Database: `", db_file, "`")
say("- Database updated: ", now$metadata$timeend[1], " (BioticExplorerServer ",
    now$metadata$package_version[1], ", ", now$metadata$update_mode[1], ")")
say("- Report written: ", format(Sys.time(), "%Y-%m-%d %H:%M"))

# Which missions are new, changed or removed?
mkey <- function(d) do.call(paste, c(d[KEY], sep = "\r"))
if (has_snapshot) {
  say("- Compared with snapshot taken ", format(old$taken, "%Y-%m-%d %H:%M"),
      " (database updated ", old$metadata$timeend[1], ")")
  say("")
  desc <- c("missiontypename", "platformname", "cruise", "cruiseseriescode")
  nums <- c("stations", "stn_rows", "ind_rows")
  o <- old$missions; o$in_old <- TRUE
  n <- now$missions; n$in_new <- TRUE
  m <- merge(n, o, by = KEY, all = TRUE, suffixes = c("", "_old"))
  for (v in desc) m[[v]] <- ifelse(is.na(m$in_new), m[[paste0(v, "_old")]], m[[v]])
  for (v in c(nums, paste0(nums, "_old"))) m[[v]][is.na(m[[v]])] <- 0
  m$status <- ifelse(is.na(m$in_old), "new", ifelse(is.na(m$in_new), "removed",
               ifelse(m$stn_rows != m$stn_rows_old | m$ind_rows != m$ind_rows_old |
                      m$stations != m$stations_old, "changed", "same")))
  m$d_stations <- m$stations - m$stations_old
  m$d_stn <- m$stn_rows - m$stn_rows_old
  m$d_ind <- m$ind_rows - m$ind_rows_old
  touched <- m[m$status != "same", ]

  yc <- merge(now$year_counts, old$year_counts, by = c("tab", "startyear"), all = TRUE,
              suffixes = c("_new", "_old"))
  yc[is.na(yc)] <- 0
  yc$diff <- yc$n_new - yc$n_old
  tot <- aggregate(cbind(n_old, n_new, diff) ~ tab, yc, sum)
  tot <- tot[match(c("mission", "stnall", "indall", "ageall"), tot$tab), ]

  say("## What changed")
  say("")
  say(sprintf("**%s new missions, %s changed, %s removed. Net change: %s stations, %s catch rows (stnall), %s individuals (indall), %s age readings (ageall).**",
              fmt(sum(m$status == "new")), fmt(sum(m$status == "changed")),
              fmt(sum(m$status == "removed")), sprintf("%+d", sum(touched$d_stations)),
              sprintf("%+d", tot$diff[tot$tab == "stnall"]), sprintf("%+d", tot$diff[tot$tab == "indall"]),
              sprintf("%+d", tot$diff[tot$tab == "ageall"])))
  say("")
  md_table(setNames(tot, c("table", "before", "after", "change")))
  yd <- yc[yc$diff != 0 & yc$tab %in% c("stnall", "indall"), ]
  if (nrow(yd)) {
    yw <- reshape(yd[c("tab", "startyear", "diff")], idvar = "startyear", timevar = "tab", direction = "wide")
    names(yw) <- sub("^diff\\.", "change in ", names(yw))
    yw[is.na(yw)] <- 0
    say("### By year")
    say("")
    md_table(yw[order(yw$startyear), ], max_rows = 40)
  }
  if (nrow(touched)) {
    say("### Missions with the largest changes")
    say("")
    tt <- touched[order(-abs(touched$d_stn) - abs(touched$d_ind)), ]
    md_table(tt[c("status", "startyear", "missiontypename", "platformname", "cruise",
                  "cruiseseriescode", "d_stations", "d_stn", "d_ind")], max_rows = 20)
    by_type <- aggregate(cbind(d_stations, d_stn, d_ind) ~ missiontypename, touched, sum)
    say("### By mission type")
    say("")
    md_table(by_type[order(-by_type$d_stn), ])
  }
  # Missions for the checks: new or changed ones.
  scope <- touched[touched$status %in% c("new", "changed"), KEY]
} else {
  say("- **No snapshot found** (`", snapshot_file, "`), so changes cannot be counted. ",
      "The checks below run on the whole database. Take a snapshot before the next update.")
  say("")
  scope <- now$missions[KEY]
}

dbWriteTable(con, "bait_scope", scope, temporary = TRUE, overwrite = TRUE)
in_scope <- function(tab, alias = "t") {
  paste0(tab, " ", alias, " SEMI JOIN bait_scope k ON ", key_join(alias, "k"))
}

# ---- Suspicious-entry checks -------------------------------------------------

findings <- list()
check <- function(id, title, explanation, sql) {
  r <- tryCatch(q(sql), error = function(e) {
    data.frame(error = conditionMessage(e))
  })
  if (nrow(r)) findings[[id]] <<- list(title = title, explanation = explanation, rows = r)
}

if (nrow(scope)) {
  esc <- "<[89a-f][0-9a-f]>"
  moji <- "Ã[\\x{80}-\\x{BF}]|Ã¸|Ã¥|Ã¦|Ã˜|Ã…|Ã†"
  text_cols <- list(stnall = c("commonname", "platformname", "missiontypename", "stationcomment", "catchcomment"),
                    indall = c("individualcomment"),
                    mission = c("platformname", "purpose"))
  enc_sql <- function(pattern, label) {
    paste(unlist(lapply(names(text_cols), function(tab) {
      vapply(text_cols[[tab]], function(col) paste0(
        "SELECT '", tab, ".", col, "' AS column_name, count(*) AS n, any_value(", col, ") AS example,
                min(t.startyear) AS first_year, max(t.startyear) AS last_year
         FROM ", in_scope(tab), " WHERE regexp_matches(", col, ", '", pattern, "') HAVING count(*) > 0"),
        character(1))
    })), collapse = " UNION ALL ")
  }
  check("escape", "Byte-escaped text (encoding corruption)",
        "Norwegian characters stored as escape text, e.g. `bl<c3><a5>kveite`. Written by BioticExplorerServer <= 0.8.8 under a non-UTF-8 locale. Repair with `BioticExplorerServer::repairDatabaseEncoding()`; if the database was built with >= 0.8.9, report a bug (see knowledge/data-quality.md).",
        enc_sql(esc))
  check("mojibake", "Double-encoded text in the source data",
        "UTF-8 text decoded as Latin-1 and re-encoded before it reached NMD (e.g. `mÃ¥lbare` for `målbare`). The bytes are like this in the API's XML, so this is a data-entry issue for the NMD data managers, not a database bug.",
        enc_sql(moji))
  check("replacement", "Unreadable characters (U+FFFD) in the source data",
        "Characters that were lost before the data reached NMD and replaced with `�`. A source-data issue; mostly in comments.",
        enc_sql("\\x{FFFD}"))

  # Species names
  check("aphia_missing", "Catch rows with a species name but no AphiaID",
        "These rows cannot be matched to a taxon by `aphia`, so filters on AphiaID will miss them.",
        paste0("SELECT commonname, scientificname, count(*) AS n, min(t.startyear) AS first_year, max(t.startyear) AS last_year
                FROM ", in_scope("stnall"), " WHERE commonname IS NOT NULL AND aphia IS NULL GROUP BY ALL ORDER BY n DESC"))
  if (has_snapshot) {
    nn <- q(paste0("SELECT aphia, commonname, count(*) AS n FROM ", in_scope("stnall"),
                   " WHERE commonname IS NOT NULL GROUP BY ALL"))
    nn <- nn[!paste(nn$aphia, nn$commonname) %in% paste(old$names$aphia, old$names$commonname), ]
    if (nrow(nn)) {
      other <- now$names[!is.na(now$names$aphia) & now$names$aphia %in% nn$aphia & !paste(now$names$aphia, now$names$commonname) %in% paste(nn$aphia, nn$commonname), ]
      nn$other_names_for_aphia <- vapply(nn$aphia, function(a) {
        x <- other$commonname[other$aphia %in% a]
        if (length(x)) paste(utils::head(x, 3), collapse = ", ") else ""
      }, character(1))
      findings$new_names <- list(
        title = "Species names not seen before",
        explanation = "Name/AphiaID combinations that were not in the database before the update. New taxa are normal; a new name for an AphiaID that already has another name (right-hand column) is a spelling change or error that splits `commonname` filters.",
        rows = nn[order(nn$other_names_for_aphia == "", -nn$n), ])
    }
  }

  # Stations
  check("coordinates", "Stations with missing or impossible positions",
        "Missing positions drop out of maps and area filters; impossible ones (outside ±90/±180, or exactly 0,0) are typing errors.",
        paste0("SELECT CASE WHEN latitudestart IS NULL OR longitudestart IS NULL THEN 'missing'
                            WHEN latitudestart = 0 AND longitudestart = 0 THEN 'at 0,0'
                            ELSE 'outside valid range' END AS problem,
                       count(DISTINCT (t.missiontype, t.startyear, t.platform, t.missionnumber, t.serialnumber)) AS stations,
                       any_value(t.platformname) AS example_platform, any_value(t.serialnumber) AS example_serialnumber,
                       min(t.startyear) AS first_year, max(t.startyear) AS last_year
                FROM ", in_scope("stnall"), "
                WHERE latitudestart IS NULL OR longitudestart IS NULL OR abs(latitudestart) > 90
                   OR abs(longitudestart) > 180 OR (latitudestart = 0 AND longitudestart = 0)
                GROUP BY 1"))
  check("dates", "Station dates that do not fit the mission year",
        "A station date in another year than the mission (beyond a few days around new year) or in the future is usually a typing error.",
        paste0("SELECT t.startyear, t.platformname, t.serialnumber, t.stationstartdate::DATE AS stationdate
                FROM ", in_scope("stnall"), "
                WHERE (abs(year(stationstartdate) - t.startyear) >= 1
                       AND NOT (month(stationstartdate) IN (1, 12)))
                   OR stationstartdate > now()
                GROUP BY ALL ORDER BY 1"))

  # Catches
  check("catch_values", "Negative or unusually large catches",
        "Negative catches are impossible. A catch more than 5 times the species' 99.9th percentile in the whole database (species with >= 200 weighed catches) is worth checking for a unit or decimal slip. Large pelagic hauls (mackerel, herring, blue whiting) are normal and stay below this limit.",
        paste0("WITH ref AS (
                  SELECT aphia, quantile_cont(catchweight, 0.999) AS p999 FROM stnall
                  WHERE catchweight > 0 AND aphia IS NOT NULL GROUP BY aphia HAVING count(*) >= 200)
                SELECT CASE WHEN t.catchweight < 0 OR t.catchcount < 0 THEN 'negative'
                            ELSE 'over 5 x species 99.9th percentile' END AS problem,
                       t.commonname, count(*) AS n, round(any_value(r.p999)) AS species_p999_kg,
                       max(t.catchweight) AS max_kg, min(t.startyear) AS first_year, max(t.startyear) AS last_year,
                       arg_max(t.platformname, t.catchweight) AS example_platform,
                       arg_max(t.serialnumber, t.catchweight) AS example_serialnumber
                FROM ", in_scope("stnall"), " LEFT JOIN ref r ON t.aphia = r.aphia
                WHERE t.catchweight < 0 OR t.catchcount < 0 OR t.catchweight > 5 * r.p999
                GROUP BY 1, 2 ORDER BY n DESC"))
  check("checklist", "Catch rows with neither weight nor count (note)",
        "Typical of checklist-style surveys (e.g. the beach seine survey from 2016 lists every species on every haul and leaves absent species empty). Such rows are not catches: count stations, or filter on non-missing `catchweight`/`catchcount`, before treating a row as a catch.",
        paste0("SELECT t.startyear, t.missiontypename, t.platformname, t.cruise, t.cruiseseriescode,
                       count(*) AS rows, count(DISTINCT serialnumber) AS stations
                FROM ", in_scope("stnall"), "
                WHERE commonname IS NOT NULL AND catchweight IS NULL AND catchcount IS NULL
                GROUP BY ALL ORDER BY rows DESC"))

  # Individuals
  check("individual_values", "Impossible individual measurements",
        "Lengths are in metres and weights in kg. Negative values are usually missing-value codes (e.g. -99.99); weights over 1000 kg for fish under a few metres are grams entered as kg; zero lengths or weights are unmeasured values entered as 0. Grouped by species and problem; many rows of one species across many years is a systematic unit problem in the source, not single typos.",
        paste0("SELECT CASE WHEN length < 0 THEN 'negative length (missing-value code?)'
                            WHEN length = 0 THEN 'zero length'
                            WHEN length > 12 THEN 'length over 12 m'
                            WHEN individualweight < 0 THEN 'negative weight'
                            WHEN individualweight = 0 THEN 'zero weight'
                            WHEN individualweight > 1000 THEN 'weight over 1000 kg (grams as kg?)'
                            ELSE 'age outside 0-150' END AS problem,
                       t.commonname, count(*) AS n, min(t.startyear) AS first_year, max(t.startyear) AS last_year,
                       count(DISTINCT (t.missiontype, t.startyear, t.platform, t.missionnumber)) AS missions,
                       any_value(t.platformname) AS example_platform, any_value(t.serialnumber) AS example_serialnumber,
                       any_value(t.specimenid) AS example_specimenid,
                       median(t.length) AS median_length_m, median(t.individualweight) AS median_weight_kg
                FROM ", in_scope("indall"), "
                WHERE length <= 0 OR length > 12 OR individualweight <= 0 OR individualweight > 1000
                   OR age < 0 OR age > 150
                GROUP BY 1, 2 ORDER BY n DESC"))
  check("condition", "Length-weight combinations far from the species' normal (Fulton's K)",
        "Fulton's K = 100·W(g)/L(cm)³ compared with the median K of the same species in the whole database (species with >= 50 weighed individuals). A K more than 3 times above or below the species median usually means a length or weight typo, such as grams entered as kg or cm as m; the worst record per species is shown. If most new individuals of a species are flagged (`pct_of_new` high), the species is recorded with a different length convention than earlier years (e.g. carapace length for crabs), not individual typos: say so instead of listing them as errors.",
        paste0("WITH ref AS (
                  SELECT aphia, median(0.1 * individualweight / length^3) AS med_K
                  FROM indall WHERE length > 0 AND individualweight > 0 AND aphia IS NOT NULL
                  GROUP BY aphia HAVING count(*) >= 50),
                x AS (
                  SELECT t.*, 0.1 * individualweight / length^3 AS K, r.med_K
                  FROM ", in_scope("indall"), " JOIN ref r ON t.aphia = r.aphia
                  WHERE length > 0 AND individualweight > 0)
                SELECT commonname,
                       count(*) FILTER (WHERE K > 3 * med_K OR K < med_K / 3) AS n,
                       round(100.0 * count(*) FILTER (WHERE K > 3 * med_K OR K < med_K / 3) / count(*), 1) AS pct_of_new,
                       round(any_value(med_K), 2) AS species_median_K,
                       round(min(K) FILTER (WHERE K > 3 * med_K OR K < med_K / 3), 3) AS min_K,
                       round(max(K) FILTER (WHERE K > 3 * med_K OR K < med_K / 3), 2) AS max_K,
                       arg_max(platformname, abs(ln(K / med_K))) AS worst_platform,
                       arg_max(serialnumber, abs(ln(K / med_K))) AS worst_serialnumber,
                       arg_max(specimenid, abs(ln(K / med_K))) AS worst_specimenid,
                       arg_max(round(length * 100, 1), abs(ln(K / med_K))) AS worst_length_cm,
                       arg_max(round(individualweight * 1000), abs(ln(K / med_K))) AS worst_weight_g
                FROM x GROUP BY commonname
                HAVING count(*) FILTER (WHERE K > 3 * med_K OR K < med_K / 3) > 0
                ORDER BY n DESC"))

  # Duplicates
  check("dup_catch", "Duplicated catch samples",
        "The same catch sample appears more than once, which double-counts catches.",
        paste0("SELECT t.startyear, t.platformname, t.serialnumber, t.catchsampleid, count(*) AS copies
                FROM ", in_scope("stnall"), "
                WHERE catchsampleid IS NOT NULL
                GROUP BY t.missiontype, t.startyear, t.platform, t.missionnumber, t.platformname, t.serialnumber, t.catchsampleid
                HAVING count(*) > 1 ORDER BY copies DESC"))
  check("dup_individual", "Duplicated individuals",
        "The same specimen appears more than once in `indall`, which double-counts fish.",
        paste0("SELECT t.startyear, t.platformname, t.serialnumber, t.catchsampleid, t.specimenid, count(*) AS copies
                FROM ", in_scope("indall"), "
                GROUP BY t.missiontype, t.startyear, t.platform, t.missionnumber, t.platformname,
                         t.serialnumber, t.catchsampleid, t.specimenid
                HAVING count(*) > 1 ORDER BY copies DESC"))
}

if (has_snapshot) {
  gone <- m[m$status == "removed" | (m$status == "changed" & (m$d_stn < 0 | m$d_ind < 0)), ]
  if (nrow(gone)) {
    findings$removed <- list(
      title = "Data removed or reduced",
      explanation = "Missions that disappeared from the source, or lost stations or individuals in this update. Usually a correction at NMD, but large losses are worth confirming.",
      rows = gone[order(gone$d_stn + gone$d_ind), c("status", "startyear", "missiontypename",
                  "platformname", "cruise", "d_stations", "d_stn", "d_ind")])
  }
}

say("## Suspicious entries")
say("")
scope_txt <- if (has_snapshot) "in the new and changed missions" else "in the whole database"
if (!length(findings)) {
  say("None found ", scope_txt, ".")
} else {
  say(length(findings), " kind(s) of suspicious entries ", scope_txt, ":")
  say("")
  for (f in findings) say("- **", f$title, "**: ", fmt(nrow(f$rows)), " row(s) in the summary below")
  say("")
  for (f in findings) {
    say("### ", f$title)
    say("")
    say(f$explanation)
    say("")
    md_table(f$rows)
  }
}

dir.create(dirname(report_file), showWarnings = FALSE, recursive = TRUE)
writeLines(out, report_file, useBytes = FALSE)
cat(out, sep = "\n")
cat("\nReport written to", report_file, "\n")
