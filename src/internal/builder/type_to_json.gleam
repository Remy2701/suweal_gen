import common
import extractor
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import omcg/module
import omcg/module_common
import suweal/surreal_type.{type SurrealType}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                     Table Type `to_json`                                      //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_datetime_to_json(name: String) {
  module.function_call.create(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("string"),
  ))
  |> module.function_call.add(
    module.function_call.create(module.binop.access(
      module.identifier.create("timestamp"),
      module.identifier.create("to_rfc3339"),
    ))
    |> module.function_call.add(module.identifier.create(name))
    |> module.function_call.add(module.binop.access(
      module.identifier.create("calendar"),
      module.identifier.create("utc_offset"),
    )),
  )
  |> module.add_import(["gleam", "json"])
  |> module.add_import(["gleam", "time", "timestamp"])
  |> module.add_import(["gleam", "time", "calendar"])
}

fn generate_int_to_json(name: String) {
  module.function_call.create(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("int"),
  ))
  |> module.function_call.add(module.identifier.create(name))
  |> module.add_import(["gleam", "json"])
}

fn generate_float_to_json(name: String) {
  module.function_call.create(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("float"),
  ))
  |> module.function_call.add(module.identifier.create(name))
  |> module.add_import(["gleam", "json"])
}

fn generate_string_to_json(name: String) {
  module.function_call.create(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("string"),
  ))
  |> module.function_call.add(module.identifier.create(name))
  |> module.add_import(["gleam", "json"])
}

fn generate_identifier_to_json(name: String) {
  module.identifier.create(name)
  |> module.binop.pipe(module.binop.access(
    module.identifier.create("identifier"),
    module.identifier.create("to_string"),
  ))
  |> module.binop.pipe(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("string"),
  ))
  |> module.add_import(["gleam", "json"])
  |> module.add_import(["suweal", "identifier"])
}

fn generate_record_to_json(name: String, inner: String) {
  module.identifier.create(name)
  |> module.binop.pipe(
    module.function_call.create(module.binop.access(
      module.identifier.create("record"),
      module.identifier.create("to_json"),
    ))
    |> module.function_call.add(module.binop.access(
      module.identifier.create(
        string.split(inner, ".") |> list.first() |> result.unwrap(inner),
      ),
      module.identifier.create("to_json"),
    )),
  )
  |> module.add_import(["suweal", "record"])
}

fn generate_point_to_json(name: String) {
  module.function_call.create(module.binop.access(
    module.identifier.create("point"),
    module.identifier.create("to_json"),
  ))
  |> module.function_call.add(module.identifier.create(name))
  |> module.add_import(["suweal", "point"])
}

fn generate_bool_to_json(name: String) {
  module.function_call.create(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("bool"),
  ))
  |> module.function_call.add(module.identifier.create(name))
  |> module.add_import(["gleam", "json"])
}

fn generate_option_to_json(name: String, inner: SurrealType) {
  module.function_call.create(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("nullable"),
  ))
  |> module.function_call.add(module.identifier.create(name))
  |> module.function_call.add(
    module.function_definition.create()
    |> module.function_definition.add_untyped_parameter("value")
    |> module.function_definition.add(generate_to_json_for_type("value", inner)),
  )
  |> module.add_import(["gleam", "json"])
}

fn generate_array_to_json(name: String, inner: SurrealType) {
  module.function_call.create(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("array"),
  ))
  |> module.function_call.add(module.identifier.create(name))
  |> module.function_call.add(
    module.function_definition.create()
    |> module.function_definition.add_untyped_parameter("value")
    |> module.function_definition.add(generate_to_json_for_type("value", inner)),
  )
  |> module.add_import(["gleam", "json"])
}

fn generate_object_to_json(name: String) {
  module.function_call.create(module.binop.access(
    module.identifier.create("json_value"),
    module.identifier.create("to_json"),
  ))
  |> module.function_call.add(module.identifier.create(name))
  |> module.add_import(["json_value"])
}

fn generate_none_to_json() {
  module.function_call.create(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("null"),
  ))
  |> module.add_import(["gleam", "json"])
}

fn generate_to_json_for_type(
  name: String,
  type_: SurrealType,
) -> module.Module {
  case type_ {
    surreal_type.Int -> generate_int_to_json(name)
    surreal_type.Float -> generate_float_to_json(name)
    surreal_type.String -> generate_string_to_json(name)
    surreal_type.Bool -> generate_bool_to_json(name)
    surreal_type.Identifier(_) -> generate_identifier_to_json(name)
    surreal_type.Record(inner) -> generate_record_to_json(name, inner)
    surreal_type.Datetime -> generate_datetime_to_json(name)
    surreal_type.Point -> generate_point_to_json(name)
    surreal_type.Option(inner) -> generate_option_to_json(name, inner)
    surreal_type.Array(inner) -> generate_array_to_json(name, inner)
    surreal_type.Object -> generate_object_to_json(name)
    surreal_type.None -> generate_none_to_json()
  }
}

pub fn generate(
  config: common.Configuration,
  name: String,
  fields: List(extractor.TableField),
  prefix: String,
) -> module.Module {
  case config.offstage {
    True -> generate_offstage_type_to_json(name, prefix)
    False -> generate_gleam_type_to_json(name, fields, prefix)
  }
}

fn generate_offstage_type_to_json(
  name: String,
  prefix: String,
) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.public()
  |> module.function_definition.with_name(prefix <> "to_json")
  |> module.function_definition.add_parameter(
    "self",
    module_common.type_identifier(name),
  )
  |> module.function_definition.with_return_type(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("Json"),
  ))
  |> module.function_definition.add(
    module.binop.access(
      module.identifier.create("encode"),
      module.identifier.create("encode_json"),
    )
    |> module.function_call.create()
    |> module.function_call.add(module.identifier.create("self"))
    |> module.function_call.add(
      module.binop.access(
        module.identifier.create("serialize"),
        module.identifier.create("encoder"),
      )
      |> module.function_call.create()
      |> module.function_call.add(
        module.identifier.create(prefix <> "serializer")
        |> module.function_call.create(),
      )
      |> module.add_import(["offstage", "dynamic", "serialize"]),
    )
    |> module.add_import(["offstage", "dynamic", "encode"]),
  )
  |> module.add_import(["gleam", "json"])
}

fn generate_gleam_type_to_json(
  name: String,
  fields: List(extractor.TableField),
  prefix: String,
) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.public()
  |> module.function_definition.with_name(prefix <> "to_json")
  |> module.function_definition.add_parameter(
    "self",
    module_common.type_identifier(name),
  )
  |> module.function_definition.with_return_type(module.binop.access(
    module.identifier.create("json"),
    module.identifier.create("Json"),
  ))
  |> module.function_definition.add(
    module.function_call.create(module.binop.access(
      module.identifier.create("json"),
      module.identifier.create("object"),
    ))
    |> module.function_call.add(
      module.literal.list(
        list.map(fields, fn(field) {
          module.literal.tuple([
            module.literal.string(field.name),
            case field.linked_enum, field.object_fields, field.type_ {
              option.Some(enum), _, surreal_type.Option(_) ->
                module.function_call.create(module.binop.access(
                  module.identifier.create("json"),
                  module.identifier.create("nullable"),
                ))
                |> module.function_call.add(module.binop.access(
                  module.identifier.create("self"),
                  module.identifier.create(field.name),
                ))
                |> module.function_call.add(
                  module.function_definition.create()
                  |> module.function_definition.add_untyped_parameter("value")
                  |> module.function_definition.add(
                    module.function_call.create(module.binop.access(
                      module.identifier.create("json"),
                      module.identifier.create("string"),
                    ))
                    |> module.function_call.add(
                      module.function_call.create(module.identifier.create(
                        enum <> "_to_string",
                      ))
                      |> module.function_call.add(module.identifier.create(
                        "value",
                      )),
                    ),
                  ),
                )
              option.Some(enum), _, _ ->
                module.function_call.create(module.binop.access(
                  module.identifier.create("json"),
                  module.identifier.create("string"),
                ))
                |> module.function_call.add(
                  module.function_call.create(module.identifier.create(
                    enum <> "_to_string",
                  ))
                  |> module.function_call.add(module.binop.access(
                    module.identifier.create("self"),
                    module.identifier.create(field.name),
                  )),
                )
              _, [_, ..], surreal_type.Object ->
                module.function_call.create(module.identifier.create(
                  field.name <> "_to_json",
                ))
                |> module.function_call.add(module.identifier.create(
                  "self." <> field.name,
                ))
              _, [_, ..], surreal_type.Array(surreal_type.Object) ->
                module.function_call.create(module.binop.access(
                  module.identifier.create("json"),
                  module.identifier.create("array"),
                ))
                |> module.function_call.add(module.binop.access(
                  module.identifier.create("self"),
                  module.identifier.create(field.name),
                ))
                |> module.function_call.add(module.identifier.create(
                  field.name <> "_to_json",
                ))
              _, _, _ ->
                generate_to_json_for_type("self." <> field.name, field.type_)
            },
          ])
        }),
      ),
    ),
  )
  |> module.add_import(["gleam", "json"])
}
