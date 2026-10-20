import birdie
import common
import internal/builder/enum_decoder
import omcg/module

pub fn enum_decoder_generation_test() {
  let generated =
    enum_decoder.generate(
      common.Configuration(False, False, "./src/db/test"),
      "color",
      ["red", "green", "blue"],
    )

  birdie.snap(module.to_string(generated), "enum_decoder_generation_test")
}

pub fn enum_decoder_generation_with_offstage_test() {
  let generated =
    enum_decoder.generate(
      common.Configuration(True, False, "./src/db/test"),
      "color",
      ["red", "green", "blue"],
    )

  birdie.snap(
    module.to_string(generated),
    "enum_decoder_generation_with_offstage_test",
  )
}

pub fn enum_decoder_generation_with_service_test() {
  let generated =
    enum_decoder.generate(
      common.Configuration(True, True, "./src/db/test"),
      "color",
      ["red", "green", "blue"],
    )

  birdie.snap(
    module.to_string(generated),
    "enum_decoder_generation_with_service_test",
  )
}
