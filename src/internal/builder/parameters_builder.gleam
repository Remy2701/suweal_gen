import common
import gleam/list
import gleam/option
import gleam/string
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
        case entry.nested {
          option.Some(nested) ->
            module.identifier.create(
              case list.reverse(string.split(nested, ".")) {
                [last, ..rest] ->
                  string.join(
                    list.reverse([common.string_to_pascal_case(last), ..rest]),
                    ".",
                  )
                [] -> ""
              },
            )
          _ -> {
            surreal_type.to_gleam_module(entry.type_, entry.linked_enum)
          }
        },
      )
    },
  )
  |> module.function_definition.add(
    module.literal.list(
      list.map(parameters, fn(entry) {
        module.literal.tuple([
          module.literal.string(entry.name),
          case entry.nested {
            option.Some(nested) -> {
              module.identifier.create(
                string.join(
                  string.split(nested, ".")
                    |> list.map(common.string_to_snake_case),
                  ".",
                )
                <> "_to_surql",
              )
              |> module.function_call.create()
            }
            _ -> {
              surreal_type.value_to_gleam_module(
                entry.type_,
                entry.linked_enum,
                entry.name,
              )
            }
          },
        ])
      }),
    ),
  )
  |> module.add_import(["suweal", "surreal_ql"])
}
