import birdie
import common
import gleam/list
import gleam/string
import sample/table_with_nested_fields
import suweal_gen

pub const input = "CREATE post SET meta = $meta;"

pub const path = "./src/db/test/create_with_nested_fields"

pub fn create_with_nested_fields_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: False, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: table_with_nested_fields.path,
          content: table_with_nested_fields.input,
        ),
        suweal_gen.File(path: path, content: input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "CreateWithNestedFields[offstage = False, service = False]",
  )
}

pub fn create_with_nested_fields_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: table_with_nested_fields.path,
          content: table_with_nested_fields.input,
        ),
        suweal_gen.File(path: path, content: input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "CreateWithNestedFields[offstage = True, service = False]",
  )
}

pub fn create_with_nested_fields_with_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: True, path: "./src"),
      [
        suweal_gen.File(
          path: table_with_nested_fields.path,
          content: table_with_nested_fields.input,
        ),
        suweal_gen.File(path: path, content: input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "CreateWithNestedFields[offstage = True, service = True]",
  )
}

pub const direct_input = "CREATE post SET meta.title = $title, meta.content = $content;"

pub const direct_path = "./src/db/test/create_directly_with_nested_fields"

pub fn create_directly_with_nested_fields_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: False, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: table_with_nested_fields.path,
          content: table_with_nested_fields.input,
        ),
        suweal_gen.File(path: direct_path, content: direct_input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, direct_path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "CreateDirectlyWithNestedFields[offstage = False, service = False]",
  )
}

pub fn create_directly_with_nested_fields_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: table_with_nested_fields.path,
          content: table_with_nested_fields.input,
        ),
        suweal_gen.File(path: direct_path, content: direct_input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, direct_path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "CreateDirectlyWithNestedFields[offstage = True, service = False]",
  )
}

pub fn create_directly_with_nested_fields_with_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: True, path: "./src"),
      [
        suweal_gen.File(
          path: table_with_nested_fields.path,
          content: table_with_nested_fields.input,
        ),
        suweal_gen.File(path: direct_path, content: direct_input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, direct_path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "CreateDirectlyWithNestedFields[offstage = True, service = True]",
  )
}
