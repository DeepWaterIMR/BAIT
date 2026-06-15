#!/usr/bin/env Rscript
# distill_xsd.R — generate knowledge/field-glossary.md from the NMD Biotic v3 XSD.
#
# The XSD is a PUBLIC schema (not data), so downloading it is fine under BAIT's privacy
# rules. This script extracts, for every field, the bilingual (EN/NO) documentation and
# flags which flattened table (stnall/indall) the field lands in.
#
# Usage:
#   Rscript scripts/distill_xsd.R [path-or-url-to-xsd] [output.md]
# Defaults: official IMR URL -> knowledge/field-glossary.md
#
# Do NOT edit knowledge/field-glossary.md by hand — edit this script and regenerate.

suppressWarnings(suppressMessages({
  if (!requireNamespace("xml2", quietly = TRUE)) stop("Please install.packages('xml2').")
  library(xml2)
}))

args    <- commandArgs(trailingOnly = TRUE)
xsd_src <- if (length(args) >= 1) args[[1]] else
  "https://www.imr.no/formats/nmdbiotic/v3/nmdbioticv3.xsd"
out_md  <- if (length(args) >= 2) args[[2]] else
  file.path(dirname(dirname(normalizePath(sub("--file=", "",
    grep("--file=", commandArgs(FALSE), value = TRUE)[1]), mustWork = FALSE))),
    "knowledge", "field-glossary.md")
if (is.na(out_md) || !nzchar(out_md)) out_md <- "knowledge/field-glossary.md"

message("Reading XSD: ", xsd_src)
doc <- xml2::read_xml(xsd_src)
ns  <- c(xs   = "http://www.w3.org/2001/XMLSchema",
         imrd = "http://www.imr.no/formats/nmddocumentation/v1_0")

# --- Core columns kept in the flattened tables (mirrors RstoxUtils::coreDataList) -------
core <- list(
  mission         = c("missiontype","startyear","platform","missionnumber","missiontypename",
                      "callsignal","platformname","cruise","missionstartdate","missionstopdate","purpose"),
  fishstation     = c("missiontype","startyear","platform","missionnumber","serialnumber","station",
                      "stationstartdate","stationstarttime","longitudestart","latitudestart",
                      "bottomdepthstart","fishingdepthmin","gear","distance"),
  catchsample     = c("missiontype","startyear","platform","missionnumber","serialnumber","catchsampleid",
                      "commonname","catchcategory","catchpartnumber","catchweight","catchcount",
                      "lengthsampleweight","lengthsamplecount"),
  individual      = c("missiontype","startyear","platform","missionnumber","serialnumber","catchsampleid",
                      "specimenid","sex","maturationstage","specialstage","length","individualweight"),
  agedetermination= c("missiontype","startyear","platform","missionnumber","serialnumber","catchsampleid",
                      "specimenid","age","readability")
)
# Which merged table each element group flows into.
in_stnall <- c("mission","fishstation","catchsample")
in_indall <- c("mission","fishstation","catchsample","individual","agedetermination")

# Friendly order for the backbone of the model.
backbone <- c("mission","fishstation","catchsample","individual","agedetermination","prey","tag")

code_types <- c("KeyType","CompositeTaxaKeyType","CompositeTaxaSexKeyType")

# All complexType names -> used to tell container elements from scalar fields.
ct_nodes <- xml2::xml_find_all(doc, "//xs:complexType[@name]", ns)
ct_names <- xml2::xml_attr(ct_nodes, "name")

squish <- function(x) {
  x <- gsub("[\r\n\t]+", " ", x); x <- gsub(" +", " ", x); trimws(x)
}
get_desc <- function(node, lang) {
  d <- xml2::xml_find_first(node,
    sprintf(".//imrd:description[@lang='%s']", lang), ns)
  if (inherits(d, "xml_missing")) "" else squish(xml2::xml_text(d))
}
get_label <- function(node, lang) {
  d <- xml2::xml_find_first(node,
    sprintf(".//imrd:name[@lang='%s']", lang), ns)
  if (inherits(d, "xml_missing")) "" else squish(xml2::xml_text(d))
}

# --- Extract fields per complexType -----------------------------------------------------
extract_group <- function(ct_node) {
  fields <- xml2::xml_find_all(ct_node, ".//xs:element[@name] | .//xs:attribute[@name]", ns)
  rows <- lapply(fields, function(f) {
    nm  <- xml2::xml_attr(f, "name")
    ty  <- xml2::xml_attr(f, "type")
    ty  <- ifelse(is.na(ty), "", ty)
    # Skip container elements (their type is itself a complexType = hierarchy, not a field).
    if (ty %in% ct_names) return(NULL)
    data.frame(
      column   = nm,
      label_en = get_label(f, "en"),
      type     = sub("^xs:", "", ty),
      is_code  = ty %in% code_types,
      desc_en  = get_desc(f, "en"),
      desc_no  = get_desc(f, "no"),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

groups <- list()
for (i in seq_along(ct_nodes)) {
  ctname <- ct_names[i]
  grp <- tolower(sub("Type$", "", ctname))   # MissionType -> mission
  df  <- extract_group(ct_nodes[[i]])
  if (is.null(df) || !nrow(df)) next
  df  <- df[!duplicated(df$column), , drop = FALSE]
  groups[[grp]] <- df
}

# --- Render markdown --------------------------------------------------------------------
# Build all lines first, then write once with useBytes to avoid locale conversion issues.
esc <- function(x) gsub("\\|", "\\\\|", x)
fmt_in <- function(grp, col) {
  s <- (grp %in% in_stnall) && (is.null(core[[grp]]) || col %in% core[[grp]])
  i <- (grp %in% in_indall) && (is.null(core[[grp]]) || col %in% core[[grp]])
  if (s && i) "stnall, indall" else if (i) "indall" else if (s) "stnall" else "-"
}

L <- character(0)
add <- function(...) L[[length(L) + 1L]] <<- paste0(...)

add("<!-- GENERATED FILE - do not edit by hand. Regenerate with scripts/distill_xsd.R -->")
add("# Field glossary (NMD Biotic v3)")
add("")
add("Generated ", as.character(Sys.Date()), " from `", xsd_src, "`.")
add("")
add("Maps plain-English concepts to the **column names** used in the flattened tables. The")
add("**in** column shows where a field appears after flattening (see `data-model.md`).")
add("**code?** = the field is a foreign key into NMDreference (a code, not a literal value).")
add("")
add("> Units: `length` is in **metres**, `individualweight` and `catchweight` in **kg**.")
add("> `commonname` is **Norwegian**. Always confirm a column exists with `colnames()`.")
add("")

emit_group <- function(grp) {
  df <- groups[[grp]]
  if (is.null(df)) return(invisible())
  add(""); add("## `", grp, "`"); add("")
  add("| column | label (EN) | type | code? | in | description (EN) |")
  add("|---|---|---|---|---|---|")
  for (k in seq_len(nrow(df))) {
    r <- df[k, ]
    d <- r$desc_en; if (nchar(d) > 300) d <- paste0(substr(d, 1, 297), "...")
    add("| `", r$column, "` | ", esc(r$label_en), " | ", r$type, " | ",
        ifelse(r$is_code, "yes", ""), " | ", fmt_in(grp, r$column), " | ", esc(d), " |")
  }
}

add("## Backbone elements (used in almost every query)")
for (g in backbone) if (!is.null(groups[[g]])) emit_group(g)

others <- sort(setdiff(names(groups), backbone))
if (length(others)) {
  add(""); add("## Other elements")
  add(""); add("<details><summary>Expand the full list of remaining elements</summary>"); add("")
  for (g in others) emit_group(g)
  add(""); add("</details>")
}

con <- file(out_md, open = "wb")
writeLines(enc2utf8(unlist(L)), con, useBytes = TRUE)
close(con)
n_fields <- sum(vapply(groups, nrow, integer(1)))
message("Wrote ", out_md, " - ", length(groups), " elements, ", n_fields, " fields.")
