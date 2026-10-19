import common
import extractor
import gleam/dict
import gleam/function
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import omcg/decode_module
import omcg/module
import omcg/module_common
import omcg/offstage_serialize_module
import omcg/option_module
import suweal/node
import suweal/surreal_type.{type SurrealType}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                     Table Type Definition                                     //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_type_definition_field(
  module: module.Module,
  field: extractor.TableField,
) {
  module
  |> module.type_variant.field(Some(field.name), case field.linked_enum {
    Some(enum) -> {
      let inner = case string.split_once(enum, ".") {
        Ok(#(module_str, name)) -> {
          module.binop.access(
            module.identifier.create(module_str),
            module.identifier.create(common.string_to_pascal_case(name)),
          )
        }
        _ -> {
          module.identifier.create(common.string_to_pascal_case(enum))
        }
      }

      case field.type_ {
        surreal_type.Option(_) -> option_module.type_(inner)
        _ -> inner
      }
    }
    None -> {
      case field.object_fields {
        [] -> surreal_type.to_gleam_type(field.type_)
        [_, ..] ->
          case field.type_ {
            surreal_type.Array(surreal_type.Object) -> {
              module.function_call.create(module.identifier.create("List"))
              |> module.function_call.add(
                common.string_to_pascal_case(field.name)
                |> module.identifier.create(),
              )
            }
            surreal_type.Object -> {
              module.identifier.create(common.string_to_pascal_case(field.name))
            }
            _ -> {
              io.println(
                "Warning: unsupported object field type for `"
                <> field.name
                <> "`: "
                <> module.to_string(surreal_type.to_gleam_type(field.type_)),
              )
              module.identifier.create(common.string_to_pascal_case(field.name))
            }
          }
      }
    }
  })
}

fn generate_type_definition(
  name: String,
  fields: List(extractor.TableField),
) -> module.Module {
  module.type_definition.create(common.string_to_pascal_case(name))
  |> module.type_definition.public()
  |> module.type_definition.add(
    module.type_variant.create(common.string_to_pascal_case(name))
    |> list.fold(fields, _, generate_type_definition_field),
  )
}

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

fn generate_type_to_json(
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
    module.identifier.create(common.string_to_pascal_case(name)),
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
    module.identifier.create(common.string_to_pascal_case(name)),
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

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                        Enum Definition                                        //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_enum_definition(
  name: String,
  values: List(String),
) -> module.Module {
  module.type_definition.create(common.string_to_pascal_case(name))
  |> module.type_definition.public()
  |> list.fold(values, _, fn(type_def, value) {
    module.type_definition.add(
      type_def,
      module.type_variant.create(common.string_to_pascal_case(value)),
    )
  })
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                       Enum `to_string`                                        //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_enum_to_string(
  name: String,
  values: List(String),
) -> module.Module {
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
        module.identifier.create(common.string_to_pascal_case(value))
          |> module.case_branch.create()
          |> module.case_branch.add(module.literal.string(value)),
      )
    }),
  )
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                        Enum `decoder`                                         //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_enum_to_decoder(
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

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                     Table Type `to_surql`                                     //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_to_surql_for_type(
  name: String,
  type_: SurrealType,
) -> module.Module {
  case type_ {
    surreal_type.Datetime ->
      module.function_call.create(module.binop.access(
        module.identifier.create("surreal_ql"),
        module.identifier.create("Datetime"),
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
      |> module.add_import(["gleam", "time", "timestamp"])
      |> module.add_import(["gleam", "time", "calendar"])
    surreal_type.Int ->
      module.function_call.create(module.binop.access(
        module.identifier.create("surreal_ql"),
        module.identifier.create("Int"),
      ))
      |> module.function_call.add(module.identifier.create(name))
    surreal_type.Float ->
      module.function_call.create(module.binop.access(
        module.identifier.create("surreal_ql"),
        module.identifier.create("Float"),
      ))
      |> module.function_call.add(module.identifier.create(name))
    surreal_type.String ->
      module.function_call.create(module.binop.access(
        module.identifier.create("surreal_ql"),
        module.identifier.create("String"),
      ))
      |> module.function_call.add(module.identifier.create(name))
    surreal_type.Identifier(_) ->
      module.identifier.create(name)
      |> module.binop.pipe(module.binop.access(
        module.identifier.create("identifier"),
        module.identifier.create("to_string"),
      ))
      |> module.binop.pipe(module.binop.access(
        module.identifier.create("surreal_ql"),
        module.identifier.create("String"),
      ))

    surreal_type.Record(inner) ->
      module.identifier.create(name)
      |> module.binop.pipe(
        module.function_call.create(module.binop.access(
          module.identifier.create("record"),
          module.identifier.create("to_surql"),
        ))
        |> module.function_call.add(
          module.identifier.create(
            string.split(inner, ".") |> list.first() |> result.unwrap(inner),
          )
          |> module.binop.access(module.identifier.create("to_surql")),
        ),
      )
    surreal_type.Point ->
      module.function_call.create(
        module.identifier.create("point")
        |> module.binop.access(module.identifier.create("to_surql")),
      )
      |> module.function_call.add(module.identifier.create(name))
    surreal_type.Bool ->
      module.function_call.create(
        module.identifier.create("surreal_ql")
        |> module.binop.access(module.identifier.create("Bool")),
      )
      |> module.function_call.add(module.identifier.create(name))
    surreal_type.Option(inner) ->
      module.function_call.create(
        module.identifier.create("surreal_ql")
        |> module.binop.access(module.identifier.create("nullable")),
      )
      |> module.function_call.add(module.identifier.create(name))
      |> module.function_call.add(
        module.function_definition.create()
        |> module.function_definition.add_untyped_parameter("value")
        |> module.function_definition.add(generate_to_surql_for_type(
          "value",
          inner,
        )),
      )
    surreal_type.Array(inner) ->
      module.function_call.create(
        module.identifier.create("surreal_ql")
        |> module.binop.access(module.identifier.create("array")),
      )
      |> module.function_call.add(module.identifier.create(name))
      |> module.function_call.add(
        module.function_definition.create()
        |> module.function_definition.add_untyped_parameter("value")
        |> module.function_definition.add(generate_to_surql_for_type(
          "value",
          inner,
        )),
      )
    surreal_type.Object ->
      module.function_call.create(
        module.identifier.create("surreal_ql")
        |> module.binop.access(module.identifier.create("from_json_value")),
      )
      |> module.function_call.add(module.identifier.create(name))
    surreal_type.None ->
      module.function_call.create(module.binop.access(
        module.identifier.create("surreal_ql"),
        module.identifier.create("Null"),
      ))
  }
}

fn generate_type_to_surql(
  name: String,
  fields: List(extractor.TableField),
  prefix: String,
) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.public()
  |> module.function_definition.with_name(prefix <> "to_surql")
  |> module.function_definition.add_parameter(
    "self",
    module.identifier.create(common.string_to_pascal_case(name)),
  )
  |> module.function_definition.with_return_type(
    module.identifier.create("surreal_ql")
    |> module.binop.access(module.identifier.create("SurrealQL")),
  )
  |> module.function_definition.add(
    module.function_call.create(module.binop.access(
      module.identifier.create("surreal_ql"),
      module.identifier.create("Object"),
    ))
    |> module.function_call.add(
      module.literal.list(
        list.map(
          list.filter(fields, fn(field) { field.name != "id" }),
          fn(field) {
            module.literal.tuple([
              module.literal.string(field.name),
              case field.linked_enum, field.object_fields, field.type_ {
                option.Some(enum), _, surreal_type.Option(_) ->
                  module.function_call.create(module.binop.access(
                    module.identifier.create("surreal_ql"),
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
                        module.identifier.create("surreal_ql"),
                        module.identifier.create("String"),
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
                    module.identifier.create("surreal_ql"),
                    module.identifier.create("String"),
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
                    field.name <> "_to_surql",
                  ))
                  |> module.function_call.add(module.identifier.create(
                    "self." <> field.name,
                  ))
                _, [_, ..], surreal_type.Array(surreal_type.Object) ->
                  module.function_call.create(module.binop.access(
                    module.identifier.create("surreal_ql"),
                    module.identifier.create("Array"),
                  ))
                  |> module.function_call.add(module.binop.access(
                    module.identifier.create("self"),
                    module.identifier.create(field.name),
                  ))
                  |> module.function_call.add(module.identifier.create(
                    field.name <> "_to_surql",
                  ))
                _, _, _ ->
                  generate_to_surql_for_type("self." <> field.name, field.type_)
              },
            ])
          },
        ),
      ),
    ),
  )
  |> module.add_import(["suweal", "surreal_ql"])
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                         Type Decoder                                          //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn decoder_of_datetime(config: common.Configuration) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_datetime()
    False -> gleam_decoder_of_datetime()
  }
}

fn offstage_serializer_of_datetime() -> module.Module {
  offstage_serialize_module.timestamp()
}

fn gleam_decoder_of_datetime() -> module.Module {
  decode_module.then(decode_module.string())
  |> module.function_call.add(
    module.function_definition.create()
    |> module.function_definition.add_untyped_parameter("str")
    |> module.function_definition.add(
      module.case_expression.create(
        module.function_call.create(module.binop.access(
          module.identifier.create("timestamp"),
          module.identifier.create("parse_rfc3339"),
        ))
        |> module.function_call.add(module.identifier.create("str")),
      )
      |> module.case_expression.add(
        module.case_branch.create(
          module.function_call.create(module.identifier.create("Ok"))
          |> module.function_call.add(module.identifier.create("time")),
        )
        |> module.case_branch.add(
          decode_module.success_of(module.identifier.create("time")),
        ),
      )
      |> module.case_expression.add(
        module.case_branch.create(
          module.function_call.create(module.identifier.create("Error"))
          |> module.function_call.add(module.identifier.discard),
        )
        |> module.case_branch.add(decode_module.failure_of(
          module.binop.access(
            module.identifier.create("timestamp"),
            module.identifier.create("unix_epoch"),
          ),
          module.binop.string_concat(
            module.literal.string("Failed to parse datetime: "),
            module.identifier.create("str"),
          ),
        )),
      ),
    ),
  )
  |> module.add_import(["gleam", "dynamic", "decode"])
  |> module.add_import(["gleam", "time", "timestamp"])
}

fn decoder_of_int(config: common.Configuration) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_int()
    False -> gleam_decoder_of_int()
  }
}

fn offstage_serializer_of_int() -> module.Module {
  offstage_serialize_module.int()
}

fn gleam_decoder_of_int() -> module.Module {
  module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("int"),
  )
  |> module.add_import(["gleam", "dynamic", "decode"])
}

fn decoder_of_float(config: common.Configuration) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_float()
    False -> gleam_decoder_of_float()
  }
}

fn offstage_serializer_of_float() -> module.Module {
  offstage_serialize_module.float()
}

fn gleam_decoder_of_float() -> module.Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("one_of"),
  ))
  |> module.function_call.add(module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("float"),
  ))
  |> module.function_call.add(
    module.literal.list([
      module.binop.pipe(
        module.binop.access(
          module.identifier.create("decode"),
          module.identifier.create("int"),
        ),
        module.function_call.create(module.binop.access(
          module.identifier.create("decode"),
          module.identifier.create("map"),
        ))
          |> module.function_call.add(module.binop.access(
            module.identifier.create("int"),
            module.identifier.create("to_float"),
          )),
      ),
    ]),
  )
  |> module.add_import(["gleam", "dynamic", "decode"])
  |> module.add_import(["gleam", "int"])
}

fn decoder_of_string(config: common.Configuration) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_string()
    False -> gleam_decoder_of_string()
  }
}

fn offstage_serializer_of_string() -> module.Module {
  offstage_serialize_module.string()
}

fn gleam_decoder_of_string() -> module.Module {
  module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("string"),
  )
  |> module.add_import(["gleam", "dynamic", "decode"])
}

fn decoder_of_identifier(
  config: common.Configuration,
  inner: String,
) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_identifier(inner)
    False -> gleam_decoder_of_identifier(inner)
  }
}

fn offstage_serializer_of_identifier(inner: String) -> module.Module {
  offstage_serialize_module.typed_identifier_of(
    module.literal.list([
      case string.split(inner, ".") {
        [table, _, ..] ->
          module.binop.access(
            module.identifier.create(table),
            module.identifier.create("table_name"),
          )
        _ -> module.identifier.create("table_name")
      },
    ]),
  )
}

fn gleam_decoder_of_identifier(inner: String) -> module.Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("identifier"),
    module.identifier.create("typed_decoder"),
  ))
  |> module.function_call.add(
    module.literal.list([
      case string.split(inner, ".") {
        [table, _, ..] ->
          module.binop.access(
            module.identifier.create(table),
            module.identifier.create("table_name"),
          )
        _ -> module.identifier.create("table_name")
      },
    ]),
  )
  |> module.add_import(["suweal", "identifier"])
}

fn decoder_of_record(
  config: common.Configuration,
  inner: String,
) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_record(inner)
    False -> gleam_decoder_of_record(inner)
  }
}

fn offstage_serializer_of_record(inner: String) -> module.Module {
  offstage_serialize_module.typed_record_of(
    module.function_call.create(module.binop.access(
      module.identifier.create(
        string.split(inner, ".") |> list.first() |> result.unwrap(inner),
      ),
      module.identifier.create("serializer"),
    )),
    module.function_definition.create()
      |> module.function_definition.add_untyped_parameter("data")
      |> module.function_definition.add(module.binop.access(
        module.identifier.create("data"),
        module.identifier.create("id"),
      )),
    module.literal.list([
      case string.split(inner, ".") {
        [table, _, ..] ->
          module.binop.access(
            module.identifier.create(table),
            module.identifier.create("table_name"),
          )
        _ -> module.identifier.create("table_name")
      },
    ]),
  )
}

fn gleam_decoder_of_record(inner: String) -> module.Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("record"),
    module.identifier.create("typed_decoder"),
  ))
  |> module.function_call.add(
    module.function_call.create(module.binop.access(
      module.identifier.create(
        string.split(inner, ".") |> list.first() |> result.unwrap(inner),
      ),
      module.identifier.create("decoder"),
    )),
  )
  |> module.function_call.add(
    module.function_definition.create()
    |> module.function_definition.add_untyped_parameter("data")
    |> module.function_definition.add(module.binop.access(
      module.identifier.create("data"),
      module.identifier.create("id"),
    )),
  )
  |> module.function_call.add(
    module.literal.list([
      case string.split(inner, ".") {
        [table, _, ..] ->
          module.binop.access(
            module.identifier.create(table),
            module.identifier.create("table_name"),
          )
        _ -> module.identifier.create("table_name")
      },
    ]),
  )
  |> module.add_import(["suweal", "record"])
}

fn decoder_of_bool(config: common.Configuration) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_bool()
    False -> gleam_decoder_of_bool()
  }
}

fn offstage_serializer_of_bool() -> module.Module {
  offstage_serialize_module.bool()
}

fn gleam_decoder_of_bool() -> module.Module {
  module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("bool"),
  )
  |> module.add_import(["gleam", "dynamic", "decode"])
}

fn decoder_of_point(config: common.Configuration) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_point()
    False -> gleam_decoder_of_point()
  }
}

fn offstage_serializer_of_point() -> module.Module {
  offstage_serialize_module.point()
}

fn gleam_decoder_of_point() -> module.Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("point"),
    module.identifier.create("decoder"),
  ))
  |> module.add_import(["suweal", "point"])
}

fn decoder_of_object(config: common.Configuration) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_object()
    False -> gleam_decoder_of_object()
  }
}

fn offstage_serializer_of_object() -> module.Module {
  offstage_serialize_module.json_value()
}

fn gleam_decoder_of_object() -> module.Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("json_value"),
    module.identifier.create("decoder"),
  ))
  |> module.add_import(["json_value"])
}

fn decoder_of_option(
  config: common.Configuration,
  inner: SurrealType,
) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_option(config, inner)
    False -> gleam_decoder_of_option(config, inner)
  }
}

fn offstage_serializer_of_option(
  config: common.Configuration,
  inner: SurrealType,
) -> module.Module {
  offstage_serialize_module.optional_of(decoder_of(config, inner))
}

fn gleam_decoder_of_option(
  config: common.Configuration,
  inner: SurrealType,
) -> module.Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("optional"),
  ))
  |> module.function_call.add(decoder_of(config, inner))
  |> module.add_import(["gleam", "dynamic", "decode"])
}

fn decoder_of_array(
  config: common.Configuration,
  inner: SurrealType,
) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_array(config, inner)
    False -> gleam_decoder_of_array(config, inner)
  }
}

fn offstage_serializer_of_array(
  config: common.Configuration,
  inner: SurrealType,
) -> module.Module {
  offstage_serialize_module.list_of(decoder_of(config, inner))
}

fn gleam_decoder_of_array(
  config: common.Configuration,
  inner: SurrealType,
) -> module.Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("list"),
  ))
  |> module.function_call.add(decoder_of(config, inner))
  |> module.add_import(["gleam", "dynamic", "decode"])
}

fn decoder_of_none(config: common.Configuration) -> module.Module {
  case config.offstage {
    True -> offstage_serializer_of_none()
    False -> gleam_decoder_of_none()
  }
}

fn offstage_serializer_of_none() -> module.Module {
  offstage_serialize_module.nil()
}

fn gleam_decoder_of_none() -> module.Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("success"),
  ))
  |> module.function_call.add(module.literal.nil)
  |> module.add_import(["gleam", "dynamic", "decode"])
}

fn decoder_of(
  config: common.Configuration,
  type_: SurrealType,
) -> module.Module {
  case type_ {
    surreal_type.Datetime -> decoder_of_datetime(config)
    surreal_type.Int -> decoder_of_int(config)
    surreal_type.Float -> decoder_of_float(config)
    surreal_type.String -> decoder_of_string(config)
    surreal_type.Identifier(inner) -> decoder_of_identifier(config, inner)
    surreal_type.Record(inner) -> decoder_of_record(config, inner)
    surreal_type.Bool -> decoder_of_bool(config)
    surreal_type.Point -> decoder_of_point(config)
    surreal_type.Object -> decoder_of_object(config)
    surreal_type.Option(inner) -> decoder_of_option(config, inner)
    surreal_type.Array(inner) -> decoder_of_array(config, inner)
    surreal_type.None -> decoder_of_none(config)
  }
}

fn generate_type_decoder(
  config: common.Configuration,
  name: String,
  fields: List(extractor.TableField),
  prefix: String,
) -> module.Module {
  case config.offstage {
    True -> offstage_generate_type_serializer(config, name, fields, prefix)
    False -> gleam_generate_type_decoder(config, name, fields, prefix)
  }
}

fn offstage_generate_type_serializer(
  config: common.Configuration,
  name: String,
  fields: List(extractor.TableField),
  prefix: String,
) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.with_name(prefix <> "serializer")
  |> module.function_definition.public()
  |> module.function_definition.with_return_type(
    offstage_serialize_module.serializer_of(module_common.type_identifier(name)),
  )
  |> module.function_definition.add(offstage_serialize_module.object_of(
    list.map(fields, fn(field) {
      let inner_serializer = case
        field.linked_enum,
        field.object_fields,
        field.type_
      {
        option.Some(enum), _, surreal_type.Option(_) -> {
          offstage_serialize_module.optional_of(
            module.function_call.create(module.identifier.create(
              enum <> "_serializer",
            )),
          )
        }
        option.Some(enum), _, _ ->
          module.function_call.create(module.identifier.create(
            enum <> "_serializer",
          ))
        _, [_, ..], surreal_type.Object ->
          module.function_call.create(module.identifier.create(
            field.name <> "_serializer",
          ))
        _, [_, ..], surreal_type.Array(surreal_type.Object) -> {
          offstage_serialize_module.list_of(
            module.function_call.create(module.identifier.create(
              field.name <> "_serializer",
            )),
          )
        }
        _, _, _ -> decoder_of(config, field.type_)
      }
      let inner_getter =
        module.function_definition.create()
        |> module.function_definition.add_parameter(
          "data",
          module_common.type_identifier(name),
        )
        |> module.function_definition.add(module.binop.access(
          module.identifier.create("data"),
          module.identifier.create(field.name),
        ))
      case field.type_ {
        surreal_type.Option(_) -> {
          module.use_expression.create(
            offstage_serialize_module.optional_field_of(
              module.identifier.create("context"),
              module.literal.string(field.name),
              option_module.none(),
              inner_serializer,
              inner_getter,
            ),
          )
        }
        _ -> {
          module.use_expression.create(offstage_serialize_module.field_of(
            module.identifier.create("context"),
            module.literal.string(field.name),
            inner_serializer,
            inner_getter,
          ))
        }
      }
      |> module.use_expression.add("context")
      |> module.use_expression.add(field.name)
    })
    |> list.append([
      offstage_serialize_module.build_of(
        module.identifier.create("context"),
        module_common.type_identifier(name)
          |> module.function_call.create()
          |> list.fold(fields, _, fn(module, field) {
            module.function_call.add_with_alias(
              module,
              field.name,
              module.identifier.create(field.name),
            )
          }),
      ),
    ]),
  ))
  |> module.add_import(["offstage", "dynamic", "serialize"])
}

fn gleam_generate_type_decoder(
  config: common.Configuration,
  name: String,
  fields: List(extractor.TableField),
  prefix: String,
) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.with_name(prefix <> "decoder")
  |> module.function_definition.public()
  |> module.function_definition.with_return_type(
    module.function_call.create(module.binop.access(
      module.identifier.create("decode"),
      module.identifier.create("Decoder"),
    ))
    |> module.function_call.add(
      module.identifier.create(common.string_to_pascal_case(name)),
    ),
  )
  |> list.fold(list.reverse(fields), _, fn(module, field) {
    module.use_expression.create(
      case field.type_ {
        surreal_type.Option(_) -> {
          module.function_call.create(module.binop.access(
            module.identifier.create("decode"),
            module.identifier.create("optional_field"),
          ))
          |> module.function_call.add(module.literal.string(field.name))
          |> module.function_call.add(module.binop.access(
            module.identifier.create("option"),
            module.identifier.create("None"),
          ))
        }
        _ -> {
          module.function_call.create(module.binop.access(
            module.identifier.create("decode"),
            module.identifier.create("field"),
          ))
          |> module.function_call.add(module.literal.string(field.name))
        }
      }
      |> module.function_call.add(
        case field.linked_enum, field.object_fields, field.type_ {
          option.Some(enum), _, surreal_type.Option(_) -> {
            module.function_call.create(module.binop.access(
              module.identifier.create("decode"),
              module.identifier.create("optional"),
            ))
            |> module.function_call.add(
              module.function_call.create(module.identifier.create(
                enum <> "_decoder",
              )),
            )
          }
          option.Some(enum), _, _ ->
            module.function_call.create(module.identifier.create(
              enum <> "_decoder",
            ))
          _, [_, ..], surreal_type.Object ->
            module.function_call.create(module.identifier.create(
              field.name <> "_decoder",
            ))
          _, [_, ..], surreal_type.Array(surreal_type.Object) -> {
            module.function_call.create(module.binop.access(
              module.identifier.create("decode"),
              module.identifier.create("list"),
            ))
            |> module.function_call.add(
              module.function_call.create(module.identifier.create(
                field.name <> "_decoder",
              )),
            )
          }
          _, _, _ -> decoder_of(config, field.type_)
        },
      ),
    )
    |> module.use_expression.add(field.name)
    |> module.function_definition.add(module, _)
  })
  |> module.function_definition.add(
    module.function_call.create(module.binop.access(
      module.identifier.create("decode"),
      module.identifier.create("success"),
    ))
    |> module.function_call.add(
      module.function_call.create(
        module.identifier.create(common.string_to_pascal_case(name)),
      )
      |> list.fold(fields, _, fn(module, field) {
        module
        |> module.function_call.add(module.identifier.create(field.name))
      }),
    ),
  )
  |> module.add_import(["gleam", "dynamic", "decode"])
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                         Dependencies                                          //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn retrieve_dependencies_(
  fields: List(extractor.TableField),
  tables: dict.Dict(String, extractor.TableInfo),
) -> set.Set(String) {
  list.fold(fields, set.new(), fn(acc, field) {
    let acc = case field.type_ {
      surreal_type.Datetime -> acc |> set.insert("gleam/time/timestamp")
      surreal_type.Option(surreal_type.Datetime) -> acc
      surreal_type.Identifier(name) ->
        acc
        |> case
          dict.get(
            tables,
            common.string_to_snake_case(common.without_namespace(name)),
          )
        {
          Ok(info) -> set.insert(_, info.path |> string.remove_prefix("./src/"))
          _ -> function.identity
        }
      surreal_type.Record(name) ->
        acc
        |> set.insert("suweal/record")
        |> case
          dict.get(
            tables,
            common.string_to_snake_case(common.without_namespace(name)),
          )
        {
          Ok(info) -> set.insert(_, info.path |> string.remove_prefix("./src/"))
          _ -> function.identity
        }
      surreal_type.Option(_) -> acc
      surreal_type.Object -> acc
      surreal_type.Point -> acc
      _ -> acc
    }

    list.fold(field.object_fields, acc, fn(acc, field) {
      retrieve_dependencies_([field], tables)
      |> set.union(acc)
    })
  })
}

fn retrieve_dependencies(
  module: module.Module,
  fields: List(extractor.TableField),
  tables: dict.Dict(String, extractor.TableInfo),
) -> module.Module {
  list.fold(fields, module, fn(module, field) {
    let module = case field.type_ {
      surreal_type.Datetime ->
        module.add_import(module, ["gleam", "time", "timestamp"])
      surreal_type.Option(surreal_type.Datetime) ->
        module
        |> module.add_import(["gleam", "option"])
        |> module.add_import(["gleam", "time", "timestamp"])
      surreal_type.Identifier(name) ->
        module
        |> case
          dict.get(
            tables,
            common.string_to_snake_case(common.without_namespace(name)),
          )
        {
          Ok(info) -> module.add_import(
            _,
            info.path |> string.remove_prefix("./src/") |> string.split("/"),
          )
          _ -> function.identity
        }
      surreal_type.Record(name) ->
        module
        |> module.add_import(["suweal", "record"])
        |> case
          dict.get(
            tables,
            common.string_to_snake_case(common.without_namespace(name)),
          )
        {
          Ok(info) -> module.add_import(
            _,
            info.path |> string.remove_prefix("./src/") |> string.split("/"),
          )
          _ -> function.identity
        }
      surreal_type.Option(_) -> module
      surreal_type.Object -> module
      surreal_type.Point -> module
      _ -> module
    }

    list.fold(field.object_fields, module, fn(module, field) {
      retrieve_dependencies(module, [field], tables)
    })
  })
}

fn resolve_dependencies(
  module: module.Module,
  fields: List(extractor.TableField),
  tables: dict.Dict(String, extractor.TableInfo),
) -> #(module.Module, List(extractor.TableField)) {
  list.fold(fields, #(module, []), fn(acc, field) {
    let #(module, fields) = acc

    let #(module, fields) = case field.type_ {
      surreal_type.Datetime -> #(module, list.append(fields, [field]))
      surreal_type.Option(surreal_type.Datetime) -> #(
        module
          |> module.add_import(["gleam", "option"]),
        list.append(fields, [field]),
      )
      surreal_type.Identifier(_) -> #(
        module.add_import(module, ["suweal", "identifier"]),
        list.append(fields, [field]),
      )
      surreal_type.Record(name) -> {
        let table = dict.get(tables, string.lowercase(name))

        let module = module.add_import(module, ["suweal", "record"])
        let module = case table {
          Ok(info) ->
            module.add_import(
              module,
              info.path |> string.remove_prefix("./src/") |> string.split("/"),
            )
          _ -> module
        }

        #(
          module,
          list.append(fields, [
            extractor.TableField(..field, type_: case table {
              Ok(info) ->
                surreal_type.Record(
                  info.path
                  |> string.split("/")
                  |> list.last()
                  |> result.unwrap("??")
                  <> "."
                  <> common.string_to_pascal_case(name),
                )
              _ -> field.type_
            }),
          ]),
        )
      }
      surreal_type.Array(surreal_type.Record(name)) -> {
        let table = dict.get(tables, string.lowercase(name))

        let module = module.add_import(module, ["suweal", "record"])
        let module = case table {
          Ok(info) ->
            module.add_import(
              module,
              info.path |> string.remove_prefix("./src/") |> string.split("/"),
            )
          _ -> module
        }

        #(
          module,
          list.append(fields, [
            extractor.TableField(..field, type_: case table {
              Ok(info) ->
                surreal_type.Array(surreal_type.Record(
                  info.path
                  |> string.split("/")
                  |> list.last()
                  |> result.unwrap("??")
                  <> "."
                  <> common.string_to_pascal_case(name),
                ))
              _ -> field.type_
            }),
          ]),
        )
      }
      surreal_type.Option(surreal_type.Record(name)) -> {
        let table = dict.get(tables, string.lowercase(name))

        let module = module.add_import(module, ["suweal", "record"])
        let module = case table {
          Ok(info) ->
            module.add_import(
              module,
              info.path |> string.remove_prefix("./src/") |> string.split("/"),
            )
          _ -> module
        }

        #(
          module,
          list.append(fields, [
            extractor.TableField(..field, type_: case table {
              Ok(info) ->
                surreal_type.Option(surreal_type.Record(
                  info.path
                  |> string.split("/")
                  |> list.last()
                  |> result.unwrap("??")
                  <> "."
                  <> common.string_to_pascal_case(name),
                ))
              _ -> field.type_
            }),
          ]),
        )
      }
      surreal_type.Option(_) -> #(
        module.add_import(module, ["gleam", "option"]),
        list.append(fields, [field]),
      )
      surreal_type.Object -> #(
        module.add_import(module, ["json_value"]),
        list.append(fields, [field]),
      )
      surreal_type.Point -> #(
        module.add_import(module, ["suweal", "point"]),
        list.append(fields, [field]),
      )
      _ -> #(module, list.append(fields, [field]))
    }

    let module =
      list.fold(field.object_fields, module, fn(module, field) {
        retrieve_dependencies(module, [field], tables)
      })

    #(module, fields)
  })
}

fn link_type(
  tables: dict.Dict(String, extractor.TableInfo),
  current: extractor.TableInfo,
  field: extractor.TableField,
) {
  ResolveTableFieldsResult(
    field: extractor.TableField(
      dependencies: field.dependencies,
      name: field.name,
      type_: case field.type_ {
        surreal_type.Int
        | surreal_type.Float
        | surreal_type.Bool
        | surreal_type.String
        | surreal_type.Datetime
        | surreal_type.None -> field.type_
        surreal_type.Identifier(inner) ->
          surreal_type.Identifier(
            common.namespace_of(current.path)
            <> "."
            <> common.string_to_pascal_case(inner),
          )
        surreal_type.Record(inner) ->
          case common.compare(current.name, common.identify_case(inner), True) {
            order.Eq ->
              surreal_type.Record(
                common.namespace_of(current.path)
                <> "."
                <> common.string_to_pascal_case(inner),
              )
            _ -> {
              let current = dict.get(tables, string.lowercase(inner))

              case current {
                Ok(current) ->
                  surreal_type.Record(
                    common.namespace_of(current.path)
                    <> "."
                    <> common.string_to_pascal_case(inner),
                  )
                _ -> {
                  io.println(
                    "Warning: Could not resolve table `" <> inner <> "`",
                  )
                  field.type_
                }
              }
            }
          }
        surreal_type.Option(_) -> field.type_
        surreal_type.Array(_) -> field.type_
        surreal_type.Point -> field.type_
        surreal_type.Object -> field.type_
      },
      linked_enum: option.map(field.linked_enum, fn(enum) {
        case string.contains(enum, ".") {
          False -> common.namespace_of(current.path) <> "." <> enum
          True -> enum
        }
      }),
      object_fields: field.object_fields,
    ),
    dependencies: case field.type_ {
      surreal_type.Identifier(inner) ->
        case common.compare(current.name, common.identify_case(inner), True) {
          order.Eq -> set.from_list([common.to_gleam_path(current.path)])
          _ -> {
            let current = dict.get(tables, string.lowercase(inner))

            case current {
              Ok(current) ->
                set.from_list([
                  common.to_gleam_path(current.path),
                ])
              _ -> {
                io.println("Warning: Could not resolve table `" <> inner <> "`")
                set.new()
              }
            }
          }
        }
      surreal_type.Record(inner) ->
        case common.compare(current.name, common.identify_case(inner), True) {
          order.Eq -> set.from_list([common.to_gleam_path(current.path)])
          _ -> {
            let current = dict.get(tables, string.lowercase(inner))

            case current {
              Ok(current) ->
                set.from_list([
                  common.to_gleam_path(current.path),
                  "suweal/record",
                ])
              _ -> {
                io.println("Warning: Could not resolve table `" <> inner <> "`")
                set.new()
              }
            }
          }
        }
      _ -> set.new()
    },
  )
}

type ResolveTableFieldsResult {
  ResolveTableFieldsResult(
    field: extractor.TableField,
    dependencies: set.Set(String),
  )
}

fn add_dependencies(
  result: ResolveTableFieldsResult,
  dependencies: set.Set(String),
) {
  ResolveTableFieldsResult(
    ..result,
    dependencies: set.union(result.dependencies, dependencies),
  )
}

fn generate_nest_field(
  config: common.Configuration,
  field: extractor.TableField,
) -> Result(module.Module, Nil) {
  case field.object_fields {
    [] -> Error(Nil)
    fields -> {
      let name = common.string_to_space_case(field.name)
      let module =
        module.root.create()
        |> list.fold(
          fields |> list.filter_map(generate_nest_field(config, _)),
          _,
          module.root.add,
        )
        |> module.root.add(module.section_comment(name))
        |> module.root.add(generate_type_definition(field.name, fields))
        |> module.root.add(generate_type_decoder(
          config,
          field.name,
          fields,
          field.name <> "_",
        ))
        |> module.root.add(generate_type_to_json(
          config,
          field.name,
          fields,
          field.name <> "_",
        ))
        |> module.root.add(generate_type_to_surql(
          field.name,
          fields,
          field.name <> "_",
        ))

      Ok(module)
    }
  }
}

fn resolve_table_fields(
  tables: dict.Dict(String, extractor.TableInfo),
  current: extractor.TableInfo,
  node: node.Node,
) -> Result(ResolveTableFieldsResult, _) {
  case node {
    node.Identifier(name) ->
      current.fields
      |> list.find(fn(f) { f.name == name })
      |> result.map(link_type(tables, current, _))
    node.WrappedNode(inner) -> resolve_table_fields(tables, current, inner)
    node.Self ->
      Ok(ResolveTableFieldsResult(
        field: extractor.TableField(
          dependencies: [],
          name: "self",
          type_: surreal_type.Record(common.to_pascal_case(current.name).value),
          linked_enum: option.None,
          object_fields: [],
        ),
        dependencies: set.new(),
      ))
    node.Object(fields) -> {
      use resolved_fields <- result.try(
        list.try_map(fields, fn(field) {
          use resolved <- result.try(resolve_table_fields(
            tables,
            current,
            field.1,
          ))

          Ok(
            ResolveTableFieldsResult(
              ..resolved,
              field: extractor.TableField(..resolved.field, name: field.0),
            ),
          )
        }),
      )

      Ok(ResolveTableFieldsResult(
        extractor.TableField(
          dependencies: [],
          name: node.to_string(node),
          type_: surreal_type.Object,
          linked_enum: option.None,
          object_fields: list.map(resolved_fields, fn(result) { result.field }),
        ),
        dependencies: list.map(resolved_fields, fn(result) {
          result.dependencies
        })
          |> list.fold(set.new(), set.union),
      ))
    }
    node.BinaryOperator(lhs:, operator:, rhs:) -> {
      use resolved_lhs <- result.try(
        resolve_table_fields(tables, current, lhs)
        |> result.map_error(fn(_) {
          io.println(
            "Warning: failed to resolve left-hand side of binary operator: "
            <> node.to_string(lhs),
          )
        }),
      )

      case operator {
        node.RelationTo | node.RelationFrom | node.RelationToFrom -> {
          case rhs {
            node.Identifier(relation) ->
              case dict.get(tables, relation) {
                Ok(table) ->
                  Ok(ResolveTableFieldsResult(
                    field: extractor.TableField(
                      dependencies: [],
                      name: relation,
                      type_: surreal_type.Array(surreal_type.Record(
                        common.namespace_of(table.path)
                        <> "."
                        <> common.to_pascal_case(table.name).value,
                      )),
                      linked_enum: option.None,
                      object_fields: [],
                    ),
                    dependencies: resolved_lhs.dependencies,
                  ))
                _ -> {
                  io.println(
                    "Warning: unknown table for relation operator: " <> relation,
                  )
                  Error(Nil)
                }
              }
            _ -> {
              io.println(
                "Warning: unsupported right-hand side for relation operator: "
                <> node.to_string(rhs),
              )
              Error(Nil)
            }
          }
        }
        node.Access ->
          case resolved_lhs.field.type_ {
            surreal_type.Array(surreal_type.Record(inner)) -> {
              use table <- result.try(dict.get(
                tables,
                common.without_namespace(inner),
              ))

              resolve_table_fields(tables, table, rhs)
              |> result.map(fn(result) {
                ResolveTableFieldsResult(
                  ..result,
                  field: extractor.TableField(
                    ..result.field,
                    type_: surreal_type.Array(result.field.type_),
                  ),
                )
                |> add_dependencies(resolved_lhs.dependencies)
              })
            }
            surreal_type.Option(surreal_type.Record(inner)) -> {
              use table <- result.try(dict.get(
                tables,
                common.without_namespace(inner),
              ))

              resolve_table_fields(tables, table, rhs)
              |> result.map(fn(result) {
                ResolveTableFieldsResult(
                  ..result,
                  field: extractor.TableField(
                    ..result.field,
                    type_: surreal_type.Option(result.field.type_),
                  ),
                )
                |> add_dependencies(resolved_lhs.dependencies)
              })
            }
            surreal_type.Record(inner) -> {
              use table <- result.try(dict.get(
                tables,
                common.string_to_snake_case(common.without_namespace(inner)),
              ))

              resolve_table_fields(tables, table, rhs)
              |> result.map(add_dependencies(_, resolved_lhs.dependencies))
            }
            _ -> {
              io.println(
                "Warning: unsupported left-hand side for access operator: "
                <> node.to_string(lhs),
              )
              Error(Nil)
            }
          }
        node.Indexing -> {
          case resolved_lhs.field.type_ {
            surreal_type.Array(inner) ->
              Ok(ResolveTableFieldsResult(
                field: extractor.TableField(
                  dependencies: resolved_lhs.field.dependencies,
                  name: node.to_string(node),
                  type_: inner,
                  linked_enum: resolved_lhs.field.linked_enum,
                  object_fields: resolved_lhs.field.object_fields,
                ),
                dependencies: resolved_lhs.dependencies,
              ))
            _ -> {
              io.println(
                "Warning: indexing of non array type `"
                <> node.to_string(lhs)
                <> "`",
              )
              Error(Nil)
            }
          }
        }
        _ -> {
          io.println(
            "Warning: unsupported operator '"
            <> string.inspect(operator)
            <> "' for field resolution: "
            <> node.to_string(node),
          )
          Error(Nil)
        }
      }
    }
    node.Array(elements) -> {
      use resolved <- result.try(
        list.try_map(elements, fn(element) {
          use resolved <- result.try(resolve_table_fields(
            tables,
            current,
            element,
          ))

          Ok(
            ResolveTableFieldsResult(
              ..resolved,
              field: extractor.TableField(
                ..resolved.field,
                name: node.to_string(element),
              ),
            ),
          )
        }),
      )

      let types = list.map(resolved, fn(e) { e.field.type_ }) |> list.unique()
      case types {
        [] -> {
          io.println(
            "Warning: no type resolved for `" <> node.to_string(node) <> "`",
          )
          Error(Nil)
        }
        [value] ->
          Ok(ResolveTableFieldsResult(
            extractor.TableField(
              dependencies: [],
              name: node.to_string(node),
              type_: surreal_type.Array(value),
              linked_enum: option.None,
              object_fields: [],
            ),
            dependencies: list.map(resolved, fn(it) { it.dependencies })
              |> list.fold(set.new(), set.union),
          ))
        _ -> {
          io.println(
            "Warning: multiple types resolved for `"
            <> node.to_string(node)
            <> "`: "
            <> string.inspect(
              list.map(types, fn(t) {
                module.to_string(surreal_type.to_gleam_type(t))
              }),
            ),
          )
          Error(Nil)
        }
      }
    }
    node.FunctionCall(lhs:, rhs:, arguments:) -> {
      case lhs, rhs {
        option.None, "count" -> {
          Ok(ResolveTableFieldsResult(
            field: extractor.TableField(
              dependencies: [],
              name: "count",
              type_: surreal_type.Int,
              linked_enum: option.None,
              object_fields: [],
            ),
            dependencies: set.new(),
          ))
        }
        option.Some("array"), "complement" -> {
          case arguments {
            [first, ..] -> {
              use resolved <- result.try(resolve_table_fields(
                tables,
                current,
                first,
              ))

              Ok(ResolveTableFieldsResult(
                field: extractor.TableField(
                  ..resolved.field,
                  name: node.to_string(node),
                ),
                dependencies: resolved.dependencies,
              ))
            }
            _ -> {
              io.println(
                "Warning: calling array::complement with no arguments: "
                <> node.to_string(node),
              )
              Error(Nil)
            }
          }
        }
        _, _ -> {
          io.println(
            "Warning: unsupported function call for field resolution: "
            <> node.to_string(node),
          )
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println(
        "Warning: unsupported node type for field resolution: "
        <> node.to_string(node),
      )
      Error(Nil)
    }
  }
}

pub type ParameterProperty {
  ParameterProperty(
    name: String,
    type_: SurrealType,
    linked_enum: option.Option(String),
    dependencies: List(String),
  )
}

fn pick_field(
  fields: List(extractor.TableField),
  node: node.Node,
) -> Result(extractor.TableField, Nil) {
  case node {
    node.Identifier(name) -> list.find(fields, fn(f) { f.name == name })
    node.BinaryOperator(lhs: lhs, operator: node.Access, rhs: rhs) ->
      pick_field(fields, lhs)
      |> result.try(fn(field) { pick_field(field.object_fields, rhs) })
    _ -> Error(Nil)
  }
}

fn extract_parameters(
  node: node.Node,
  expected_type: Result(SurrealType, Nil),
  table_info: extractor.TableInfo,
  tables: dict.Dict(String, extractor.TableInfo),
  namespace: String,
) {
  case node {
    node.BinaryOperator(
      lhs: node.Parameter(name),
      operator: node.Equal,
      rhs: node.None,
    ) -> {
      Ok([
        ParameterProperty(
          name: name,
          type_: surreal_type.Option(surreal_type.None),
          linked_enum: option.None,
          dependencies: [],
        ),
      ])
    }
    node.BinaryOperator(lhs:, operator: node.Equal, rhs:)
    | node.BinaryOperator(lhs:, operator: node.GreaterThan, rhs:)
    | node.BinaryOperator(lhs:, operator: node.GreaterThanOrEqual, rhs:)
    | node.BinaryOperator(lhs:, operator: node.LessThan, rhs:)
    | node.BinaryOperator(lhs:, operator: node.LessThanOrEqual, rhs:) ->
      case rhs {
        node.Parameter(name) -> {
          // Figure out the type of the lhs and add it to the parameters list
          pick_field(table_info.fields, lhs)
          |> result.map(fn(f) {
            case f.name == "id", f.type_ {
              True, surreal_type.Identifier(identifier_name) ->
                case string.contains(identifier_name, ".") {
                  True ->
                    ParameterProperty(
                      name: name,
                      type_: f.type_,
                      linked_enum: option.None,
                      dependencies: [],
                    )
                  _ ->
                    ParameterProperty(
                      name: name,
                      type_: surreal_type.Identifier(
                        namespace <> "." <> identifier_name,
                      ),
                      linked_enum: option.None,
                      dependencies: [],
                    )
                }
              _, surreal_type.Record(record_name) ->
                case dict.get(tables, record_name) {
                  Ok(info) ->
                    ParameterProperty(
                      name: name,
                      type_: surreal_type.Identifier(
                        common.namespace_of(info.path)
                        <> "."
                        <> common.string_to_pascal_case(record_name),
                      ),
                      linked_enum: option.None,
                      dependencies: [],
                    )
                  _ ->
                    ParameterProperty(
                      name: name,
                      type_: surreal_type.Identifier(name),
                      linked_enum: option.None,
                      dependencies: [],
                    )
                }
              _, surreal_type.String ->
                ParameterProperty(
                  name: name,
                  type_: surreal_type.String,
                  linked_enum: option.map(f.linked_enum, fn(enum) {
                    case string.contains(enum, ".") {
                      False ->
                        namespace <> "." <> common.string_to_pascal_case(enum)
                      True -> enum
                    }
                  }),
                  dependencies: f.dependencies,
                )
              _, surreal_type.Option(surreal_type.String) ->
                ParameterProperty(
                  name: name,
                  type_: surreal_type.Option(surreal_type.String),
                  linked_enum: option.map(f.linked_enum, fn(enum) {
                    case string.contains(enum, ".") {
                      False ->
                        namespace <> "." <> common.string_to_pascal_case(enum)
                      True -> enum
                    }
                  }),
                  dependencies: f.dependencies,
                )
              _, _ ->
                ParameterProperty(
                  name: name,
                  type_: f.type_,
                  linked_enum: option.None,
                  dependencies: [],
                )
            }
          })
          |> result.unwrap(
            ParameterProperty(
              name: name,
              type_: surreal_type.Object,
              linked_enum: option.None,
              dependencies: [],
            ),
          )
          |> list.wrap()
          |> Ok
        }
        _ -> Error(Nil)
      }
    node.BinaryOperator(lhs:, operator: node.And, rhs:)
    | node.BinaryOperator(lhs:, operator: node.Or, rhs:) ->
      [
        extract_parameters(lhs, Error(Nil), table_info, tables, namespace),
        extract_parameters(rhs, Error(Nil), table_info, tables, namespace),
      ]
      |> list.filter_map(function.identity)
      |> list.flatten()
      |> Ok
    node.Parameter(name) ->
      case expected_type {
        Ok(type_) ->
          Ok([
            ParameterProperty(
              name: name,
              type_: type_,
              linked_enum: option.None,
              dependencies: [],
            ),
          ])
        _ -> Error(Nil)
      }
    node.WrappedNode(inner) ->
      extract_parameters(inner, expected_type, table_info, tables, namespace)
    _ -> Error(Nil)
  }
}

fn complete_parameter_extraction(
  parameters: List(ParameterProperty),
) -> List(ParameterProperty) {
  list.fold(parameters, [], fn(acc: List(ParameterProperty), param) {
    case list.find(acc, fn(item) { item.name == param.name }) {
      Ok(property) ->
        list.filter(acc, fn(p) { p.name != param.name })
        |> list.append([
          ParameterProperty(..param, type_: case property.type_, param.type_ {
            surreal_type.Option(surreal_type.None), surreal_type.Option(inner)
            -> surreal_type.Option(inner)
            surreal_type.Option(surreal_type.None), inner ->
              surreal_type.Option(inner)
            surreal_type.Option(inner), surreal_type.Option(surreal_type.None)
            -> surreal_type.Option(inner)
            inner, surreal_type.Option(surreal_type.None) ->
              surreal_type.Option(inner)
            a, b if a == b -> a
            _, _ -> param.type_
          }),
        ])
      Error(_) -> list.append(acc, [param])
    }
  })
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                          Table Spec                                           //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_table_specs(
  config: common.Configuration,
  name: String,
) -> module.Module {
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
    |> module.function_call.add(
      module.identifier.create(common.string_to_pascal_case(name)),
    ),
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
          module.identifier.create(common.string_to_pascal_case(name)),
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
    |> module.function_call.add(
      module.identifier.create(common.string_to_pascal_case(name)),
    ),
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
          module.identifier.create(common.string_to_pascal_case(name)),
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

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                          Parameters                                           //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_parameters_builder(
  parameters: List(ParameterProperty),
) -> module.Module {
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

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             Query                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_query_builder(
  parameters: List(ParameterProperty),
  result_type: String,
  prefix: option.Option(String),
  operation_type: String,
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
        |> module.function_call.add(
          module.function_call.create(module.identifier.create("List"))
          |> module.function_call.add(module.identifier.create(result_type)),
        )
        |> module.function_call.add(option_module.type_(
          module.function_call.create(module.identifier.create("List"))
          |> module.function_call.add(module.identifier.create(result_type)),
        )),
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
        module.identifier.create(operation_type),
      ),
    )
    |> module.function_call.add_with_alias(
      "query",
      module.identifier.create("query_node"),
    )
    |> module.function_call.add_with_alias(
      "serializer",
      offstage_serialize_module.list_of(
        module.function_call.create(module.identifier.create("serializer")),
      ),
    )
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

fn do_define_normal_table_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.DefineTable(name:, as_:, ..) = node
  use info <- result.try(
    dict.get(tables, name)
    |> result.replace_error("Unknown table for field: " <> name),
  )

  let module =
    module.root.create()
    |> list.fold(
      info.fields
        |> list.filter_map(generate_nest_field(config, _)),
      _,
      module.root.add,
    )
    |> module.root.add(
      module.const_definition.create("table_name", module.literal.string(name))
      |> module.const_definition.public(),
    )
    |> list.fold(info.enums, _, fn(module, entry) {
      let #(enum_name, values) = entry
      module
      |> module.root.add(generate_enum_definition(enum_name, values))
      |> module.root.add(generate_enum_to_string(enum_name, values))
      |> module.root.add(generate_enum_to_decoder(config, enum_name, values))
    })

  let #(module, fields) = resolve_dependencies(module, info.fields, tables)

  let module =
    module
    |> module.root.add(
      module.section_comment(common.string_to_space_case(name)),
    )
    |> module.root.add(generate_type_definition(name, fields))
    |> module.root.add(generate_type_decoder(config, name, fields, ""))
    |> module.root.add(generate_type_to_json(config, name, fields, ""))
    |> module.root.add(generate_type_to_surql(name, fields, ""))
    |> module.root.add(generate_table_specs(config, name))

  let module = case as_, list.find(info.fields, fn(f) { f.name == "id" }) {
    option.Some(_),
      Ok(extractor.TableField(type_: surreal_type.Identifier(name), ..))
    -> {
      case
        dict.get(
          tables,
          string.lowercase(
            string.split(name, ".") |> list.last() |> result.unwrap(""),
          ),
        )
      {
        Ok(info) ->
          module.add_import(
            module,
            info.path
              |> string.remove_prefix("./src/")
              |> string.split("/"),
          )
        _ -> module
      }
    }
    _, _ -> module
  }

  Ok(module)
}

fn do_define_relation_table_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.DefineTable(name:, ..) = node
  use info <- result.try(
    dict.get(tables, name)
    |> result.replace_error("Unknown table for field: " <> name),
  )

  let module = module.root.create()

  // Generate `table_name` constant
  let module =
    module
    |> module.root.add(
      module.const_definition.create("table_name", module.literal.string(name))
      |> module.const_definition.public(),
    )

  // Generate enum definitions, `to_string` functions and decoders
  let module =
    list.fold(info.enums, module, fn(module, entry) {
      let #(enum_name, values) = entry
      module
      |> module.root.add(generate_enum_definition(enum_name, values))
      |> module.root.add(generate_enum_to_string(enum_name, values))
      |> module.root.add(generate_enum_to_decoder(config, enum_name, values))
    })

  let #(module, fields) = resolve_dependencies(module, info.fields, tables)

  // Generate table type definition, decoder, `to_json` and `to_surql` functions
  let module =
    module
    |> module.root.add(
      module.section_comment(common.string_to_space_case(name)),
    )
    |> module.root.add(generate_type_definition(name, fields))
    |> module.root.add(generate_type_decoder(config, name, fields, ""))
    |> module.root.add(generate_type_to_json(config, name, fields, ""))
    |> module.root.add(generate_type_to_surql(name, fields, ""))
    |> module.root.add(generate_table_specs(config, name))

  Ok(module)
}

fn do_select_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.Select(fields:, table:, where:, limit:, ..) = node
  use table_info <- result.try(
    dict.get(tables, table)
    |> result.replace_error("Unknown table for select: " <> table),
  )

  let path =
    result.unwrap(string.split_once(table_info.path, "src/"), #("", "")).1
  let path = string.split(path, "/")
  let namespace = list.last(path) |> result.unwrap("")

  let module = case fields {
    [node.SelectField(field: node.All, ..)] -> {
      let module =
        module.root.create()
        |> module.root.add(module.section_comment("Query result"))
        |> module.root.add(
          module.const_definition.create(
            "QueryResult",
            module.binop.access(
              module.identifier.create(namespace),
              module.identifier.create(common.string_to_pascal_case(table)),
            ),
          )
          |> module.const_definition.public()
          |> module.const_definition.as_type(),
        )
        |> module.root.add(
          module.const_definition.create(
            "to_json",
            module.binop.access(
              module.identifier.create(namespace),
              module.identifier.create("to_json"),
            ),
          )
          |> module.const_definition.public(),
        )

      let module = case config.offstage {
        True ->
          module
          |> module.root.add(
            module.const_definition.create(
              "serializer",
              module.binop.access(
                module.identifier.create(namespace),
                module.identifier.create("serializer"),
              ),
            )
            |> module.const_definition.public(),
          )
        False ->
          module
          |> module.root.add(
            module.const_definition.create(
              "decoder",
              module.binop.access(
                module.identifier.create(namespace),
                module.identifier.create("decoder"),
              ),
            )
            |> module.const_definition.public(),
          )
      }

      let dependencies =
        set.from_list([path |> string.join("/")])
        |> set.union(
          list.flat_map(table_info.fields, fn(f) { f.dependencies })
          |> set.from_list,
        )

      let module =
        dependencies
        |> set.to_list()
        |> list.fold(module, fn(module, dependency) {
          module.add_import(module, string.split(dependency, "/"))
        })

      module
    }
    _ -> {
      let results =
        list.filter_map(fields, fn(field) {
          use res <- result.try(resolve_table_fields(
            tables,
            table_info,
            field.field,
          ))

          Ok(
            ResolveTableFieldsResult(
              ..res,
              field: extractor.TableField(
                ..res.field,
                name: field.alias |> option.unwrap(res.field.name),
              ),
            ),
          )
        })

      let fields = list.map(results, fn(res) { res.field })

      let module =
        list.fold(fields, module.root.create(), fn(module, field) {
          case field.object_fields {
            [] -> module
            fields -> {
              module
              |> module.root.add(generate_type_definition(
                common.string_to_pascal_case(field.name),
                fields,
              ))
              |> module.root.add(generate_type_decoder(
                config,
                common.string_to_pascal_case(field.name),
                fields,
                "",
              ))
              |> module.root.add(generate_type_to_json(
                config,
                field.name,
                fields,
                "",
              ))
            }
          }
        })

      let module =
        module
        |> module.root.add(module.section_comment("Query result"))
        |> module.root.add(generate_type_definition("QueryResult", fields))
        |> module.root.add(generate_type_decoder(
          config,
          "QueryResult",
          fields,
          "",
        ))
        |> module.root.add(generate_type_to_json(
          config,
          "QueryResult",
          fields,
          "",
        ))

      let dependencies =
        set.from_list([path |> string.join("/")])
        |> set.union(
          list.flat_map(table_info.fields, fn(f) { f.dependencies })
          |> set.from_list,
        )
        |> set.union(retrieve_dependencies_(fields, tables))

      let module =
        dependencies
        |> set.to_list()
        |> list.fold(module, fn(module, dependency) {
          module.add_import(module, string.split(dependency, "/"))
        })

      module
    }
  }

  let parameters =
    list.filter_map(
      list.filter_map(
        [
          option.to_result(where, Nil)
            |> result.map(pair.new(_, Ok(surreal_type.Bool))),
          option.to_result(limit, Nil)
            |> result.map(pair.new(_, Ok(surreal_type.Int))),
        ],
        function.identity,
      ),
      fn(item) {
        extract_parameters(item.0, item.1, table_info, tables, namespace)
      },
    )
    |> list.flatten()
    |> complete_parameter_extraction()

  let module = case parameters {
    [] -> module
    _ -> {
      module
      |> module.root.add(generate_parameters_builder(parameters))
    }
  }

  let module = case config.service {
    True ->
      module.root.add(
        module,
        generate_query_builder(
          parameters,
          "QueryResult",
          option.Some(namespace),
          "Read",
        ),
      )
    False -> module
  }

  Ok(module)
}

fn do_update_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.Update(target:, set:, where:) = node

  use table_info <- result.try(
    dict.get(tables, target)
    |> result.map_error(fn(_) { "Unknown table for update: " <> target }),
  )

  let path =
    result.unwrap(string.split_once(table_info.path, "src/"), #("", "")).1
  let path = string.split(path, "/")
  let namespace = list.last(path) |> result.unwrap("")

  let module =
    module.root.create()
    |> module.root.add(
      module.const_definition.create(
        "QueryResult",
        module.binop.access(
          module.identifier.create(namespace),
          module_common.type_identifier(target),
        ),
      )
      |> module.const_definition.public()
      |> module.const_definition.as_type(),
    )

  let module =
    module
    |> module.root.add(case config.offstage {
      True ->
        module.const_definition.create(
          "serializer",
          module.binop.access(
            module.identifier.create(namespace),
            module.identifier.create("serializer"),
          ),
        )
        |> module.const_definition.public()
      False ->
        module.const_definition.create(
          "decoder",
          module.binop.access(
            module.identifier.create(namespace),
            module.identifier.create("decoder"),
          ),
        )
        |> module.const_definition.public()
    })

  let module =
    module
    |> module.root.add(
      module.const_definition.create(
        "to_json",
        module.binop.access(
          module.identifier.create(namespace),
          module.identifier.create("to_json"),
        ),
      )
      |> module.const_definition.public(),
    )

  let dependencies = set.from_list([path |> string.join("/")])
  let dependencies =
    set.union(retrieve_dependencies_(table_info.fields, tables), dependencies)

  let module =
    dependencies
    |> set.to_list()
    |> list.fold(module, fn(module, dependency) {
      module.add_import(module, string.split(dependency, "/"))
    })

  let parameters =
    list.filter_map(
      case where {
        option.Some(item) ->
          list.append(set |> list.map(fn(item) { pair.new(item, Error(Nil)) }), [
            #(item, Ok(surreal_type.Bool)),
          ])
        _ ->
          set
          |> list.map(fn(item) { pair.new(item, Error(Nil)) })
      },
      fn(item) {
        extract_parameters(item.0, item.1, table_info, tables, namespace)
      },
    )
    |> list.flatten()
    |> complete_parameter_extraction()

  let module = case parameters {
    [] -> module
    _ -> module.root.add(module, generate_parameters_builder(parameters))
  }

  let module = case config.service {
    True ->
      module.root.add(
        module,
        generate_query_builder(
          parameters,
          "QueryResult",
          option.Some(namespace),
          "Update",
        ),
      )
    False -> module
  }

  Ok(module)
}

fn do_create_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.Create(only:, target:, set:) = node
  use table_info <- result.try(
    dict.get(tables, target)
    |> result.map_error(fn(_) { "Unknown table for create: " <> target }),
  )

  let path =
    result.unwrap(string.split_once(table_info.path, "src/"), #("", "")).1
  let path = string.split(path, "/")
  let namespace = list.last(path) |> result.unwrap("")

  let module =
    module.root.create()
    |> module.root.add(
      module.const_definition.create(
        "QueryResult",
        module.binop.access(
          module.identifier.create(namespace),
          module_common.type_identifier(target),
        ),
      )
      |> module.const_definition.public()
      |> module.const_definition.as_type(),
    )

  let module =
    module
    |> module.root.add(case config.offstage {
      True ->
        module.const_definition.create(
          "serializer",
          module.binop.access(
            module.identifier.create(namespace),
            module.identifier.create("serializer"),
          ),
        )
        |> module.const_definition.public()
      False ->
        module.const_definition.create(
          "decoder",
          module.binop.access(
            module.identifier.create(namespace),
            module.identifier.create("decoder"),
          ),
        )
        |> module.const_definition.public()
    })

  let module =
    module
    |> module.root.add(
      module.const_definition.create(
        "to_json",
        module.binop.access(
          module.identifier.create(namespace),
          module.identifier.create("to_json"),
        ),
      )
      |> module.const_definition.public(),
    )

  let dependencies = set.from_list([path |> string.join("/")])
  let dependencies =
    set.union(retrieve_dependencies_(table_info.fields, tables), dependencies)

  let module =
    dependencies
    |> set.to_list()
    |> list.fold(module, fn(module, dependency) {
      module.add_import(module, string.split(dependency, "/"))
    })

  let parameters =
    list.filter_map(
      list.map(set, fn(item) { pair.new(item, Error(Nil)) }),
      fn(item) {
        extract_parameters(item.0, item.1, table_info, tables, namespace)
      },
    )
    |> list.flatten()
    |> complete_parameter_extraction()

  let module = case parameters {
    [] -> module
    _ -> module.root.add(module, generate_parameters_builder(parameters))
  }

  let module = case config.service {
    True ->
      module.root.add(
        module,
        generate_query_builder(
          parameters,
          "QueryResult",
          option.Some(namespace),
          "Create",
        ),
      )
    False -> module
  }

  Ok(module)
}

fn do_delete_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.Delete(target:, where:) = node

  case target {
    node.BinaryOperator(
      lhs: from,
      operator: node.RelationTo,
      rhs: node.Identifier(name),
    ) -> {
      use table_info <- result.try(
        dict.get(tables, name)
        |> result.replace_error("Unknown table for update: " <> name),
      )

      let path =
        result.unwrap(string.split_once(table_info.path, "src/"), #("", "")).1
      let path = string.split(path, "/")
      let namespace = list.last(path) |> result.unwrap("")

      let module =
        module.root.create()
        |> module.root.add(
          module.const_definition.create("QueryResult", module.literal.nil)
          |> module.const_definition.as_type()
          |> module.const_definition.public(),
        )
        |> module.root.add(
          module.const_definition.create(
            "to_json",
            module.binop.access(
              module.identifier.create("json"),
              module.identifier.create("null"),
            ),
          )
          |> module.const_definition.public(),
        )
        |> module.add_import(["gleam", "json"])

      let module = case config.offstage {
        True ->
          module
          |> module.root.add(
            module.function_definition.create()
            |> module.function_definition.public()
            |> module.function_definition.with_name("serializer")
            |> module.function_definition.add(
              module.function_call.create(module.binop.access(
                module.identifier.create("serialize"),
                module.identifier.create("nil"),
              )),
            ),
          )
          |> module.add_import(["offstage", "dynamic", "serialize"])
        False ->
          module
          |> module.root.add(
            module.function_definition.create()
            |> module.function_definition.public()
            |> module.function_definition.with_name("decoder")
            |> module.function_definition.add(
              module.function_call.create(module.binop.access(
                module.identifier.create("decode"),
                module.identifier.create("success"),
              ))
              |> module.function_call.add(module.literal.nil),
            ),
          )
          |> module.add_import(["gleam", "dynamic", "decode"])
      }

      let module =
        retrieve_dependencies(module, table_info.fields, tables)
        |> module.add_import(path)

      let in =
        table_info.fields
        |> list.find(fn(f) { f.name == "in" })
        |> result.map(fn(f) {
          case f.type_ {
            surreal_type.Record(record) ->
              case string.contains(record, ".") {
                True ->
                  extractor.TableField(
                    ..f,
                    type_: surreal_type.Identifier(record),
                  )
                _ -> {
                  dict.get(tables, string.lowercase(record))
                  |> result.map(fn(info) {
                    extractor.TableField(
                      ..f,
                      type_: surreal_type.Identifier(
                        common.namespace_of(info.path)
                        <> "."
                        <> common.to_pascal_case(info.name).value,
                      ),
                    )
                  })
                  |> result.unwrap(f)
                }
              }
            _ -> f
          }
        })
        |> result.unwrap(
          extractor.TableField(
            dependencies: [],
            name: "in",
            type_: surreal_type.Record("Nil"),
            linked_enum: option.None,
            object_fields: [],
          ),
        )

      let parameters =
        list.filter_map(
          [#(from, Ok(in.type_))]
            |> list.append(case where {
              option.Some(item) -> [#(item, Ok(surreal_type.Bool))]
              _ -> []
            }),
          fn(item) {
            extract_parameters(item.0, item.1, table_info, tables, namespace)
          },
        )
        |> list.flatten()
        |> complete_parameter_extraction()

      let module = case parameters {
        [] -> module
        _ -> module.root.add(module, generate_parameters_builder(parameters))
      }

      let module = case config.service {
        True ->
          module.root.add(
            module,
            generate_query_builder(
              parameters,
              "QueryResult",
              option.Some(namespace),
              "Delete",
            ),
          )
        False -> module
      }

      Ok(module)
    }
    _ -> {
      io.println(
        "Warning: unsupported delete target: " <> node.to_string(target),
      )
      Ok(module.root.create())
    }
  }
}

fn do_relate_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.Relate(table:, from:, to:, set:) = node

  use table_info <- result.try(
    dict.get(tables, table)
    |> result.replace_error("Unknown table for update: " <> table),
  )

  let path =
    result.unwrap(string.split_once(table_info.path, "src/"), #("", "")).1
  let path = string.split(path, "/")
  let namespace = list.last(path) |> result.unwrap("")

  let module =
    module.root.create()
    |> module.root.add(
      module.const_definition.create(
        "QueryResult",
        module.binop.access(
          module.identifier.create(namespace),
          module_common.type_identifier(table),
        ),
      )
      |> module.const_definition.public()
      |> module.const_definition.as_type(),
    )

  let module =
    module
    |> module.root.add(case config.offstage {
      True ->
        module.const_definition.create(
          "serializer",
          module.binop.access(
            module.identifier.create(namespace),
            module.identifier.create("serializer"),
          ),
        )
        |> module.const_definition.public()
      False ->
        module.const_definition.create(
          "decoder",
          module.binop.access(
            module.identifier.create(namespace),
            module.identifier.create("decoder"),
          ),
        )
        |> module.const_definition.public()
    })

  let module =
    module
    |> module.root.add(
      module.const_definition.create(
        "to_json",
        module.binop.access(
          module.identifier.create(namespace),
          module.identifier.create("to_json"),
        ),
      )
      |> module.const_definition.public(),
    )

  let dependencies = set.from_list([path |> string.join("/")])
  let dependencies =
    set.union(retrieve_dependencies_(table_info.fields, tables), dependencies)

  let in =
    table_info.fields
    |> list.find(fn(f) { f.name == "in" })
    |> result.map(fn(f) {
      case f.type_ {
        surreal_type.Record(record) ->
          case string.contains(record, ".") {
            True -> f
            _ -> {
              dict.get(tables, string.lowercase(record))
              |> result.map(fn(info) {
                extractor.TableField(
                  ..f,
                  type_: surreal_type.Record(
                    common.namespace_of(info.path)
                    <> "."
                    <> common.to_pascal_case(info.name).value,
                  ),
                )
              })
              |> result.unwrap(f)
            }
          }
        _ -> f
      }
    })
    |> result.unwrap(
      extractor.TableField(
        dependencies: [],
        name: "in",
        type_: surreal_type.Record("Nil"),
        linked_enum: option.None,
        object_fields: [],
      ),
    )
  let out =
    table_info.fields
    |> list.find(fn(f) { f.name == "out" })
    |> result.map(fn(f) {
      case f.type_ {
        surreal_type.Record(record) ->
          case string.contains(record, ".") {
            True -> f
            _ -> {
              dict.get(tables, string.lowercase(record))
              |> result.map(fn(info) {
                extractor.TableField(
                  ..f,
                  type_: surreal_type.Record(
                    common.namespace_of(info.path)
                    <> "."
                    <> common.to_pascal_case(info.name).value,
                  ),
                )
              })
              |> result.unwrap(f)
            }
          }
        _ -> f
      }
    })
    |> result.unwrap(
      extractor.TableField(
        dependencies: [],
        name: "out",
        type_: surreal_type.Record("Nil"),
        linked_enum: option.None,
        object_fields: [],
      ),
    )

  let parameters =
    list.filter_map(
      list.append(set |> list.map(pair.new(_, Error(Nil))), [
        #(from, Ok(in.type_)),
        #(to, Ok(out.type_)),
      ]),
      fn(item) {
        extract_parameters(item.0, item.1, table_info, tables, namespace)
      },
    )
    |> list.flatten()
    |> complete_parameter_extraction()

  let module =
    dependencies
    |> set.to_list()
    |> list.fold(module, fn(module, dependency) {
      module.add_import(module, string.split(dependency, "/"))
    })

  let module = case parameters {
    [] -> module
    _ -> module.root.add(module, generate_parameters_builder(parameters))
  }

  let module = case config.service {
    True ->
      module.root.add(
        module,
        generate_query_builder(
          parameters,
          "QueryResult",
          option.Some(namespace),
          "Create",
        ),
      )
    False -> module
  }

  Ok(module)
}

fn do_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  case node {
    node.DefineTable(type_: node.NormalTable, ..) -> {
      do_define_normal_table_node(config, node, tables)
    }
    node.DefineTable(type_: node.RelationTable(..), ..) -> {
      do_define_relation_table_node(config, node, tables)
    }
    node.Select(..) -> {
      do_select_node(config, node, tables)
    }
    node.Update(..) -> {
      do_update_node(config, node, tables)
    }
    node.Create(..) -> {
      do_create_node(config, node, tables)
    }
    node.Delete(..) -> {
      do_delete_node(config, node, tables)
    }
    node.Relate(..) -> {
      do_relate_node(config, node, tables)
    }
    _ -> Ok(module.root.create())
  }
}

pub fn process_delegated_table(
  tables: dict.Dict(String, extractor.TableInfo),
) -> dict.Dict(String, extractor.TableInfo) {
  tables
  |> dict.map_values(fn(_, info) {
    case info.delegated {
      option.Some(node.Select(fields:, table:, ..)) ->
        {
          use table_info <- result.try(
            dict.get(tables, table)
            |> result.map_error(fn(_) { "Unknown table for select: " <> table }),
          )

          let table_fields =
            list.filter_map(fields, fn(field) {
              case field.field {
                node.Identifier("id") ->
                  list.find(table_info.fields, fn(f) { f.name == "id" })
                  |> result.map(fn(f) {
                    extractor.TableField(
                      dependencies: f.dependencies,
                      name: field.alias |> option.unwrap("id"),
                      type_: case f.type_ {
                        surreal_type.Identifier(name) ->
                          surreal_type.Identifier(
                            table_info.path
                            |> string.split("/")
                            |> list.last()
                            |> result.unwrap("??")
                            <> "."
                            <> name,
                          )
                        _ -> f.type_
                      },
                      linked_enum: f.linked_enum,
                      object_fields: f.object_fields,
                    )
                  })
                node.Identifier(name) ->
                  list.find(table_info.fields, fn(f) { f.name == name })
                  |> result.map(fn(f) {
                    let assert Ok(prefix) =
                      string.split(table_info.path, "/") |> list.last()
                    extractor.TableField(
                      dependencies: f.dependencies,
                      name: field.alias |> option.unwrap(name),
                      type_: f.type_,
                      linked_enum: f.linked_enum
                        |> option.map(fn(enum) { prefix <> "." <> enum }),
                      object_fields: f.object_fields,
                    )
                  })
                node.WrappedNode(node.If(_, then_:, else_:, ..)) ->
                  case then_, else_ {
                    node.None, node.Identifier(name)
                    | node.Identifier(name), node.None
                    -> {
                      list.find(table_info.fields, fn(f) { f.name == name })
                      |> result.map(fn(f) {
                        let assert Ok(prefix) =
                          string.split(table_info.path, "/") |> list.last()
                        extractor.TableField(
                          dependencies: f.dependencies,
                          name: field.alias |> option.unwrap(name),
                          type_: case f.type_ {
                            surreal_type.Option(_) -> f.type_
                            _ -> surreal_type.Option(f.type_)
                          },
                          linked_enum: f.linked_enum
                            |> option.map(fn(enum) { prefix <> "." <> enum }),
                          object_fields: f.object_fields,
                        )
                      })
                    }
                    _, _ -> Error(Nil)
                  }
                _ -> Error(Nil)
              }
            })

          Ok(extractor.TableInfo(
            name: info.name,
            path: info.path,
            fields: list.append(info.fields, table_fields),
            enums: info.enums,
            delegated: option.None,
          ))
        }
        |> result.unwrap(info)
      _ -> info
    }
  })
}

pub fn generate_file(
  config: common.Configuration,
  raw: String,
  ast: List(node.Node),
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(String, String) {
  use generated <- result.try(list.try_map(ast, do_node(config, _, tables)))

  let module =
    module.root.create()
    |> list.fold(generated, _, module.root.add)

  // Generate the query constant
  let module =
    module
    |> module.root.add(module.section_comment("Raw query"))
    |> module.root.add(
      module.const_definition.create(
        "query_string",
        string.split(string.replace(raw, "\"", "\\\""), "\n")
          |> list.map(fn(line) { module.literal.string(line <> "\\n") })
          |> list.reduce(module.binop.string_concat)
          |> result.unwrap(module.literal.string("")),
      )
      |> module.const_definition.public(),
    )
    |> module.root.add(
      module.const_definition.create(
        "query_node",
        module.literal.list(list.map(ast, node.to_module)),
      )
      |> module.const_definition.public(),
    )

  let content = module.to_string2(module)

  Ok(content)
}
