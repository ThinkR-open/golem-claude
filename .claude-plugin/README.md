# Claude Code Plugin: Golem Shiny App Builder

This directory contains the Claude Code plugin configuration for building Shiny applications with the golem framework.

## Installation

### Option 1: Via Claude Code Plugin Command (Recommended)

In Claude Code, use the `/plugin` command:

```
/plugin install https://github.com/thinkr-open/golem-claude/plugins/golem-plugin
```

### Option 2: Direct Installation

1. Copy the `plugins/` directory to your Claude Code configuration
2. Or reference this repository in your Claude Code plugin marketplace

## Plugin Structure

```
.claude-plugin/
├── marketplace.json          # Plugin registry configuration
└── README.md                 # This file

../plugins/golem-plugin/
├── plugin.json              # Plugin manifest
├── README.md                # Plugin description
└── skills/                  # Claude Code skills
    ├── create-golem.md
    ├── add-module.md
    ├── add-function.md
    ├── check-app.md
    ├── run-tests.md
    └── check-ns.md
```

## Available Skills

Once installed, you can use these skills in Claude Code:

1. **Create Golem App** - `create-golem`
   - Initialize a new golem Shiny application

2. **Add Module** - `add-module`
   - Create reusable Shiny modules

3. **Add Function** - `add-function`
   - Add business logic or utility functions

4. **Check App** - `check-app`
   - Validate your golem application

5. **Run Tests** - `run-tests`
   - Execute your test suite

6. **Check for Missing ns()** - `check-ns`
   - Validate module namespace wrapping

## Quick Start

After installation, ask Claude Code:

```
Create a golem Shiny app for managing project tasks
```

Claude will:
1. Create the app structure with proper conventions
2. Generate modules for different features
3. Add functions for business logic
4. Set up tests and documentation
5. Provide guidance for development

## Configuration

The plugin is configured in:
- `marketplace.json` - Plugin registry and metadata
- `plugins/golem-plugin/plugin.json` - Plugin manifest with skill definitions

To customize:
1. Edit `plugin.json` to add/remove skills
2. Create new skill files in the `skills/` directory
3. Update main README.md with new documentation

## Development

To contribute to this plugin:

1. Fork the repository
2. Create a feature branch
3. Update skills or resources
4. Test with Claude Code
5. Submit a pull request

### Testing Skills

1. Use Claude Code locally
2. Ask Claude to use the skill
3. Verify output matches guidelines in `CLAUDE.md`

## Troubleshooting

**Plugin not showing up?**
- Ensure `marketplace.json` is valid JSON
- Check that `plugins/` directory exists
- Verify Claude Code recognizes your installation

**Skills not working?**
- Check the skill `.md` files are in `skills/` directory
- Verify skill IDs in `plugin.json` match file names
- Review CLAUDE.md for project rules

**Can't create app?**
- Ensure you have R and golem installed: `install.packages("golem")`
- Check that you're in an appropriate directory
- Verify file permissions

## Support

For issues or questions:
- Check [Golem documentation](https://thinkr-open.github.io/golem/)
- Review examples in `/generated` folder
- See main README.md for guidelines and documentation

## Version

- Plugin Version: 1.0.0
- Golem Framework: 0.3+
- R Version: 4.0+

## License

This plugin and all examples are provided by ThinkR.

See LICENSE file for details.

---

**Built for professional Shiny development with Claude Code** 🚀
