import extractor
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import omcg/module
import suweal/node
import suweal/surreal_type

pub type MigrationEntity {
  MigrationTable(name: String, type_: node.TableType, raw_string: String)
  MigrationTableField(
    name: String,
    table: String,
    type_: surreal_type.SurrealType,
    raw_string: String,
  )
  MigrationAccess(name: String, raw_string: String)
  MigrationIndex(name: String, raw_string: String)
}

fn surreal_type_to_json(type_: surreal_type.SurrealType) -> json.Json {
  case type_ {
    surreal_type.String -> json.string("string")
    surreal_type.Int -> json.string("int")
    surreal_type.Float -> json.string("float")
    surreal_type.Bool -> json.string("bool")
    surreal_type.Datetime -> json.string("datetime")
    surreal_type.Identifier(inner) ->
      json.object([
        #("type", json.string("identifier")),
        #("value", json.string(inner)),
      ])
    surreal_type.Record(inner) ->
      json.object([
        #("type", json.string("record")),
        #("value", json.string(inner)),
      ])
    surreal_type.Option(inner) ->
      json.object([
        #("type", json.string("option")),
        #("value", surreal_type_to_json(inner)),
      ])
    surreal_type.Array(inner) ->
      json.object([
        #("type", json.string("array")),
        #("value", surreal_type_to_json(inner)),
      ])
    surreal_type.Point -> json.string("point")
    surreal_type.Object -> json.string("object")
    surreal_type.None -> json.string("none")
  }
}

pub fn surreal_type_decoder() -> decode.Decoder(surreal_type.SurrealType) {
  decode.one_of(
    decode.then(decode.string, fn(value) {
      case value {
        "string" -> decode.success(surreal_type.String)
        "int" -> decode.success(surreal_type.Int)
        "float" -> decode.success(surreal_type.Float)
        "bool" -> decode.success(surreal_type.Bool)
        "datetime" -> decode.success(surreal_type.Datetime)
        "point" -> decode.success(surreal_type.Point)
        "object" -> decode.success(surreal_type.Object)
        "none" -> decode.success(surreal_type.None)
        _ -> decode.failure(surreal_type.String, "Invalid type")
      }
    }),
    [
      {
        use type_ <- decode.field("type", decode.string)

        case type_ {
          "identifier" -> {
            use value <- decode.field("value", decode.string)
            decode.success(surreal_type.Identifier(value))
          }
          "record" -> {
            use value <- decode.field("value", decode.string)
            decode.success(surreal_type.Record(value))
          }
          "option" -> {
            use value <- decode.field("value", surreal_type_decoder())
            decode.success(surreal_type.Option(value))
          }
          "array" -> {
            use value <- decode.field("value", surreal_type_decoder())
            decode.success(surreal_type.Array(value))
          }
          _ -> decode.failure(surreal_type.String, "Invalid type")
        }
      },
    ],
  )
}

pub fn migration_table_field_to_json(field: MigrationEntity) -> json.Json {
  case field {
    MigrationTable(..) -> {
      json.object([
        #("kind", json.string("table")),
        #("type", case field.type_ {
          node.NormalTable -> json.object([#("kind", json.string("normal"))])
          node.RelationTable(in:, out:) ->
            json.object([
              #("kind", json.string("relation")),
              #("in", json.string(in)),
              #("out", json.string(out)),
            ])
        }),
        #("name", json.string(field.name)),
        #("raw_string", json.string(field.raw_string)),
      ])
    }
    MigrationTableField(..) -> {
      json.object([
        #("kind", json.string("table_field")),
        #("name", json.string(field.name)),
        #("table", json.string(field.table)),
        #("type", surreal_type_to_json(field.type_)),
        #("raw_string", json.string(field.raw_string)),
      ])
    }
    MigrationAccess(..) -> {
      json.object([
        #("kind", json.string("access")),
        #("name", json.string(field.name)),
        #("raw_string", json.string(field.raw_string)),
      ])
    }
    MigrationIndex(..) -> {
      json.object([
        #("kind", json.string("index")),
        #("name", json.string(field.name)),
        #("raw_string", json.string(field.raw_string)),
      ])
    }
  }
}

pub fn migration_table_field_decoder() -> decode.Decoder(MigrationEntity) {
  use type_ <- decode.field("kind", decode.string)
  case type_ {
    "table" -> {
      use name <- decode.field("name", decode.string)
      use type_ <- decode.then({
        use internal <- decode.field("kind", decode.string)
        case internal {
          "relation" -> {
            use in <- decode.field("in", decode.string)
            use out <- decode.field("out", decode.string)
            decode.success(node.RelationTable(in: in, out: out))
          }
          "normal" -> {
            decode.success(node.NormalTable)
          }
          _ -> decode.failure(node.NormalTable, "Invalid type")
        }
      })
      use raw_string <- decode.field("raw_string", decode.string)

      decode.success(MigrationTable(name:, type_:, raw_string:))
    }
    "table_field" -> {
      use name <- decode.field("name", decode.string)
      use table <- decode.field("table", decode.string)
      use type_ <- decode.field("type", surreal_type_decoder())
      use raw_string <- decode.field("raw_string", decode.string)

      decode.success(MigrationTableField(name, table, type_, raw_string))
    }
    "access" -> {
      use name <- decode.field("name", decode.string)
      use raw_string <- decode.field("raw_string", decode.string)

      decode.success(MigrationAccess(name, raw_string))
    }
    "index" -> {
      use name <- decode.field("name", decode.string)
      use raw_string <- decode.field("raw_string", decode.string)

      decode.success(MigrationIndex(name, raw_string))
    }
    _ ->
      decode.failure(MigrationIndex(name: "", raw_string: ""), "Invalid type")
  }
}

fn extract_object_field(
  table: String,
  prefix: String,
  field: extractor.TableField,
) {
  case field.object_fields {
    [] -> [
      MigrationTableField(
        name: prefix <> field.name,
        table: table,
        type_: field.type_,
        raw_string: field.raw_string,
      ),
    ]
    _ ->
      field.object_fields
      |> list.flat_map(extract_object_field(table, field.name <> ".", _))
  }
}

pub fn extract_entities(extracted_info: extractor.ExtractorResult) {
  extracted_info.tables
  |> dict.to_list()
  |> list.flat_map(fn(entry) {
    let #(name, table) = entry
    table.fields
    |> list.flat_map(extract_object_field(name, "", _))
  })
  |> list.append(
    extracted_info.accesses
    |> dict.to_list()
    |> list.map(fn(entry) {
      let #(_, access) = entry
      MigrationAccess(name: access.name, raw_string: access.raw_string)
    }),
  )
  |> list.append(
    extracted_info.indexes
    |> dict.to_list()
    |> list.map(fn(entry) {
      let #(_, access) = entry
      MigrationIndex(name: access.name, raw_string: access.raw_string)
    }),
  )
  |> list.append(
    extracted_info.tables
    |> dict.to_list()
    |> list.map(fn(entry) {
      let #(_, table) = entry
      MigrationTable(
        name: table.name.value,
        type_: table.type_,
        raw_string: table.raw_string,
      )
    }),
  )
}

pub type FieldDifference {
  FieldAdded(MigrationEntity)
  FieldRemoved(MigrationEntity)
  FieldChanged(MigrationEntity, MigrationEntity)
  TableAdded(String)
}

pub fn find_different_entities(
  current: List(MigrationEntity),
  previous: List(MigrationEntity),
) {
  let fields =
    current
    |> list.sort(fn(a, b) {
      let priority = fn(field) {
        case field {
          MigrationTable(type_: node.NormalTable, ..) -> 0
          MigrationTable(type_: node.RelationTable(..), ..) -> 1
          MigrationTableField(..) -> 2
          MigrationAccess(..) -> 3
          MigrationIndex(..) -> 4
        }
      }

      int.compare(priority(a), priority(b))
    })
    |> list.filter(fn(field) {
      let raw_string = case field {
        MigrationTableField(raw_string:, ..) -> raw_string
        MigrationTable(raw_string:, ..) -> raw_string
        MigrationAccess(raw_string:, ..) -> raw_string
        MigrationIndex(raw_string:, ..) -> raw_string
      }

      raw_string != "__IGNORE__"
    })
    |> list.filter_map(fn(field) {
      let matching =
        list.find(previous, fn(prev) {
          case prev, field {
            MigrationTableField(..), MigrationTableField(..) ->
              prev.name == field.name && prev.table == field.table
            MigrationAccess(..), MigrationAccess(..) -> prev.name == field.name
            _, _ -> False
          }
        })
      case matching {
        Ok(matching) ->
          case matching, field {
            MigrationTableField(..), MigrationTableField(..) ->
              case matching.type_ == field.type_ {
                True -> Error(Nil)
                False -> Ok(FieldChanged(matching, field))
              }
            MigrationAccess(..), MigrationAccess(..) -> Error(Nil)
            _, _ -> Error(Nil)
          }
        Error(_) -> Ok(FieldAdded(field))
      }
    })

  // let tables =
  //   fields
  //   |> list.filter_map(fn(result) {
  //     case result {
  //       FieldAdded(MigrationTableField(table:, ..)) -> {
  //         let fields =
  //           list.filter(previous, fn(prev) {
  //             case prev {
  //               MigrationTableField(table: prev_table, ..) ->
  //                 prev_table == table
  //               _ -> False
  //             }
  //           })
  //         case fields {
  //           [] -> Ok(table)
  //           _ -> Error(Nil)
  //         }
  //       }
  //       _ -> Error(Nil)
  //     }
  //   })
  //   |> list.unique()
  //   |> list.filter_map(fn(table) {
  //     use table <- result.try(dict.get(extracted_info.tables, table))
  //     case table.raw_string {
  //       "__IGNORE__" -> Error(Nil)
  //       _ -> Ok(TableAdded(table.raw_string))
  //     }
  //   })

  // tables
  // |> 
  // list.append(fields)
  fields
}

pub fn generate_migrations(
  version: Int,
  fields: List(FieldDifference),
) -> module.Module {
  module.root.create()
  |> module.root.add(
    module.function_definition.create()
    |> module.function_definition.public()
    |> module.function_definition.with_name(
      "migration_" <> int.to_string(version),
    )
    |> module.function_definition.add_parameter(
      "connection",
      module.binop.access(
        module.identifier.create("suweal"),
        module.identifier.create("Connection"),
      )
        |> module.add_import(["suweal"]),
    )
    |> module.function_definition.add_parameter(
      "parameters",
      module.identifier.create("List")
        |> module.function_call.create()
        |> module.function_call.add(
          module.literal.tuple([
            module.types.string(),
            module.binop.access(
              module.identifier.create("surreal_ql"),
              module.identifier.create("SurrealQL"),
            ),
          ])
          |> module.add_import(["suweal", "surreal_ql"]),
        ),
    )
    |> module.function_definition.add(
      module.function_call.create(
        module.binop.access(
          module.identifier.create("surreal_http"),
          module.identifier.create("run_sql"),
        )
        |> module.add_import(["suweal", "http", "surreal_http"]),
      )
      |> module.function_call.add(module.identifier.create("connection"))
      |> module.function_call.add(
        list.fold(fields, option.None, fn(acc, field) {
          let rhs =
            case field {
              FieldAdded(MigrationTable(raw_string:, ..)) -> raw_string
              FieldAdded(MigrationTableField(raw_string:, ..)) -> raw_string
              FieldAdded(MigrationAccess(raw_string:, ..)) -> raw_string
              FieldAdded(MigrationIndex(raw_string:, ..)) -> raw_string
              TableAdded(table) -> table
              FieldRemoved(_) -> "-- Remove unsupported"
              FieldChanged(lhs, rhs) ->
                "-- Change unsupported "
                <> case lhs {
                  MigrationTableField(raw_string:, ..) -> raw_string
                  MigrationTable(raw_string:, ..) -> raw_string
                  MigrationAccess(raw_string:, ..) -> raw_string
                  MigrationIndex(raw_string:, ..) -> raw_string
                }
                <> " ==INTO=> "
                <> case rhs {
                  MigrationTableField(raw_string:, ..) -> raw_string
                  MigrationTable(raw_string:, ..) -> raw_string
                  MigrationAccess(raw_string:, ..) -> raw_string
                  MigrationIndex(raw_string:, ..) -> raw_string
                }
            }
            |> string.replace("\"", "\\\"")
            |> string.append(";\\n")
            |> module.literal.string()

          case acc {
            option.Some(lhs) ->
              option.Some(module.binop.string_concat(lhs, rhs))
            option.None -> option.Some(rhs)
          }
        })
        |> option.unwrap(module.literal.string("")),
      )
      |> module.function_call.add(module.identifier.create("parameters"))
      |> module.function_call.add(
        module.binop.access(
          module.identifier.create("decode"),
          module.identifier.create("success"),
        )
        |> module.function_call.create()
        |> module.function_call.add(module.literal.nil)
        |> module.add_import(["gleam", "dynamic", "decode"]),
      ),
    ),
  )
}
