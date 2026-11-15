import common
import gleam/function
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import omcg/id_case
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
            case list.reverse(string.split(nested, ".")) {
              [last, ..rest] ->
                string.join(
                  list.reverse([id_case.string_to_pascal_case(last), ..rest]),
                  ".",
                )
                |> module.identifier.create()
                |> module.add_import([
                  "#TABLE:" <> result.unwrap(list.last(rest), last),
                ])
              [] -> module.identifier.create("")
            }

          _ -> {
            surreal_type.to_gleam_module(entry.type_, entry.linked_enum)
            |> case common.resolve_surreal_type_access_deps(entry.type_) {
              option.Some(dep) -> module.add_import(_, ["#TABLE:" <> dep])
              _ -> function.identity
            }
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
                    |> list.map(id_case.string_to_snake_case),
                  ".",
                )
                <> "_to_surql",
              )
              |> module.function_call.create()
              |> module.function_call.add(module.identifier.create(entry.name))
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
