import birdie
import common
import suweal_gen

pub const input = "DEFINE TABLE user TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;\n"
  <> "\n"
  <> "DEFINE FIELD username ON user TYPE string DEFAULT NONE PERMISSIONS FULL;\n"
  <> "DEFINE FIELD email ON user TYPE string DEFAULT NONE PERMISSIONS FULL;\n"
  <> "DEFINE FIELD password ON user TYPE string PERMISSIONS FULL;\n"

pub const path = "./src/db/test/simple_user_table"

pub fn simple_user_table_test() {
  let assert Ok(content) =
    suweal_gen.generate_file(
      common.Configuration(offstage: False, service: False, path: "./src"),
      input,
      path,
    )

  birdie.snap(content, "SimpleUserTable[backstage = False, service = False]")
}

pub fn simple_user_table_with_backstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_file(
      common.Configuration(offstage: True, service: False, path: "./src"),
      input,
      path,
    )

  birdie.snap(content, "SimpleUserTable[backstage = True, service = False]")
}

pub fn simple_user_table_with_backstage_and_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_file(
      common.Configuration(offstage: True, service: True, path: "./src"),
      input,
      path,
    )

  birdie.snap(content, "SimpleUserTable[backstage = True, service = True]")
}
