import common
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import omcg/id_case
import omcg/module
import omcg/offstage_serialize_module
import omcg/option_module
import suweal/surreal_type

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             Query                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub type OperationType {
  Create
  Read
  Update
  Delete
}

pub fn generate(
  parameters parameters: List(common.ParameterProperty),
  result_type result_type: String,
  prefix prefix: option.Option(String),
  operation_type operation_type: OperationType,
  only only: Bool,
) -> module.Module {
  list.fold(
    parameters,
    module.function_definition.create()
      |> module.function_definition.with_name("query")
      |> module.function_definition.public()
      |> module.function_definition.with_return_type(
        module.function_call.create(module.binop.access(
          module.identifier.create("query"),
          module.identifier.create("Query"),
        ))
        |> module.function_call.add(case only {
          True -> module.identifier.create(result_type)
          False ->
            module.function_call.create(module.identifier.create("List"))
            |> module.function_call.add(module.identifier.create(result_type))
        })
        |> module.function_call.add(
          option_module.type_(case only {
            True -> module.identifier.create(result_type)
            False ->
              module.function_call.create(module.identifier.create("List"))
              |> module.function_call.add(module.identifier.create(result_type))
          }),
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
                    list.reverse([id_case.string_to_pascal_case(last), ..rest]),
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
    module.binop.access(
      module.identifier.create("query"),
      module.identifier.create("query"),
    )
    |> module.function_call.create()
    |> module.function_call.add_with_alias("resource", case prefix {
      Some(prefix) ->
        module.binop.access(
          module.identifier.create(prefix),
          module.identifier.create("table_name"),
        )
      None -> module.identifier.create("table_name")
    })
    |> module.function_call.add_with_alias(
      "operation_type",
      module.binop.access(
        module.identifier.create("suweal_service"),
        module.identifier.create(case operation_type {
          Create -> "Create"
          Read -> "Read"
          Update -> "Update"
          Delete -> "Delete"
        }),
      ),
    )
    |> module.function_call.add_with_alias(
      "query",
      module.identifier.create("query_node"),
    )
    |> module.function_call.add_with_alias("serializer", case only {
      True ->
        case operation_type, prefix {
          Delete, _ | _, None ->
            module.identifier.create("serializer")
            |> module.function_call.create()
          _, Some(prefix) ->
            module.binop.access(
              module.identifier.create(prefix),
              module.identifier.create("serializer"),
            )
            |> module.function_call.create()
        }
      False ->
        offstage_serialize_module.list_of(
          module.function_call.create(module.identifier.create("serializer")),
        )
    })
    |> module.function_call.add_with_alias(
      "parameters",
      module.function_call.create(module.identifier.create("parameters"))
        |> list.fold(parameters, _, fn(module, entry) {
          module.function_call.add_with_alias(
            module,
            entry.name,
            module.identifier.create(entry.name),
          )
        }),
    ),
  )
  |> module.add_import(["suweal", "surreal_ql"])
  |> module.add_import(["suweal_service", "query"])
  |> module.add_import(["suweal_service"])
}
