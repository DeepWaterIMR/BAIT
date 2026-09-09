#!/usr/bin/env Rscript
#
# Round-trip the survey nickname registry.
#
#   Rscript scripts/cruise-series-nicknames.R export   # DB -> knowledge/cruise-series-nicknames.xlsx
#   Rscript scripts/cruise-series-nicknames.R import   # xlsx -> tables in knowledge/species-and-surveys.md
#
# The Excel file is the editable source of truth for nicknames, unofficial names and
# abbreviations; `export` refreshes the database-derived columns while keeping every
# hand-edited one, and `import` regenerates the markdown tables that agents read.
#
# Two sheets:
#   cruise_series   - surveys that ARE a cruise series (keyed by cruiseseriescode)
#   ad_hoc_surveys  - surveys that are NOT, and must be addressed by a list of cruise numbers
#
# Contains reference metadata only (cruise-series codes, survey names, platforms, years) —
# no station, catch or individual records.

suppressPackageStartupMessages({
  library(DBI); library(duckdb); library(dplyr); library(openxlsx)
})

`%||%`   <- function(x, y) if (is.null(x)) y else x
repo     <- normalizePath(".", mustWork = TRUE)   # run from the repo root
xlsxPath <- file.path(repo, "knowledge", "cruise-series-nicknames.xlsx")
mdPath   <- file.path(repo, "knowledge", "species-and-surveys.md")

# Columns the user owns. Export never overwrites them; import reads them.
editCols  <- c("nickname", "unofficial_names", "abbreviations", "norwegian_name", "notes")
adhocCols <- c("survey", "nickname", "abbreviations", "norwegian_name", "cruises", "notes")

blank    <- function(x) is.na(x) | !nzchar(trimws(x))
mdEscape <- function(x) gsub("|", "\\|", x, fixed = TRUE)
# Rscript runs in the C locale, so mark strings UTF-8 explicitly and write bytes verbatim —
# otherwise ø/å come out as <U+00F8> escapes.
utf8     <- function(x) { x <- as.character(x); Encoding(x) <- "UTF-8"; trimws(x) }

dbPath <- function() {
  if (.Platform$OS.type == "windows")
    file.path(Sys.getenv("USERPROFILE"), "IMR_biotic_BES_database", "bioticexplorer.duckdb")
  else path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb")
}

# ---- markdown blocks --------------------------------------------------------

# Parse a generated table back out of species-and-surveys.md, so a fresh clone (where the
# gitignored spreadsheet is missing) still recovers every name the team has recorded.
readMdBlock <- function(tag, cols) {
  if (!file.exists(mdPath)) return(NULL)
  md <- readLines(mdPath, warn = FALSE, encoding = "UTF-8")
  b <- grep(paste0("^<!-- BEGIN ", tag, " -->$"), md)
  e <- grep(paste0("^<!-- END ", tag, " -->$"), md)
  if (length(b) != 1 || length(e) != 1 || e <= b) return(NULL)

  body <- md[(b + 1):(e - 1)]
  body <- body[grepl("^\\|", body) & !grepl("^\\|[-\\s|]+\\|$", body)]
  body <- body[-1]                                    # drop the header row
  if (!length(body)) return(NULL)

  # Split on unescaped pipes only (a note may contain a literal \| ), then unescape.
  cells <- lapply(strsplit(sub("\\|\\s*$", "", sub("^\\|", "", body)), "(?<!\\\\)\\|", perl = TRUE),
                  function(x) trimws(gsub("\\|", "|", x, fixed = TRUE)))
  cells <- cells[lengths(cells) == length(cols)]
  if (!length(cells)) return(NULL)

  m <- do.call(rbind, cells)
  out <- as.data.frame(m, stringsAsFactors = FALSE)
  names(out) <- cols
  out
}

writeMdBlock <- function(tag, lines) {
  md <- readLines(mdPath, warn = FALSE)
  b <- grep(paste0("^<!-- BEGIN ", tag, " -->$"), md)
  e <- grep(paste0("^<!-- END ", tag, " -->$"), md)
  if (length(b) != 1 || length(e) != 1 || e <= b)
    stop("Marker comments for '", tag, "' not found (or malformed) in ", mdPath)
  writeLines(c(md[1:b], lines, md[e:length(md)]), mdPath, useBytes = TRUE)
}

# ---- export -----------------------------------------------------------------

exportXlsx <- function() {
  con <- dbConnect(duckdb::duckdb(), dbdir = dbPath(), read_only = TRUE)
  on.exit(dbDisconnect(con, shutdown = TRUE))

  # --- sheet 1: real cruise series, one row each ------------------------------
  official <- tbl(con, "csindex") |>
    group_by(cruiseseriescode, name) |>
    summarise(n_cruises  = n_distinct(cruise),
              first_year = min(startyear, na.rm = TRUE),
              last_year  = max(startyear, na.rm = TRUE),
              .groups    = "drop") |>
    collect() |>
    mutate(code = suppressWarnings(as.integer(cruiseseriescode))) |>
    arrange(is.na(code), code) |>
    select(code, official_name = name, n_cruises, first_year, last_year)

  # Keep whatever the user has already filled in. The spreadsheet is gitignored, so on a
  # fresh clone fall back to the committed markdown table — the routine must survive that.
  prev <- if (file.exists(xlsxPath)) {
    readWorkbook(xlsxPath, sheet = "cruise_series") |>
      mutate(code = suppressWarnings(as.integer(code)))
  } else {
    p <- readMdBlock("cruise-series-nicknames",
                     c("code", "nickname", "abbreviations", "unofficial_names",
                       "norwegian_name", "notes"))
    if (!is.null(p)) p$code <- suppressWarnings(as.integer(p$code))
    p
  }

  if (!is.null(prev) && nrow(prev)) {
    keep <- intersect(editCols, names(prev))
    official <- left_join(official, prev[, c("code", keep)], by = "code")
  }
  for (cl in setdiff(editCols, names(official))) official[[cl]] <- NA_character_

  out <- official |>
    select(code, official_name, nickname, unofficial_names, abbreviations,
           norwegian_name, notes, n_cruises, first_year, last_year)

  # --- sheet 2: surveys with no cruise-series code ----------------------------
  adhoc <- if (file.exists(xlsxPath) && "ad_hoc_surveys" %in% getSheetNames(xlsxPath)) {
    readWorkbook(xlsxPath, sheet = "ad_hoc_surveys")
  } else {
    p <- readMdBlock("adhoc-surveys", c("survey", "abbreviations", "norwegian_name",
                                        "cruises", "notes"))
    if (!is.null(p)) {
      # The markdown renders cruises as `c("a", "b")`; turn that back into "a; b".
      p$cruises <- vapply(p$cruises, function(x) {
        x <- gsub('^`?c\\(|\\)`?$', "", trimws(x))
        paste(gsub('^"|"$', "", trimws(strsplit(x, ",", fixed = TRUE)[[1]])), collapse = "; ")
      }, character(1), USE.NAMES = FALSE)
    }
    p
  }
  if (is.null(adhoc) || !nrow(adhoc)) {
    adhoc <- tibble(survey = character(), nickname = character(),
                    abbreviations = character(), norwegian_name = character(),
                    cruises = character(), notes = character())
  }
  for (cl in setdiff(adhocCols, names(adhoc))) adhoc[[cl]] <- NA_character_
  adhoc <- adhoc[, adhocCols]

  # Validate the cruise lists against the database so a typo shows up in the sheet rather
  # than silently returning nothing months later.
  chk <- vapply(adhoc$cruises, function(cs) {
    if (blank(cs)) return(NA_character_)
    want <- trimws(strsplit(cs, ";", fixed = TRUE)[[1]])
    want <- want[nzchar(want)]
    got  <- tbl(con, "mission") |> filter(cruise %in% want) |> distinct(cruise) |> collect()
    miss <- setdiff(want, got$cruise)
    if (length(miss)) paste0(nrow(got), "/", length(want), " found; MISSING: ",
                             paste(miss, collapse = ", "))
    else paste0(nrow(got), "/", length(want), " found")
  }, character(1), USE.NAMES = FALSE)
  adhoc$in_database <- chk

  # --- write ------------------------------------------------------------------
  hdr <- createStyle(textDecoration = "bold")
  wrap <- createStyle(wrapText = TRUE, valign = "top")
  grey <- createStyle(fgFill = "#EFEFEF", valign = "top", wrapText = TRUE)

  wb <- createWorkbook()
  addWorksheet(wb, "cruise_series")
  writeData(wb, "cruise_series", out, headerStyle = hdr)
  freezePane(wb, "cruise_series", firstActiveRow = 2, firstActiveCol = 3)
  setColWidths(wb, "cruise_series", cols = 1:10,
               widths = c(6, 70, 22, 34, 22, 28, 46, 10, 10, 10))
  addStyle(wb, "cruise_series", wrap, rows = 2:(nrow(out) + 1), cols = 1:10, gridExpand = TRUE)
  # Read-only columns get a grey background so it is obvious what not to edit.
  addStyle(wb, "cruise_series", grey, rows = 2:(nrow(out) + 1), cols = c(1, 2, 8, 9, 10),
           gridExpand = TRUE, stack = TRUE)

  addWorksheet(wb, "ad_hoc_surveys")
  writeData(wb, "ad_hoc_surveys", adhoc, headerStyle = hdr)
  setColWidths(wb, "ad_hoc_surveys", cols = 1:7, widths = c(26, 26, 20, 26, 60, 60, 34))
  if (nrow(adhoc)) {
    addStyle(wb, "ad_hoc_surveys", wrap, rows = 2:(nrow(adhoc) + 1), cols = 1:7,
             gridExpand = TRUE)
    addStyle(wb, "ad_hoc_surveys", grey, rows = 2:(nrow(adhoc) + 1), cols = 7,
             gridExpand = TRUE, stack = TRUE)
  }

  addWorksheet(wb, "how_to")
  writeData(wb, "how_to", data.frame(instructions = c(
    "SHEET cruise_series - surveys that are a registered cruise series.",
    "Edit the white columns only. Grey columns (code, official_name, n_cruises, first_year, last_year) come from the database and are overwritten on the next export.",
    "All name columns take a semicolon-separated list; put the most-used form first.",
    "nickname:         spoken/written English names, e.g. EggaNord; EggaN.",
    "unofficial_names: anything that does not fit the other columns (old names, informal forms).",
    "abbreviations:    short forms, e.g. EggaN; EN.",
    "norwegian_name:   Norwegian name(s), e.g. Eggakanttokt nord; Egga-nord.",
    "notes:            anything an agent should know (ambiguity, season, area, confidence).",
    "Leave a row blank if the series has no nickname worth recording - blank rows are skipped.",
    "",
    "SHEET ad_hoc_surveys - surveys that are NOT a cruise series and must be addressed by cruise number.",
    "survey:      the survey's main name, e.g. Spurdog Survey.",
    "cruises:     semicolon-separated cruise numbers, e.g. 2021011; 2022849.",
    "in_database: grey, filled in by export - checks each cruise number against the mission table. Fix any MISSING before importing.",
    "Add a row whenever a survey has no cruiseseriescode. Re-export after adding cruises for a new year.",
    "",
    "Save the file, hand it back to Claude, and ask it to run the import step."
  )), headerStyle = hdr)
  setColWidths(wb, "how_to", cols = 1, widths = 130)

  saveWorkbook(wb, xlsxPath, overwrite = TRUE)
  message("Wrote ", xlsxPath, " (", nrow(out), " cruise series, ", nrow(adhoc),
          " ad-hoc surveys)")
}

# ---- import -----------------------------------------------------------------

# Some short forms are used for more than one survey (IBTS covers three North Sea series).
# Detect those and print them, so an agent asks instead of picking the first match.
collisionBlock <- function(d) {
  nameCols <- c("nickname", "unofficial_names", "abbreviations")
  long <- do.call(rbind, lapply(nameCols, function(cl) {
    v <- d[[cl]]
    do.call(rbind, lapply(seq_along(v), function(i) {
      if (blank(v[i])) return(NULL)
      toks <- trimws(strsplit(v[i], ";", fixed = TRUE)[[1]])
      toks <- toks[nzchar(toks)]
      if (!length(toks)) return(NULL)
      data.frame(code = d$code[i], token = toks, stringsAsFactors = FALSE)
    }))
  }))
  if (is.null(long) || !nrow(long)) return(character())

  long$key <- tolower(long$token)
  long     <- long[!duplicated(long[, c("key", "code")]), ]
  dup      <- names(which(table(long$key) > 1))
  if (!length(dup)) return(character())

  lines <- vapply(sort(dup), function(k) {
    sub  <- long[long$key == k, ]
    disp <- sub$token[which.max(nchar(sub$token))]
    sprintf("> - **%s** → codes %s", mdEscape(disp),
            paste(sort(unique(sub$code)), collapse = ", "))
  }, character(1))

  c("> ⚠️ **Ambiguous short forms** — these map to more than one cruise series. Ask the user",
    "> which one they mean; never pick the first match.", ">", lines, "")
}

importSeries <- function() {
  d <- readWorkbook(xlsxPath, sheet = "cruise_series") |>
    mutate(across(any_of(editCols), utf8), code = suppressWarnings(as.integer(code)))

  # Only series the user has actually named make it into the markdown table.
  d <- d |>
    filter(!(blank(nickname) & blank(unofficial_names) & blank(abbreviations))) |>
    arrange(code)
  if (!nrow(d)) stop("No named cruise series in ", basename(xlsxPath), " - nothing to import.")

  cell <- function(x) ifelse(blank(x), "", mdEscape(x))
  rows <- sprintf("| %s | %s | %s | %s | %s | %s |",
                  ifelse(is.na(d$code), "", d$code),
                  cell(d$nickname), cell(d$abbreviations), cell(d$unofficial_names),
                  cell(d$norwegian_name), cell(d$notes))

  writeMdBlock("cruise-series-nicknames", c(
    "| Code | Nickname | Abbreviations | Other names in use | Norwegian | Notes |",
    "|---|---|---|---|---|---|",
    rows, "",
    collisionBlock(d),
    sprintf("> Generated from [`cruise-series-nicknames.xlsx`](cruise-series-nicknames.xlsx) on %s by",
            format(Sys.Date())),
    "> `Rscript scripts/cruise-series-nicknames.R import`. **Edit the spreadsheet, not this table.**",
    "> `Code` is `cruiseseriescode` and is authoritative — filter on it rather than grepping",
    "> `csindex$name`. The spreadsheet also lists every series that has no nickname yet."
  ))
  nrow(d)
}

importAdhoc <- function() {
  if (!"ad_hoc_surveys" %in% getSheetNames(xlsxPath)) return(0L)
  a <- readWorkbook(xlsxPath, sheet = "ad_hoc_surveys") |>
    mutate(across(any_of(adhocCols), utf8))
  a <- a[!blank(a$survey) & !blank(a$cruises), , drop = FALSE]
  if (!nrow(a)) return(0L)

  cell  <- function(x) ifelse(blank(x), "", mdEscape(x))
  # Render the cruise numbers as an R vector, ready to paste into a filter.
  asVec <- function(cs) {
    v <- trimws(strsplit(cs, ";", fixed = TRUE)[[1]])
    paste0('c("', paste(v[nzchar(v)], collapse = '", "'), '")')
  }
  # Nickname and abbreviations share one markdown column.
  alt <- mapply(function(nk, ab) {
    parts <- c(if (!blank(nk)) nk, if (!blank(ab)) ab)
    if (!length(parts)) "" else mdEscape(paste(parts, collapse = "; "))
  }, a$nickname, a$abbreviations, USE.NAMES = FALSE)
  rows <- sprintf("| %s | %s | %s | `%s` | %s |",
                  cell(a$survey), alt, cell(a$norwegian_name),
                  vapply(a$cruises, asVec, character(1), USE.NAMES = FALSE),
                  cell(a$notes))

  writeMdBlock("adhoc-surveys", c(
    "| Survey | Other names | Norwegian | Cruise numbers | Notes |",
    "|---|---|---|---|---|",
    rows, "",
    "> These have **no `cruiseseriescode`** — `csindex` does not know them, and filtering by",
    "> cruise series will silently return nothing. Address them by cruise number instead:",
    "> `filter(cruise %in% c(...))` on `mission` / `stnall` / `indall`.",
    ">",
    "> The lists are **not self-updating** — a new survey year adds a cruise number that",
    "> nobody has recorded here. Check the latest year before reporting a time series as",
    "> complete, and ask the user to add missing cruises via the export/import routine."
  ))
  nrow(a)
}

importXlsx <- function() {
  stopifnot(file.exists(xlsxPath))
  ns <- importSeries()
  na <- importAdhoc()
  message("Updated ", mdPath, " (", ns, " named cruise series, ", na, " ad-hoc surveys)")
}

# ---- dispatch ---------------------------------------------------------------

act <- commandArgs(trailingOnly = TRUE)[1]
switch(act %||% "",
       export = exportXlsx(),
       import = importXlsx(),
       stop("Usage: Rscript scripts/cruise-series-nicknames.R [export|import]"))
