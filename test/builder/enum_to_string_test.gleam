import birdie
import internal/builder/enum_to_string
import omcg/module

pub fn enum_to_string_generation_test() {
  let generated = enum_to_string.generate("color", ["red", "green", "blue"])

  birdie.snap(module.to_string(generated), "enum_to_string_generation_test")
}
