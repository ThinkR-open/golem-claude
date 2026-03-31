---
name: check-ns
description: Go through all the modules code and check for potential missing ns().
---

# Skill: check for missing `ns()` in modules

## Context

Each shiny module id should be namespaced using the `ns()` function which is defined at the top of the function.

This is correct:

```r
mod_analytics_ui <- function(id) {
  ns <- NS(id)
  tagList(
    selectInput(
      ns("type_filter"),
      label = NULL,
      choices = c("All", "None")
    )
  )
}
```

This is not:

```r
mod_analytics_ui <- function(id) {
  ns <- NS(id)
  tagList(
    selectInput(
      "type_filter",
      label = NULL,
      choices = c("All", "None")
    )
  )
}
```

## Step 1

Locate all the places in the codebase where there is an output id.

In a golem context, all modules files start with `mod_`, so you only have to look there.

Most of the time, the namespaced id is in the UI functions, but in some corner cases (for example when calling JavaScript handlers), the output id should also be namespaced in the server functions.

## Step 2

Go over all these identified ids, and check that they are all inside a `ns()`.

## Step 3

If you didn't find any id without `ns()`, inform the user.

If you have found any id without `ns()`, list them all to the user and ask them if they want you to update the codebase.

## Step 4

If the user said yes, edit the files, and return.
