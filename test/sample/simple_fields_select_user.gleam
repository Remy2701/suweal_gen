import birdie
import common
import gleam/list
import gleam/string
import sample/simple_user_table_test
import suweal_gen

pub const input = "SELECT username, email FROM user;"

pub const path = "./src/db/test/simple_select_user"

pub fn simple_select_fields_user_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: False, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: simple_user_table_test.path,
          content: simple_user_table_test.input,
        ),
        suweal_gen.File(path: path, content: input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "SimpleSelectFieldsUser[offstage = False, service = False]",
  )
}

pub fn simple_select_fields_user_with_backstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: simple_user_table_test.path,
          content: simple_user_table_test.input,
        ),
        suweal_gen.File(path: path, content: input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "SimpleSelectFieldsUser[offstage = True, service = False]",
  )
}

pub fn simple_select_fields_user_with_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: True, path: "./src"),
      [
        suweal_gen.File(
          path: simple_user_table_test.path,
          content: simple_user_table_test.input,
        ),
        suweal_gen.File(path: path, content: input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "SimpleSelectFieldsUser[offstage = True, service = True]",
  )
}
