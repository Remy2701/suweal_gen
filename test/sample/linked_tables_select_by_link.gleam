import birdie
import common
import gleam/list
import gleam/string
import sample/linked_tables
import suweal_gen

pub const input = "SELECT * FROM b WHERE b0 = $b0;"

pub const path = "./src/db/test/linked_tables_select_by_link"

pub fn linked_tables_select_by_link_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: False, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables.path_table_a,
          content: linked_tables.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables.path_table_b,
          content: linked_tables.input_table_b,
        ),
        suweal_gen.File(path: path, content: input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesSelectByLink[offstage = False, service = False]",
  )
}

pub fn linked_tables_select_by_link_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables.path_table_a,
          content: linked_tables.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables.path_table_b,
          content: linked_tables.input_table_b,
        ),
        suweal_gen.File(path: path, content: input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesSelectByLink[offstage = True, service = False]",
  )
}

pub fn linked_tables_select_by_link_with_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: True, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables.path_table_a,
          content: linked_tables.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables.path_table_b,
          content: linked_tables.input_table_b,
        ),
        suweal_gen.File(path: path, content: input),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesSelectByLink[offstage = True, service = True]",
  )
}
