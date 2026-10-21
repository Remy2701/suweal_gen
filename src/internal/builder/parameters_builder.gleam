import common
import gleam/list
import omcg/module
import suweal/surreal_type

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                          Parameters                                           //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn generate(parameters: List(common.ParameterProperty)) -> module.Module {
  list.fold(
    parameters,
    module.function_definition.create()
      |> module.function_definition.with_name("parameters")
      |> module.function_definition.public()
      |> module.function_definition.with_return_type(
        module.function_call.create(module.identifier.create("List"))
        |> module.function_call.add(
          module.literal.tuple([
            module.identifier.create("String"),
            module.binop.access(
              module.identifier.create("surreal_ql"),
              module.identifier.create("SurrealQL"),
            )
              |> module.add_import(["suweal", "surreal_ql"]),
          ]),
        ),
      ),
    fn(module, entry) {
      module.function_definition.add_aliased_parameter(
        module,
        entry.name,
        entry.name,
        surreal_type.to_gleam_module(entry.type_, entry.linked_enum),
      )
    },
  )
  |> module.function_definition.add(
    module.literal.list(
      list.map(parameters, fn(entry) {
        module.literal.tuple([
          module.literal.string(entry.name),
          surreal_type.value_to_gleam_module(
            entry.type_,
            entry.linked_enum,
            entry.name,
          ),
        ])
      }),
    ),
  )
  |> module.add_import(["suweal", "surreal_ql"])
}
