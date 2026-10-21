import gleam/list
import omcg/id_case
import omcg/module

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                        Enum Definition                                        //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn generate(name: String, values: List(String)) -> module.Module {
  module.type_definition.create(id_case.string_to_pascal_case(name))
  |> module.type_definition.public()
  |> list.fold(values, _, fn(type_def, value) {
    module.type_definition.add(
      type_def,
      module.type_variant.create(id_case.string_to_pascal_case(value)),
    )
  })
}
