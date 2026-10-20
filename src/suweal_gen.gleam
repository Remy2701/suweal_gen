import argv
import clip
import clip/arg
import clip/flag
import common
import extractor
import generator
import gleam/dict
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import lexer
import parser
import simplifile

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

/// Define the command-line interface for the tool.
fn command() {
  clip.command({
    use offstage <- clip.parameter
    use service <- clip.parameter
    use path <- clip.parameter

    common.Configuration(offstage, service, path)
  })
  |> clip.flag(flag.new("offstage") |> flag.help("Enable offstage integration"))
  |> clip.flag(
    flag.new("service") |> flag.help("Enable suweal_service integration"),
  )
  |> clip.arg(
    arg.new("path")
    |> arg.default("./src")
    |> arg.help("Path to the source directory"),
  )
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
      Ok(File(path: file.path <> ".gleam", content: content))
    }),
  )

  Ok(result)
}

pub fn main() -> Nil {
  // Parse the arguments
  let assert Ok(config) =
    command()
    |> clip.run(argv.load().arguments)

  // List the files
  let assert Ok(files) = list_files(config.path, [])

  // Read all *.surql files
  let assert Ok(files) =
    list.try_map(files, fn(file) {
      use content <- result.try(simplifile.read(file <> ".surql"))
      Ok(File(path: file, content: content))
    })

  let assert Ok(files) =
    generate_files(config, files)
    |> result.map_error(render_error)
    |> result.map_error(io.println)

  // Generate the output files
  let assert Ok(_) =
    files
    |> list.try_each(fn(file) {
      use _ <- result.try(
        simplifile.write(file.path, file.content)
        |> result.map_error(fn(_) { "Failed to write file: " <> file.path }),
      )
      Ok(Nil)
    })

  Nil
}
