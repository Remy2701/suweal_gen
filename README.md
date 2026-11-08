# Suweal Generator

[![Package Version](https://img.shields.io/hexpm/v/suweal_gen)](https://hex.pm/packages/suweal_gen)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/suweal_gen/)

An (experimental) code generation library for .surql files.

```toml
[dev_dependencies]
suweal_gen = ">= 0.5.1 and < 1.0.0"
```

# Running the generator

The generator has two commands, `gen` and `clear`. Both take an optional
`path` argument (the source directory, defaults to `./src`).

## `gen`

Finds every `.surql` file under `path` (recursively) and generates the matching
`.gleam` modules next to it.

```sh
gleam run -m suweal_gen -- gen [path] [flags]
```

| Flag           | Description                                      |
| -------------- | ------------------------------------------------ |
| `--offstage`   | Enable the offstage integration                  |
| `--service`    | Enable the suweal_service integration            |
| `--versioning` | Enable versioning (see below)                    |
| `--force`      | Force generation, ignoring any checks            |

**No integration:**
```sh
gleam run -m suweal_gen -- gen
```

**offstage integration:**
```sh
gleam run -m suweal_gen -- gen --offstage
```

### Versioning

With `--versioning`, each generation is stored as a numbered version. The
generator records a hash of every `.surql` file in `versions.json` and, when
the schema changed since the previous version, writes the field changes as a
migration in `migrations/`. Generated versions live in `versions/`.

If no `.surql` file changed since the last version, generation is skipped. Use
`--force` to generate anyway.

## `clear`

Removes everything the generator produced under `path`: the generated `.gleam`
files, `versions/`, `versions.json` and `migrations/`.

```sh
gleam run -m suweal_gen -- clear [path]
```
