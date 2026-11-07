import extractor
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import omcg/module
import suweal/node
import suweal/surreal_type

pub type MigrationTableField {
  MigrationTableField(
    name: String,
    table: String,
    type_: surreal_type.SurrealType,
    raw_string: String,
  )
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

pub fn migration_table_field_to_json(field: MigrationTableField) -> json.Json {
  json.object([
    #("name", json.string(field.name)),
    #("table", json.string(field.table)),
    #("type", surreal_type_to_json(field.type_)),
    #("raw_string", json.string(field.raw_string)),
  ])
}

pub fn migration_table_field_decoder() -> decode.Decoder(MigrationTableField) {
  use name <- decode.field("name", decode.string)
  use table <- decode.field("table", decode.string)
  use type_ <- decode.field("type", surreal_type_decoder())
  use raw_string <- decode.field("raw_string", decode.string)

  decode.success(MigrationTableField(name, table, type_, raw_string))
}

pub type MigrationTable {
  MigrationTable(
    name: String,
    fields: List(MigrationTableField),
    type_: node.TableType,
  )
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

pub fn extract_fields(tables: dict.Dict(String, extractor.TableInfo)) {
  tables
  |> dict.to_list()
  |> list.flat_map(fn(entry) {
    let #(name, table) = entry
    table.fields
    |> list.flat_map(extract_object_field(name, "", _))
  })
}

pub type FieldDifference {
  FieldAdded(MigrationTableField)
  FieldRemoved(MigrationTableField)
  FieldChanged(MigrationTableField, MigrationTableField)
  TableAdded(String)
}

pub fn find_different_fields(
  current: List(MigrationTableField),
  previous: List(MigrationTableField),
  tables: dict.Dict(String, extractor.TableInfo),
) {
  let fields =
    current
    |> list.filter(fn(field) { field.raw_string != "__IGNORE__" })
    |> list.filter_map(fn(field) {
      let matching =
        list.find(previous, fn(prev) {
          prev.name == field.name && prev.table == field.table
        })
      case matching {
        Ok(matching) ->
          case matching.type_ == field.type_ {
            True -> Error(Nil)
            False -> Ok(FieldChanged(matching, field))
          }
        Error(_) -> Ok(FieldAdded(field))
      }
    })

  let tables =
    fields
    |> list.filter_map(fn(result) {
      case result {
        FieldAdded(field) -> {
          let fields =
            list.filter(previous, fn(prev) { prev.table == field.table })
          case fields {
            [] -> Ok(field.table)
            _ -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    })
    |> list.unique()
    |> list.filter_map(fn(table) {
      use table <- result.try(dict.get(tables, table))
      case table.raw_string {
        "__IGNORE__" -> Error(Nil)
        _ -> Ok(TableAdded(table.raw_string))
      }
    })

  tables
  |> list.append(fields)
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
              FieldAdded(field) -> field.raw_string
              TableAdded(table) -> table
              FieldRemoved(_) -> "-- Remove unsupported"
              FieldChanged(lhs, rhs) ->
                "-- Change unsupported "
                <> lhs.raw_string
                <> " ==INTO=> "
                <> rhs.raw_string
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
      |> module.function_call.add(module.literal.list([]))
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
