import argv
import clip
import clip/arg
import clip/flag
import common
import extractor
import generator
import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import lexer
import migration
import omcg/module
import parser
import shellout
import simplifile

const suweal_version = "0.4.3-local"

type Command {
  GenCommand(config: common.Configuration)
  ClearCommand(path: String)
}

/// Define the command-line interface for the tool.
fn command() {
  clip.subcommands([
    #(
      "gen",
      clip.command({
        use offstage <- clip.parameter
        use service <- clip.parameter
        use versioning <- clip.parameter
        use force <- clip.parameter
        use path <- clip.parameter

        GenCommand(common.Configuration(
          offstage:,
          service:,
          versioning:,
          force:,
          path:,
        ))
      })
        |> clip.flag(
          flag.new("offstage")
          |> flag.help("Enable offstage integration"),
        )
        |> clip.flag(
          flag.new("service")
          |> flag.help("Enable suweal_service integration"),
        )
        |> clip.flag(
          flag.new("versioning")
          |> flag.help("Enable versioning"),
        )
        |> clip.flag(
          flag.new("force")
          |> flag.help("Force generation, ignoring any checks"),
        )
        |> clip.arg(
          arg.new("path")
          |> arg.default("./src")
          |> arg.help("Path to the source directory"),
        ),
    ),
    #(
      "clear",
      clip.command({
        use path <- clip.parameter

        ClearCommand(path:)
      })
        |> clip.arg(
          arg.new("path")
          |> arg.default("./src")
          |> arg.help("Path to the source directory"),
        ),
    ),
  ])
}

pub type Error {
  FailedToTokenize(error: lexer.LexerError, file: File)
  FailedToParse(error: parser.ParserError, file: File)
  FailedToExtractTables(error: String, file: File)
  FailedToGenerate(error: String, file: File)
}

pub fn render_error(error: Error) -> String {
  case error {
    FailedToTokenize(error:, file:) -> lexer.render_error(error, file.content)
    FailedToParse(error:, file:) -> parser.render_error(error, file.content)
    FailedToExtractTables(error:, file:) ->
      "Failed to extract tables in " <> file.path <> ": " <> error
    FailedToGenerate(error:, file:) ->
      "Failed to generate file " <> file.path <> ": " <> error
  }
}

pub type File {
  File(path: String, content: String)
}

pub fn generate_file(
  config: common.Configuration,
  content: String,
  path: String,
) {
  use tokens <- result.try(
    lexer.tokenize(path, content)
    |> result.map_error(FailedToTokenize(_, File(path: path, content: content))),
  )

  use ast <- result.try(
    parser.parse(tokens)
    |> result.map_error(FailedToParse(_, File(path: path, content: content))),
  )

  use tables <- result.try(
    extractor.extract_tables(content, ast)
    |> result.map_error(FailedToExtractTables(
      _,
      File(path: path, content: content),
    )),
  )

  use content <- result.try(
    generator.generate_file(config, content, ast, tables)
    |> result.map_error(FailedToGenerate(_, File(path: path, content: content))),
  )

  Ok(content)
}

pub fn generate_files(config: common.Configuration, files: List(File)) {
  use tokens <- result.try(
    files
    |> list.try_map(fn(entry) {
      lexer.tokenize(entry.path, entry.content)
      |> result.map_error(FailedToTokenize(_, entry))
    }),
  )

  use nodes <- result.try(
    list.zip(files, tokens)
    |> list.try_map(fn(entry) {
      let #(file, tokens) = entry
      parser.parse(tokens)
      |> result.map_error(FailedToParse(_, file))
    }),
  )

  use tables <- result.try(
    list.zip(files, nodes)
    |> list.try_map(fn(entry) {
      extractor.extract_tables(entry.0.path, entry.1)
      |> result.map_error(FailedToExtractTables(_, entry.0))
    }),
  )

  let tables =
    list.fold(tables, dict.new(), fn(acc, table) { dict.merge(acc, table) })
    |> extractor.complete_fields_dependencies()
    |> generator.process_delegated_table

  use result <- result.try(
    list.zip(files, nodes)
    |> list.try_map(fn(entry) {
      let #(file, ast) = entry
      use content <- result.try(
        generator.generate_file(config, file.content, ast, tables)
        |> result.map_error(FailedToGenerate(_, file)),
      )
      Ok(File(path: file.path, content: content))
    }),
  )

  Ok(#(result, tables))
}

// ---------------------------------------------------------------------------
// Console output
// ---------------------------------------------------------------------------

fn ansi(text: String, code: String) -> String {
  "\u{1b}[" <> code <> "m" <> text <> "\u{1b}[0m"
}

fn bold(text: String) -> String {
  ansi(text, "1")
}

fn dim(text: String) -> String {
  ansi(text, "2")
}

fn green(text: String) -> String {
  ansi(text, "32")
}

fn yellow(text: String) -> String {
  ansi(text, "33")
}

fn red(text: String) -> String {
  ansi(text, "31")
}

fn cyan(text: String) -> String {
  ansi(text, "36")
}

fn print_header(title: String) -> Nil {
  io.println("")
  io.println(bold(cyan("suweal_gen")) <> dim(" › ") <> bold(title))
  io.println("")
}

fn print_success(message: String) -> Nil {
  io.println("  " <> green("✓") <> " " <> message)
}

fn print_info(message: String) -> Nil {
  io.println("  " <> cyan("•") <> " " <> message)
}

fn print_warning(message: String) -> Nil {
  io.println("  " <> yellow("!") <> " " <> message)
}

fn print_detail(message: String) -> Nil {
  io.println("      " <> dim(message))
}

fn print_error(message: String) -> Nil {
  io.println_error("")
  io.println_error("  " <> red("✗") <> " " <> bold(red("Error")))
  message
  |> string.split("\n")
  |> list.each(fn(line) { io.println_error("    " <> line) })
  io.println_error("")
}

/// "1 file", "2 files"
fn pluralize(count: Int, noun: String) -> String {
  let noun = case count {
    1 -> noun
    _ -> noun <> "s"
  }
  bold(int.to_string(count)) <> " " <> noun
}

fn elapsed_since(start: timestamp.Timestamp) -> String {
  let seconds =
    timestamp.difference(start, timestamp.system_time())
    |> duration.to_seconds
  float.to_string(float.to_precision(seconds, 2)) <> "s"
}

fn describe_file_error(path: String, error: simplifile.FileError) -> String {
  path <> " (" <> simplifile.describe_error(error) <> ")"
}

// ---------------------------------------------------------------------------
// File system helpers
// ---------------------------------------------------------------------------

/// List the ".surql" files in the given directory and its subdirectories
/// recursively. The returned paths do not include the ".surql" extension.
fn list_files(
  base: String,
  found: List(String),
) -> Result(List(String), String) {
  use paths <- result.try(
    simplifile.read_directory(base)
    |> result.map_error(fn(_) { "Failed to read directory: " <> base }),
  )

  list.try_fold(paths, found, fn(acc, path) {
    let full_path = base <> "/" <> path
    use is_directory <- result.try(
      simplifile.is_directory(full_path)
      |> result.map_error(fn(_) {
        "Failed to check if path is a directory: " <> full_path
      }),
    )

    case is_directory {
      True -> list_files(full_path, acc)
      False ->
        case string.split_once(path, ".") {
          Ok(#(name, "surql")) -> Ok([base <> "/" <> name, ..acc])
          _ -> Ok(acc)
        }
    }
  })
}

/// Write a file, creating its parent directories if needed.
fn create_dir_and_write(path: String, content: String) -> Result(Nil, String) {
  let directory_path =
    path
    |> string.split("/")
    |> list.reverse
    |> list.drop(1)
    |> list.reverse
    |> string.join("/")

  use _ <- result.try(
    simplifile.create_directory_all(directory_path)
    |> result.map_error(fn(_) {
      "Failed to create directory: " <> directory_path
    }),
  )

  simplifile.write(path, content)
  |> result.map_error(fn(err) {
    "Failed to write file: " <> describe_file_error(path, err)
  })
}

// ---------------------------------------------------------------------------
// Change detection & versioning
// ---------------------------------------------------------------------------

fn hash_file(path: String) -> Result(String, simplifile.FileError) {
  use bits <- result.map(simplifile.read_bits(path))
  crypto.hash(crypto.Md5, bits)
  |> bit_array.base16_encode
}

fn compute_file_hashes(
  files: List(String),
) -> Result(List(#(String, String)), String) {
  use file <- list.try_map(files)
  let path = file <> ".surql"
  case hash_file(path) {
    Ok(hash) -> Ok(#(file, hash))
    Error(err) ->
      Error("Failed to hash file: " <> describe_file_error(path, err))
  }
}

/// The files whose hash is new or differs from the previously recorded one.
fn changed_files(
  old: List(#(String, String)),
  new: List(#(String, String)),
) -> List(String) {
  new
  |> list.filter(fn(entry) {
    let #(file, hash) = entry
    case list.key_find(old, file) {
      Ok(old_hash) -> old_hash != hash
      Error(_) -> True
    }
  })
  |> list.map(fn(entry) { entry.0 })
}

/// What happened to the source files since the last generation.
type Changes {
  FirstRun
  Unchanged
  Changed(files: List(String))
}

/// The versions to persist and the number of the version they follow.
type VersionPlan {
  VersionPlan(config: common.VersionsConfig, previous: Int, changes: Changes)
}

fn new_version(
  config: common.Configuration,
  number: Int,
) -> common.VersionConfig {
  let name = "v" <> int.to_string(number)
  common.VersionConfig(
    version: name,
    version_number: number,
    path: config.path <> "/versions_/" <> name,
    suweal_version:,
    date: timestamp.system_time(),
  )
}

fn read_stored_versions(
  config: common.Configuration,
) -> Result(common.VersionsConfig, Nil) {
  use content <- result.try(
    simplifile.read(config.path <> "/versions.json")
    |> result.replace_error(Nil),
  )
  json.parse(content, common.versions_config_decoder())
  |> result.replace_error(Nil)
}

fn plan_versions(
  config: common.Configuration,
  hashes: List(#(String, String)),
) -> Result(VersionPlan, String) {
  case read_stored_versions(config) {
    // Nothing (valid) stored yet: this is the very first version.
    Error(_) ->
      Ok(VersionPlan(
        config: common.VersionsConfig(
          [new_version(config, 1)],
          config.path <> "/migrations_",
          hashes,
        ),
        previous: 0,
        changes: FirstRun,
      ))

    Ok(stored) -> {
      use last <- result.try(
        list.max(stored.versions, fn(a, b) {
          int.compare(a.version_number, b.version_number)
        })
        |> result.replace_error("versions.json does not contain any version"),
      )

      let changes = case changed_files(stored.files, hashes) {
        [] -> Unchanged
        files -> Changed(files)
      }

      Ok(VersionPlan(
        config: common.VersionsConfig(
          versions: [
            new_version(config, last.version_number + 1),
            ..stored.versions
          ],
          migrations: stored.migrations,
          files: hashes,
        ),
        previous: last.version_number,
        changes:,
      ))
    }
  }
}

// ---------------------------------------------------------------------------
// Generation steps
// ---------------------------------------------------------------------------

fn read_sources(files: List(String)) -> Result(List(File), String) {
  use file <- list.try_map(files)
  let path = file <> ".surql"
  case simplifile.read(path) {
    Ok(content) -> Ok(File(path: file, content:))
    Error(err) ->
      Error("Failed to read file: " <> describe_file_error(path, err))
  }
}

/// Write every generated module to its source location and to the snapshot
/// directory of the new version.
fn write_generated_files(
  config: common.Configuration,
  files: List(File),
  version: Int,
) -> Result(Nil, String) {
  use file <- list.try_each(files)
  let source_path = file.path <> ".gleam"
  let snapshot_path =
    config.path
    <> "/versions_/v"
    <> int.to_string(version)
    <> string.remove_prefix(file.path, config.path)
    <> ".gleam"

  use _ <- result.try(create_dir_and_write(snapshot_path, file.content))
  create_dir_and_write(source_path, file.content)
  |> result.map(fn(_) { print_detail(source_path) })
}

fn read_previous_fields(
  config: common.Configuration,
  version: Int,
) -> Result(List(migration.MigrationTableField), String) {
  let path =
    config.path <> "/versions_/v" <> int.to_string(version) <> "/fields.json"

  use content <- result.try(
    simplifile.read(path)
    |> result.replace_error(
      "Failed to read fields of previous version ("
      <> int.to_string(version)
      <> ")",
    ),
  )

  json.parse(content, decode.list(migration.migration_table_field_decoder()))
  |> result.replace_error("Failed to parse fields of previous version")
}

/// Write the field snapshot and the migration of the new version, returning
/// the number of fields that differ from the previous version.
fn write_migration(
  config: common.Configuration,
  tables: dict.Dict(String, extractor.TableInfo),
  previous: Int,
) -> Result(Int, String) {
  let version = previous + 1
  let fields =
    migration.extract_fields(tables)
    |> list.filter(fn(field) { field.raw_string != "__IGNORE__" })

  use previous_fields <- result.try(case previous {
    0 -> Ok([])
    _ -> read_previous_fields(config, previous)
  })
  let migration_fields =
    migration.find_different_fields(fields, previous_fields, tables)

  use _ <- result.try(create_dir_and_write(
    config.path <> "/versions_/v" <> int.to_string(version) <> "/fields.json",
    json.to_string(json.array(fields, migration.migration_table_field_to_json)),
  ))

  let migration_path =
    config.path
    <> "/migrations_/migration_"
    <> int.to_string(version)
    <> ".gleam"
  use _ <- result.try(create_dir_and_write(
    migration_path,
    migration.generate_migrations(version, migration_fields)
      |> module.to_string,
  ))

  print_success(
    pluralize(list.length(migration_fields), "field change")
    <> " → "
    <> dim(migration_path),
  )
  Ok(list.length(migration_fields))
}

fn print_changes(changes: Changes) -> Nil {
  case changes {
    FirstRun -> print_info("No previous version found, starting at v1")
    Unchanged -> print_info("No changes since the previous version")
    Changed(files) -> {
      print_info(pluralize(list.length(files), "file") <> " changed:")
      files |> list.sort(string.compare) |> list.each(print_detail)
    }
  }
}

fn run_gen(config: common.Configuration) -> Result(Nil, String) {
  let started = timestamp.system_time()
  print_header("gen " <> dim(config.path))

  use files <- result.try(list_files(config.path, []))
  print_success("Found " <> pluralize(list.length(files), ".surql file"))

  use hashes <- result.try(compute_file_hashes(files))
  use plan <- result.try(plan_versions(config, hashes))
  print_changes(plan.changes)

  let version = plan.previous + 1
  case plan.changes, config.force {
    Unchanged, False -> {
      print_warning(
        "Nothing to generate, use " <> bold("--force") <> " to generate anyway",
      )
      Ok(Nil)
    }
    _, _ -> {
      case plan.changes, config.force {
        Unchanged, True -> print_warning("Forced generation")
        _, _ -> Nil
      }

      use sources <- result.try(read_sources(files))
      use #(generated, tables) <- result.try(
        generate_files(config, sources)
        |> result.map_error(render_error),
      )
      print_success("Generated " <> pluralize(list.length(generated), "module"))

      use _ <- result.try(write_generated_files(config, generated, version))
      print_success(
        "Wrote snapshot "
        <> dim(config.path <> "/versions_/v" <> int.to_string(version)),
      )

      use _ <- result.try(case config.versioning {
        True ->
          result.map(write_migration(config, tables, plan.previous), fn(_) {
            Nil
          })
        False -> Ok(Nil)
      })

      use _ <- result.try(
        simplifile.write(
          config.path <> "/versions.json",
          json.to_string(common.versions_config_to_json(plan.config)),
        )
        |> result.map_error(fn(err) {
          "Failed to write file: "
          <> describe_file_error(config.path <> "/versions.json", err)
        }),
      )

      io.println("")
      io.println(
        "  "
        <> green(bold("Done!"))
        <> " Generated version "
        <> bold("v" <> int.to_string(version))
        <> dim(" in " <> elapsed_since(started)),
      )
      io.println("")
      Ok(Nil)
    }
  }
}

fn run_clear(path: String) -> Result(Nil, String) {
  print_header("clear " <> dim(path))

  use files <- result.try(list_files(path, []))
  let targets =
    list.flatten([
      [path <> "/versions_", path <> "/versions.json", path <> "/migrations_"],
      list.map(files, fn(file) { file <> ".gleam" }),
    ])

  // Missing targets are fine: the goal is that they do not exist afterwards.
  let removed =
    list.filter(targets, fn(target) {
      case simplifile.is_file(target), simplifile.is_directory(target) {
        Ok(False), Ok(False) -> False
        _, _ -> simplifile.delete(target) == Ok(Nil)
      }
    })

  list.each(removed, print_detail)
  print_success("Removed " <> pluralize(list.length(removed), "item"))
  io.println("")
  Ok(Nil)
}

pub fn main() -> Nil {
  let assert Ok(command) =
    command()
    |> clip.run(argv.load().arguments)

  let result = case command {
    GenCommand(config:) -> run_gen(config)
    ClearCommand(path:) -> run_clear(path)
  }

  case result {
    Ok(Nil) -> Nil
    Error(message) -> {
      print_error(message)
      shellout.exit(1)
    }
  }
}
