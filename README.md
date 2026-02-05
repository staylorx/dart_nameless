Named Params — CLI scanner and custom lint for positional parameters

This package provides a CLI scanner that
scans Dart source and report function, method, and constructor signatures that
use positional parameters where named parameters may be preferable. It is
reporting-only (no automatic fixes) and designed to be reusable as a library,
run as a CLI tool, or integrated as a lint rule in analysis_options.yaml.

Defaults and behavior

- Default `positionalThresholdPublic`: 1 — signatures with more than this many
  positional parameters are reported.
- Default `positionalThresholdPrivate`: 999 — signatures with more than this many
  positional parameters are reported.
- Default `allowedPositionalNames`: `ref`, `message` — a single
  positional parameter with these names is allowed and will not be reported.
- Exclude: `.nameless.yaml` (if present) and `.gitignore` entries are
  respected; additional exclude globs can be provided via CLI or config.

Quick start

Install dependencies and run the scanner on the current directory:

```powershell
dart pub get
dart run bin/nameless.dart .
```

CLI usage

```powershell
nameless [options] [path]

Options:
- `-c, --config`   Path to config YAML file (default: .nameless.yaml if present)
- `-f, --format`   Output format: `text` (default) or `json`
- `-o, --output`   Output to file instead of stdout
- `-v, --verbose`  Verbose output
- `-h, --help`     Show help

Config subcommand:
nameless config [options]

Options:
- `-c, --config`       Path to config YAML file to load and modify
- `-t, --threshold`    Set positional threshold (int)
- `-a, --allowed-names` Allowed single positional names, comma-separated
- `-e, --exclude-globs` Exclude globs, comma-separated
- `-f, --format`       Output format: `text` (default) or `json`
- `-o, --output`       Output to file instead of stdout
- `-h, --help`         Show help
```

Example using a config file

Create `example/config.example.yaml` (already included) or `.nameless.yaml` at
the repo root:

```yaml
positionalThresholdPublic: 1
allowedPositionalNames:
	- ref
	- message
excludeGlobs:
	- build/
	- .dart_tool/
```

Then run:

```powershell
dart run bin/nameless.dart --config=.nameless.yaml .
```

Custom Lint Integration

The package also provides a custom_lint plugin for integration with `dart analyze`.
Add to your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - nameless_analysis_plugin:require_nameless
  nameless_analysis_plugin:
    require_nameless:
      positional_public_threshold: 1
      positional_private_threshold: 1
      exempted_single_methods:
        - "ref"
        - "message"
```

Then run `dart analyze` to see lint warnings in your IDE and CI.

Testing

Run unit tests with:

```powershell
dart test
```

Library API

The core scanner is implemented in `lib/` and exposes:

- `Config` — configuration model
- `scanDirectory(String rootPath, Config config)` — returns findings
- `createPlugin()` — custom_lint plugin entrypoint

Next steps

- Add more thorough `.gitignore`/glob matching and richer JSON output via an
  MCP/dart integration if desired.
