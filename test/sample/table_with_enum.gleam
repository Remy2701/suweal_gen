import birdie
import common
import suweal_gen

pub const input = "DEFINE TABLE post TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;\n"
  <> "\n"
  <> "DEFINE FIELD title ON post TYPE string DEFAULT NONE PERMISSIONS FULL;\n"
  <> "DEFINE FIELD status ON post TYPE string DEFAULT NONE ASSERT $value INSIDE ['draft', 'processing', 'published'] PERMISSIONS FULL;\n"

pub const path = "./src/db/test/table_with_enum"

pub fn table_with_enum_test() {
  let assert Ok(content) =
    suweal_gen.generate_file(
      common.Configuration(offstage: False, service: False, path: "./src"),
      input,
      path,
    )

  birdie.snap(content, "TableWithEnum[offstage = False, service = False]")
}

pub fn table_with_enum_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_file(
      common.Configuration(offstage: True, service: False, path: "./src"),
      input,
      path,
    )

  birdie.snap(content, "TableWithEnum[offstage = True, service = False]")
}

pub fn table_with_enum_with_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_file(
      common.Configuration(offstage: True, service: True, path: "./src"),
      input,
      path,
    )

  birdie.snap(content, "TableWithEnum[offstage = True, service = True]")
}
