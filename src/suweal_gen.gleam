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
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleam/time/timestamp
import lexer
import migration
import omcg/module
import parser
import simplifile

const suweal_version = "0.4.3-local"

/// List the files ending with ".surql" in the given directory and its 
/// subdirectories recursively.
fn list_files(
  base: String,
  list: List(String),
) -> Result(List(String), String) {
  use paths <- result.try(
    simplifile.read_directory(base)
    |> result.map_error(fn(_) { "Failed to read directory: " <> base }),
  )
  use data <- result.try(
    list.try_fold(paths, list, fn(acc, path) {
      use is_directory <- result.try(
        simplifile.is_directory(base <> "/" <> path)
        |> result.map_error(fn(_) {
          "Failed to check if path is directory: " <> base <> "/" <> path
        }),
      )
      use files <- result.try(case is_directory {
        True -> list_files(base <> "/" <> path, acc)
        False -> {
          let #(name, extension) =
            string.split_once(path, ".") |> result.unwrap(#(path, ""))
          case extension {
            "surql" -> Ok([base <> "/" <> name, ..acc])
            _ -> Ok(acc)
          }
        }
      })
      Ok(files)
    }),
  )
  Ok(data)
}

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
        use path <- clip.parameter

        GenCommand(common.Configuration(offstage:, service:, versioning:, path:))
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

fn hash_file(path: String) -> Result(String, simplifile.FileError) {
  use bits <- result.map(simplifile.read_bits(path))
  crypto.hash(crypto.Md5, bits)
  |> bit_array.base16_encode
}

fn compute_file_hashes(
  files: List(String),
) -> Result(List(#(String, String)), String) {
  list.try_map(files, fn(file) {
    use hash <- result.try(
      hash_file(file <> ".surql")
      |> result.map_error(fn(err) {
        "Failed to compute hash for file: "
        <> file
        <> ": "
        <> string.inspect(err)
      }),
    )
    Ok(#(file, hash))
  })
}

fn compare_hashes(
  old: List(#(String, String)),
  new: List(#(String, String)),
) -> List(String) {
  list.filter(new, fn(new_entry) {
    let #(file, hash) = new_entry
    case list.find(old, fn(old_entry) { old_entry.0 == file }) {
      Ok(#(_, old_hash)) -> old_hash != hash
      Error(_) -> True
    }
  })
  |> list.map(fn(entry) { entry.0 })
}

fn read_versions(
  config: common.Configuration,
  hashes: List(#(String, String)),
) -> Result(#(common.VersionsConfig, Int), Nil) {
  let versions =
    simplifile.read(config.path <> "/versions.json")
    |> result.replace_error(Nil)
    |> result.try(fn(content) {
      json.parse(content, common.versions_config_decoder())
      |> result.replace_error(Nil)
    })

  case versions, config.versioning {
    Error(_), True -> {
      io.println("Versioning was not enabled, enabling now...")
      Ok(#(
        common.VersionsConfig(
          [
            common.VersionConfig(
              version: "v1",
              version_number: 1,
              path: config.path <> "/versions_/v1",
              suweal_version: suweal_version,
              date: timestamp.system_time(),
            ),
          ],
          config.path <> "/migrations_",
          hashes,
        ),
        0,
      ))
    }
    Ok(version), _ -> {
      let different = compare_hashes(version.files, hashes)

      let last_version =
        list.max(version.versions, fn(a, b) {
          int.compare(a.version_number, b.version_number)
        })
      let last_version = case last_version {
        Ok(version) -> version
        Error(_) -> panic as "Failed to determine the last version"
      }

      case different {
        [] -> {
          io.println("Nothing has changed!")
          Ok(#(version, last_version.version_number))
        }
        _ -> {
          io.println(
            "Found "
            <> int.to_string(list.length(different))
            <> " different files",
          )
          Ok(#(
            common.VersionsConfig(
              versions: [
                common.VersionConfig(
                  version: "v" <> int.to_string(last_version.version_number + 1),
                  version_number: last_version.version_number + 1,
                  path: config.path
                    <> "/versions_/v"
                    <> int.to_string(last_version.version_number + 1),
                  suweal_version: suweal_version,
                  date: timestamp.system_time(),
                ),
                ..version.versions
              ],
              migrations: version.migrations,
              files: hashes,
            ),
            last_version.version_number,
          ))
        }
      }
    }
    _, _ -> Error(Nil)
  }
}

fn create_dir_and_write(path: String, content: String) -> Result(Nil, String) {
  let directory_path =
    path
    |> string.split("/")
    |> list.reverse()
    |> list.drop(1)
    |> list.reverse()
    |> string.join("/")

  use _ <- result.try(
    simplifile.create_directory_all(directory_path)
    |> result.map_error(fn(_) {
      "Failed to create directory: " <> directory_path
    }),
  )

  use _ <- result.try(
    simplifile.write(path, content)
    |> result.map_error(fn(err) {
      "Failed to write file: " <> path <> " (" <> string.inspect(err) <> ")"
    }),
  )

  Ok(Nil)
}

fn gen_command(config: common.Configuration) {
  // List the files
  let assert Ok(files) = list_files(config.path, [])
  let assert Ok(hashes) = compute_file_hashes(files)

  let #(versions, last_version) =
    read_versions(config, hashes)
    |> result.map(fn(value) { #(Ok(value.0), Ok(value.1)) })
    |> result.unwrap(#(Error(Nil), Error(Nil)))

  // Read all *.surql files
  let assert Ok(files) =
    list.try_map(files, fn(file) {
      use content <- result.try(simplifile.read(file <> ".surql"))
      Ok(File(path: file, content: content))
    })

  // Generate the output files
  let assert Ok(#(files, tables)) =
    generate_files(config, files)
    |> result.map_error(render_error)
    |> result.map_error(io.println)

  // Generate the output files
  let assert Ok(_) =
    files
    |> list.try_each(fn(file) {
      let version_path =
        result.map(last_version, fn(version) {
          config.path
          <> "/versions_/v"
          <> int.to_string(version + 1)
          <> string.remove_prefix(file.path, config.path)
          <> ".gleam"
        })

      let source_path = file.path <> ".gleam"

      use _ <- result.try(case version_path {
        Ok(version_path) -> create_dir_and_write(version_path, file.content)
        _ -> Ok(Nil)
      })

      use _ <- result.try(
        simplifile.write(source_path, file.content)
        |> result.map_error(fn(err) {
          "Failed to write file: "
          <> source_path
          <> " ("
          <> string.inspect(err)
          <> ")"
        }),
      )
      Ok(Nil)
    })

  // Generate the migrations if versioning is enabled
  let assert Ok(_) = case config.versioning {
    True -> {
      let fields =
        migration.extract_fields(tables)
        |> list.filter(fn(field) { field.raw_string != "__IGNORE__" })

      use last_version <- result.try(
        last_version
        |> result.replace_error("No version found, cannot generate migrations"),
      )

      use migration_fields <- result.try(case last_version {
        0 -> Ok(migration.find_different_fields(fields, [], tables))
        _ -> {
          let previous_version_path =
            config.path
            <> "/versions_/v"
            <> int.to_string(last_version)
            <> "/fields.json"

          use previous_fields <- result.try(
            simplifile.read(previous_version_path)
            |> result.replace_error(
              "Failed to read fields of previous version ("
              <> int.to_string(last_version)
              <> ")",
            ),
          )

          use previous_fields <- result.try(
            json.parse(
              previous_fields,
              decode.list(migration.migration_table_field_decoder()),
            )
            |> result.replace_error(
              "Failed to parse fields of previous version",
            ),
          )

          let fields =
            migration.find_different_fields(fields, previous_fields, tables)

          Ok(fields)
        }
      })

      io.println(
        "Found "
        <> int.to_string(list.length(migration_fields))
        <> " different fields.",
      )

      let version_path =
        config.path
        <> "/versions_/v"
        <> int.to_string(last_version + 1)
        <> "/fields.json"

      use _ <- result.try(
        simplifile.write(
          version_path,
          json.to_string(json.array(
            fields,
            migration.migration_table_field_to_json,
          )),
        )
        |> result.map_error(fn(err) {
          "Failed to write file: "
          <> version_path
          <> " ("
          <> string.inspect(err)
          <> ")"
        }),
      )

      let migration =
        migration.generate_migrations(last_version + 1, migration_fields)

      // Write migration to migration_<version>.gleam
      let migration_path =
        config.path
        <> "/migrations_/migration_"
        <> int.to_string(last_version + 1)
        <> ".gleam"

      use _ <- result.try(create_dir_and_write(
        migration_path,
        module.to_string(migration),
      ))

      Ok(Nil)
    }
    False -> Ok(Nil)
  }

  // Write the updated versions to the versions.json file if available
  let _ =
    result.map(versions, fn(versions) {
      simplifile.write(
        config.path <> "/versions.json",
        json.to_string(common.versions_config_to_json(versions)),
      )
    })

  Nil
}

fn clear_command(path: String) {
  let assert Ok(files) = list_files(path, [])

  let _ = simplifile.delete(path <> "/versions_")
  let _ = simplifile.delete(path <> "/versions.json")
  let _ = simplifile.delete(path <> "/migrations_")

  let _ = list.map(files, fn(file) { simplifile.delete(file <> ".gleam") })

  Nil
}

pub fn main() -> Nil {
  // Parse the arguments
  let assert Ok(command) =
    command()
    |> clip.run(argv.load().arguments)

  case command {
    GenCommand(config:) -> gen_command(config)
    ClearCommand(path:) -> clear_command(path)
  }
}
