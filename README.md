## Tools to build shiny apps with Claude & golem

For now, this is a work in progress.

## Examples

The examples in the `/examples` folder has been generated using the following prompts:

### GPS visualize

Prompt:

```
Using the good practices defined in `claude.md`, create the following golem application:

- One module that will read a GPX file that is uploaded, or take an example one in the app
- One module that will display a graph of the GPX file on a ggplot2 map

Create this app in a folder called examples/gpxviz.
```

Claude output:

```
⏺ All 19 tests pass. Here's what was created in examples/gpxviz:

  Structure:
  - R/fct_read_gpx.R — read_gpx(path): reads a GPX file via sf::st_read(), returns an sf object of track points
  - R/fct_plot_gpx.R — plot_gpx(track_data): converts track points to a linestring and plots it with ggplot2::geom_sf(), marking start (green) and end (red)
  - R/mod_gpx_upload.R — UI: radio buttons (example/upload) + conditional fileInput + "Load GPX" button; Server: on click, reads the chosen file and writes to gpx_storage$data
  - R/mod_gpx_map.R — UI: plotOutput; Server: renders plot_gpx() whenever gpx_storage$data is non-NULL
  - R/app_server.R — creates the shared gpx_storage <- reactiveValues() pre-loaded with the example track, wires up both module servers
  - R/app_ui.R — sidebarLayout with the upload module on the left, map module on the right
  - inst/extdata/example.gpx — a 20-point example track along the Seine in Paris (Eiffel Tower → Notre Dame area)
```
