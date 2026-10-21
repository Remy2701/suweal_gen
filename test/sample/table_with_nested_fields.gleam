import birdie
import common
import suweal_gen

pub const input = "DEFINE TABLE post TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;\n"
  <> "\n"
  <> "DEFINE FIELD meta ON post TYPE object DEFAULT NONE PERMISSIONS FULL;\n"
  <> "DEFINE FIELD meta.title ON post TYPE string DEFAULT NONE PERMISSIONS FULL;\n"
  <> "DEFINE FIELD meta.content ON post TYPE string PERMISSIONS FULL;\n"

pub const path = "./src/db/test/table_with_nested_fields"

pub fn table_with_nested_fields_test() {
  let assert Ok(content) =
    suweal_gen.generate_file(
      common.Configuration(offstage: False, service: False, path: "./src"),
      input,
      path,
    )

  birdie.snap(
    content,
    "TableWithNestedFields[offstage = False, service = False]",
  )
}

pub fn table_with_nested_fields_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_file(
      common.Configuration(offstage: True, service: False, path: "./src"),
      input,
      path,
    )

  birdie.snap(
    content,
    "TableWithNestedFields[offstage = True, service = False]",
  )
}

pub fn table_with_nested_fields_with_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_file(
      common.Configuration(offstage: True, service: True, path: "./src"),
      input,
      path,
    )

  birdie.snap(content, "TableWithNestedFields[offstage = True, service = True]")
}
