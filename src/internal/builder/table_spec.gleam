import common
import omcg/module
import omcg/module_common

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                          Table Spec                                           //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn generate(config: common.Configuration, name: String) -> module.Module {
  case config.offstage {
    True -> generate_offstage_table_specs(name)
    False -> generate_gleam_table_specs(name)
  }
}

fn generate_gleam_table_specs(name: String) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.public()
  |> module.function_definition.with_name("specs")
  |> module.function_definition.with_return_type(
    module.function_call.create(module.binop.access(
      module.identifier.create("table_spec"),
      module.identifier.create("GleamTableSpec"),
    ))
    |> module.function_call.add(module_common.type_identifier(name)),
  )
  |> module.function_definition.add(
    module.function_call.create(module.binop.access(
      module.identifier.create("table_spec"),
      module.identifier.create("TableSpec"),
    ))
    |> module.function_call.add_with_alias(
      "table_name",
      module.identifier.create("table_name"),
    )
    |> module.function_call.add_with_alias(
      "query_string",
      module.identifier.create("query_string"),
    )
    |> module.function_call.add_with_alias(
      "query",
      module.identifier.create("query_node"),
    )
    |> module.function_call.add_with_alias(
      "id",
      module.function_definition.create()
        |> module.function_definition.add_parameter(
          "value",
          module_common.type_identifier(name),
        )
        |> module.function_definition.add(
          module.function_call.create(module.binop.access(
            module.identifier.create("identifier"),
            module.identifier.create("Identifier"),
          ))
          |> module.function_call.add(
            module.identifier.create("value")
            |> module.binop.access(module.identifier.create("id"))
            |> module.binop.access(module.identifier.create("type_")),
          )
          |> module.function_call.add(
            module.identifier.create("value")
            |> module.binop.access(module.identifier.create("id"))
            |> module.binop.access(module.identifier.create("id")),
          ),
        ),
    )
    |> module.function_call.add_with_alias(
      "to_surql",
      module.identifier.create("to_surql"),
    )
    |> module.function_call.add_with_alias(
      "to_json",
      module.identifier.create("to_json"),
    )
    |> module.function_call.add_with_alias(
      "serializer",
      module.identifier.create("decoder"),
    ),
  )
  |> module.add_import(["suweal", "table_spec"])
}

fn generate_offstage_table_specs(name: String) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.public()
  |> module.function_definition.with_name("specs")
  |> module.function_definition.with_return_type(
    module.function_call.create(module.binop.access(
      module.identifier.create("bs_table_spec"),
      module.identifier.create("TableSpec"),
    ))
    |> module.function_call.add(module_common.type_identifier(name)),
  )
  |> module.function_definition.add(
    module.function_call.create(module.binop.access(
      module.identifier.create("table_spec"),
      module.identifier.create("TableSpec"),
    ))
    |> module.function_call.add_with_alias(
      "table_name",
      module.identifier.create("table_name"),
    )
    |> module.function_call.add_with_alias(
      "query_string",
      module.identifier.create("query_string"),
    )
    |> module.function_call.add_with_alias(
      "query",
      module.identifier.create("query_node"),
    )
    |> module.function_call.add_with_alias(
      "id",
      module.function_definition.create()
        |> module.function_definition.add_parameter(
          "value",
          module_common.type_identifier(name),
        )
        |> module.function_definition.add(
          module.function_call.create(module.binop.access(
            module.identifier.create("identifier"),
            module.identifier.create("Identifier"),
          ))
          |> module.function_call.add(
            module.identifier.create("value")
            |> module.binop.access(module.identifier.create("id"))
            |> module.binop.access(module.identifier.create("type_")),
          )
          |> module.function_call.add(
            module.identifier.create("value")
            |> module.binop.access(module.identifier.create("id"))
            |> module.binop.access(module.identifier.create("id")),
          ),
        ),
    )
    |> module.function_call.add_with_alias(
      "to_surql",
      module.identifier.create("to_surql"),
    )
    |> module.function_call.add_with_alias(
      "to_json",
      module.identifier.create("to_json"),
    )
    |> module.function_call.add_with_alias(
      "serializer",
      module.identifier.create("serializer"),
    ),
  )
  |> module.add_aliased_import(
    ["offstage_suweal", "table_spec"],
    "bs_table_spec",
  )
  |> module.add_import(["suweal", "table_spec"])
}
