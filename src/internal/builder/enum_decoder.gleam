import common
import gleam/list
import omcg/decode_module
import omcg/module
import omcg/module_common
import omcg/offstage_serialize_module

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                        Enum `decoder`                                         //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn generate(
  config: common.Configuration,
  name: String,
  values: List(String),
) -> module.Module {
  case config.offstage {
    True -> generate_enum_to_offstage_serializer(name, values)
    False -> generate_enum_to_gleam_decoder(name, values)
  }
}

fn generate_enum_to_gleam_decoder(
  name: String,
  values: List(String),
) -> module.Module {
  let assert [first, ..] = values

  module.function_definition.create()
  |> module.function_definition.with_name(name <> "_decoder")
  |> module.function_definition.public()
  |> module.function_definition.with_return_type(
    decode_module.decoder_of(module_common.type_identifier(name)),
  )
  |> module.function_definition.add(
    decode_module.string()
    |> decode_module.then()
    |> module.use_expression.create()
    |> module.use_expression.add("value"),
  )
  |> module.function_definition.add(
    module.case_expression.create(module.identifier.create("value"))
    |> list.fold(values, _, fn(module, value) {
      module
      |> module.case_expression.add(
        module.case_branch.create(module.literal.string(value))
        |> module.case_branch.add(
          decode_module.success_of(module_common.type_identifier(value)),
        ),
      )
    })
    |> module.case_expression.add(
      module.case_branch.create_default()
      |> module.case_branch.add(decode_module.failure_of(
        module_common.type_identifier(first),
        module.binop.string_concat(
          module.literal.string("Unknown value "),
          module.identifier.create("value"),
        ),
      )),
    ),
  )
  |> module.add_import(["gleam", "dynamic", "decode"])
}

fn generate_enum_to_offstage_serializer(
  name: String,
  values: List(String),
) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.with_name(name <> "_serializer")
  |> module.function_definition.public()
  |> module.function_definition.with_return_type(
    offstage_serialize_module.serializer_of(module_common.type_identifier(name)),
  )
  |> module.function_definition.add(offstage_serialize_module.string_enum_of(
    values
      |> list.map(module_common.type_identifier)
      |> module.literal.list(),
    module.identifier.create(name <> "_to_string"),
  ))
}
