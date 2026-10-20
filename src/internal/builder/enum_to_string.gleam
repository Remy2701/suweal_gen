import gleam/list
import omcg/module
import omcg/module_common

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                       Enum `to_string`                                        //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn generate(name: String, values: List(String)) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.with_name(name <> "_to_string")
  |> module.function_definition.public()
  |> module.function_definition.add_aliased_parameter(
    "value",
    "value",
    module_common.type_identifier(name),
  )
  |> module.function_definition.with_return_type(module.types.string())
  |> module.function_definition.add(
    module.identifier.create("value")
    |> module.case_expression.create()
    |> list.fold(values, _, fn(module, value) {
      module.case_expression.add(
        module,
        module_common.type_identifier(value)
          |> module.case_branch.create()
          |> module.case_branch.add(module.literal.string(value)),
      )
    }),
  )
}
