# Golem Shiny App Builder Plugin

Build professional Shiny applications with Claude Code using the golem framework.

## What This Plugin Provides

A set of skills and guidelines for creating production-ready Shiny applications following R package best practices and golem conventions.

### Skills

- **Create Golem App** - Initialize a new golem Shiny application
- **Add Module** - Create reusable Shiny modules with UI and server logic
- **Add Function** - Add business logic functions or utilities
- **Check App** - Validate package structure and dependencies
- **Run Tests** - Execute your test suite
- **Check for Missing ns()** - Validate module namespace wrapping

All documentation and guidelines are in the main project README.

## Quick Start

1. Use the `/plugin` command in Claude Code to install this plugin
2. Create a new app:
   ```
   I want to create a golem Shiny application
   ```
3. Add modules and functions as needed
4. Run `Rscript -e "golem::run_dev()"` to preview your app

## Key Features

- ✅ Enforces R package best practices
- ✅ Golem naming conventions and patterns
- ✅ Reactive programming guidelines
- ✅ Module and function templates
- ✅ Test-driven development support
- ✅ Complete documentation and examples

## Development Workflow

```
Create App → Add Modules → Add Functions → Test → Check → Deploy
```

## Requirements

- R 4.0+
- golem package
- devtools package
- Shiny package

## Example Applications

This plugin is designed to generate apps like:

- **comparegpx** - GPS file comparison and visualization
- **videotager** - Video tagging and search system
- And more!

See `/generated` for complete working examples.

## More Information

See the main README in the parent directory for complete documentation.

---

Built by [ThinkR](https://thinkr.fr) for professional Shiny development with Claude Code.
