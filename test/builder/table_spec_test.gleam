import birdie
import common
import internal/builder/table_spec
import omcg/module

pub fn table_spec_generation_test() {
  let generated =
    table_spec.generate(
      common.Configuration(False, False, "./src/db/test"),
      "user",
    )

  birdie.snap(module.to_string(generated), "table_spec_json_generation_test")
}

pub fn table_spec_generation_with_offstage_test() {
  let generated =
    table_spec.generate(
      common.Configuration(True, False, "./src/db/test"),
      "user",
    )

  birdie.snap(
    module.to_string(generated),
    "table_spec_generation_with_offstage_test",
  )
}

pub fn table_spec_generation_with_service_test() {
  let generated =
    table_spec.generate(
      common.Configuration(True, True, "./src/db/test"),
      "user",
    )

  birdie.snap(
    module.to_string(generated),
    "table_spec_generation_with_service_test",
  )
}
