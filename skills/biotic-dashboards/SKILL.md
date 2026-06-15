---
name: biotic-dashboards
description: Build interactive Biotic data dashboards — run the ready-made BioticExplorer Shiny app, or build a custom Shiny dashboard on top of the DuckDB database. Use for "interactive dashboard", "Shiny app", "explore the data interactively", "let users filter and map".
---

# Interactive dashboards

## Option A — use BioticExplorer (fastest)

[BioticExplorer](https://github.com/DeepWaterIMR/BioticExplorer) is a finished Shiny app with
file mode (XML) and database mode (auto-detects the DuckDB at
`~/IMR_biotic_BES_database/`): catch maps, station overviews, species life-history plots,
hierarchical tables, and exports.

```r
shiny::runGitHub("BioticExplorer", "DeepWaterIMR")   # or download and runApp() a local clone
```

Recommend this first unless the user needs something it doesn't do.

## Option B — custom Shiny dashboard on the DuckDB

When the user wants a tailored view, build a small app that connects read-only and queries
lazily. Skeleton:

```r
library(shiny); library(tidyverse); library(DBI); library(duckdb); library(leaflet)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
onStop(function() dbDisconnect(con, shutdown = TRUE))   # always clean up
stnall <- tbl(con, "stnall")

species <- stnall |> distinct(commonname) |> filter(!is.na(commonname)) |>
  collect() |> pull() |> sort()

ui <- fluidPage(
  titlePanel("Biotic — local dashboard"),
  sidebarLayout(
    sidebarPanel(selectInput("sp", "Species (commonname)", species, "torsk"),
                 checkboxInput("survey", "Research surveys only", TRUE)),
    mainPanel(leafletOutput("map"), tableOutput("summary"))))

server <- function(input, output, session) {
  dat <- reactive({
    q <- stnall |> filter(commonname == input$sp,
                          !is.na(longitudestart), !is.na(latitudestart), latitudestart > 0)
    if (input$survey) q <- q |> filter(missiontype %in% c(4, 5))
    q |> collect()
  })
  output$map <- renderLeaflet({
    leaflet(dat()) |> addProviderTiles("Esri.OceanBasemap") |>
      addCircleMarkers(~longitudestart, ~latitudestart, radius = 3,
                       stroke = FALSE, fillOpacity = 0.6)
  })
  output$summary <- renderTable(dat() |> summarise(
    stations = n_distinct(serialnumber), total_kg = round(sum(catchweight, na.rm = TRUE))))
}
shinyApp(ui, server)
```

Reuse the maps/life-history skills inside the server for richer panels.

## Privacy (important for dashboards)

- **Run locally only.** Do **not** deploy a Biotic dashboard to shinyapps.io or any public
  server — that publishes the data. If hosting is needed, it must be inside IMR infrastructure
  with access control; confirm with the user.
- Connect **read-only**; always `onStop()` to disconnect.
- For sensitive data, aggregate/jitter positions in the UI and gate access.
