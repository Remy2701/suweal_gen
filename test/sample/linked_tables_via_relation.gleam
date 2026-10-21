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
  <> "DEFINE FIELD b0 ON b TYPE bool DEFAULT NONE PERMISSIONS FULL;\n"
  <> "DEFINE FIELD b1 ON b TYPE int DEFAULT NONE PERMISSIONS FULL;\n"

pub const path_table_b = "./src/db/test/linked_table_b"

pub const input_table_c = "DEFINE TABLE c TYPE RELATION IN a OUT b SCHEMAFULL PERMISSIONS NONE;\n"
  <> "\n"
  <> "DEFINE FIELD in ON c TYPE record<a> DEFAULT NONE PERMISSIONS FULL;\n"
  <> "DEFINE FIELD out ON c TYPE record<b> DEFAULT NONE PERMISSIONS FULL;\n"

pub const path_table_c = "./src/db/test/linked_table_c"

pub fn linked_tables_via_relation_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: False, service: False, path: "./src"),
      [
        suweal_gen.File(path: path_table_a, content: input_table_a),
        suweal_gen.File(path: path_table_b, content: input_table_b),
        suweal_gen.File(path: path_table_c, content: input_table_c),
      ],
    )

  birdie.snap(
    test_util.merge_content(content),
    "LinkedTablesViaRelation[offstage = False, service = False]",
  )
}

pub fn linked_tables_via_relation_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: False, path: "./src"),
      [
        suweal_gen.File(path: path_table_a, content: input_table_a),
        suweal_gen.File(path: path_table_b, content: input_table_b),
        suweal_gen.File(path: path_table_c, content: input_table_c),
      ],
    )

  birdie.snap(
    test_util.merge_content(content),
    "LinkedTablesViaRelation[offstage = True, service = False]",
  )
}

pub fn linked_tables_via_relation_with_offstage_and_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: True, path: "./src"),
      [
        suweal_gen.File(path: path_table_a, content: input_table_a),
        suweal_gen.File(path: path_table_b, content: input_table_b),
        suweal_gen.File(path: path_table_c, content: input_table_c),
      ],
    )

  birdie.snap(
    test_util.merge_content(content),
    "LinkedTablesViaRelation[offstage = True, service = True]",
  )
}
