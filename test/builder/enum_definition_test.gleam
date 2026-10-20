import birdie
import internal/builder/enum_definition
import omcg/module

pub fn enum_definition_generation_test() {
  let generated = enum_definition.generate("color", ["red", "green", "blue"])

  birdie.snap(module.to_string(generated), "enum_definition_generation_test")
}
