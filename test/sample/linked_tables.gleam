import birdie
import common
import suweal_gen
import test_util

pub const input_table_a = "DEFINE TABLE a TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;\n"
  <> "\n"
  <> "DEFINE FIELD a0 ON a TYPE string DEFAULT NONE PERMISSIONS FULL;\n"
  <> "DEFINE FIELD a1 ON a TYPE int DEFAULT NONE PERMISSIONS FULL;\n"

pub const path_table_a = "./src/db/test/linked_table_a"

pub const input_table_b = "DEFINE TABLE b TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;\n"
  <> "\n"
  <> "DEFINE FIELD b0 ON b TYPE record<a> DEFAULT NONE PERMISSIONS FULL;\n"
  <> "DEFINE FIELD b1 ON b TYPE int DEFAULT NONE PERMISSIONS FULL;\n"

pub const path_table_b = "./src/db/test/linked_table_b"

pub fn linked_tables_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: False, service: False, path: "./src"),
      [
        suweal_gen.File(path: path_table_a, content: input_table_a),
        suweal_gen.File(path: path_table_b, content: input_table_b),
      ],
    )

  birdie.snap(
    test_util.merge_content(content),
    "LinkedTables[offstage = False, service = False]",
  )
}

pub fn linked_tables_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: False, path: "./src"),
      [
        suweal_gen.File(path: path_table_a, content: input_table_a),
        suweal_gen.File(path: path_table_b, content: input_table_b),
      ],
    )

  birdie.snap(
    test_util.merge_content(content),
    "LinkedTables[offstage = True, service = False]",
  )
}

pub fn linked_tables_with_offstage_and_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: True, path: "./src"),
      [
        suweal_gen.File(path: path_table_a, content: input_table_a),
        suweal_gen.File(path: path_table_b, content: input_table_b),
      ],
    )

  birdie.snap(
    test_util.merge_content(content),
    "LinkedTables[offstage = True, service = True]",
  )
}
