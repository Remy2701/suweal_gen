import common
import extractor
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import omcg/decode_module
import omcg/module
import omcg/module_common
import omcg/offstage_serialize_module
import omcg/option_module
import suweal/surreal_type.{type SurrealType}

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

pub fn generate(
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
    |> module.function_call.add(module_common.type_identifier(name)),
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
      module.function_call.create(module_common.type_identifier(name))
      |> list.fold(fields, _, fn(module, field) {
        module
        |> module.function_call.add(module.identifier.create(field.name))
      }),
    ),
  )
  |> module.add_import(["gleam", "dynamic", "decode"])
}
