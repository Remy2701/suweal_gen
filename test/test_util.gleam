import gleam/list
import gleam/string
import suweal_gen

pub fn merge_content(files: List(suweal_gen.File)) -> String {
  files
  |> list.map(fn(file) { "// [" <> file.path <> "]\n" <> file.content })
  |> string.join("\n\n")
}
