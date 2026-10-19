import common
import gleam/dict
import gleam/function
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import suweal/node
import suweal/surreal_ql
import suweal/surreal_type

//-----------------------------------------------------------------------------------------------//
//                                          Table Info                                           //
//-----------------------------------------------------------------------------------------------//

pub type TableField {
  TableField(
    dependencies: List(String),
    name: String,
    type_: surreal_type.SurrealType,
    linked_enum: option.Option(String),
    object_fields: List(TableField),
  )
}

/// Merge two lists of TableField, combining fields with the same name and merging their 
/// object_fields recursively.
fn merge_fields(a: List(TableField), b: List(TableField)) {
  use acc, field <- list.fold(list.append(a, b), [])

  case list.find(acc, fn(f: TableField) { f.name == field.name }) {
    Ok(found) ->
      acc
      |> list.filter(fn(f) { f.name != field.name })
      |> list.append([
        TableField(
          ..found,
          object_fields: merge_fields(found.object_fields, field.object_fields),
        ),
      ])
    _ -> [field, ..acc]
  }
}

pub type TableInfo {
  TableInfo(
    name: common.IdentifierCase,
    path: String,
    fields: List(TableField),
    enums: List(#(String, List(String))),
    delegated: option.Option(node.Node),
  )
}

/// Resolve the field with support for nested fields (e.g. `tags.*`). this is useful for arrays 
/// which define constraints on the inner type and objects.
fn resolve_nested_field(
  path: String,
  node: node.Node,
  fields: List(TableField),
  type_: surreal_type.SurrealType,
  enum: option.Option(String),
  object_fields: List(TableField),
) -> Result(List(TableField), Nil) {
  case node {
    node.Identifier(name) ->
      fields
      |> list.filter(fn(f) { f.name != name })
      |> list.append([
        TableField(
          dependencies: case enum {
            option.Some(_) -> [string.remove_prefix(path, "./src/")]
            _ -> []
          },
          name: name,
          type_: type_,
          linked_enum: enum,
          object_fields: object_fields,
        ),
      ])
      |> Ok
    node.BinaryOperator(_, node.Access, node.All) -> Ok(fields)
    node.BinaryOperator(lhs, node.Access, rhs) -> {
      use resolved <- result.try(
        resolve_nested_field(path, lhs, [], surreal_type.Object, option.None, [
          TableField(
            dependencies: [],
            name: node.to_string(rhs),
            type_: type_,
            linked_enum: enum,
            object_fields: object_fields,
          ),
        ]),
      )

      merge_fields(resolved, fields)
      |> Ok
    }
    _ -> {
      io.println("Warning: unsupported field name: " <> node.to_string(node))
      Error(Nil)
    }
  }
}

//-----------------------------------------------------------------------------------------------//
//                                             State                                             //
//-----------------------------------------------------------------------------------------------//

/// The (internal) state of the node processor.
type NodeProcessorState {
  NodeProcessorState(tables: dict.Dict(String, TableInfo))
}

//-----------------------------------------------------------------------------------------------//
//                                            Extract                                            //
//-----------------------------------------------------------------------------------------------//

/// Extract the table information from a DefineNormalTable node.
fn extract_normal_table(
  path: String,
  state: NodeProcessorState,
  name: String,
  as_: option.Option(node.Node),
) -> Result(NodeProcessorState, String) {
  Ok(
    NodeProcessorState(tables: dict.insert(
      state.tables,
      name,
      TableInfo(
        name: common.identify_case(name),
        path: path,
        fields: case as_ {
          option.None -> [
            TableField(
              dependencies: [
                string.remove_prefix(path, "./src/"),
              ],
              name: "id",
              type_: surreal_type.Identifier(common.string_to_pascal_case(name)),
              linked_enum: option.None,
              object_fields: [],
            ),
          ]
          _ -> []
        },
        enums: [],
        delegated: as_,
      ),
    )),
  )
}

/// Extract the table information from a DefineRelationTable node.
fn extract_relation_table(
  path: String,
  state: NodeProcessorState,
  name: String,
) -> Result(NodeProcessorState, String) {
  Ok(
    NodeProcessorState(tables: dict.insert(
      state.tables,
      name,
      TableInfo(
        name: common.identify_case(name),
        path: path,
        fields: [
          TableField(
            dependencies: [
              string.remove_prefix(path, "./src/"),
            ],
            name: "id",
            type_: surreal_type.Identifier(common.string_to_pascal_case(name)),
            linked_enum: option.None,
            object_fields: [],
          ),
        ],
        enums: [],
        delegated: option.None,
      ),
    )),
  )
}

/// Process the assert branch of a DefineField node. When the assert branch is present with a node
/// in the format `$value IN ["variantA", "variantB", ...]` it will create the associated 
/// enumeration.
fn process_field_assert(
  name: node.Node,
  info: TableInfo,
  assert_: option.Option(node.Node),
) {
  case assert_ {
    option.Some(node.BinaryOperator(
      node.Parameter("value"),
      node.Inside,
      node.Array(values),
    )) -> {
      // Only accept String values or null or none
      use values <- result.try(
        list.try_map(values, fn(value) {
          case value {
            node.Value(surreal_ql.String(str)) -> Ok(Ok(str))
            node.None -> Ok(Error(Nil))
            node.Value(surreal_ql.Null) -> Ok(Error(Nil))
            _ -> Error(Nil)
          }
        }),
      )
      let values = list.filter_map(values, function.identity)

      case name {
        node.Identifier(name) -> {
          Ok(#(option.Some(name), list.append(info.enums, [#(name, values)])))
        }
        _ -> {
          io.println(
            "Warning: unsupported field name for enum: " <> node.to_string(name),
          )
          Error(Nil)
        }
      }
    }

    _ -> Error(Nil)
  }
  |> result.unwrap(#(option.None, info.enums))
}

/// Extract field information from a DefineField node.
fn extract_field(
  path: String,
  state: NodeProcessorState,
  name: node.Node,
  table: String,
  type_: surreal_type.SurrealType,
  assert_: option.Option(node.Node),
) -> Result(NodeProcessorState, String) {
  use info <- result.try(
    dict.get(state.tables, table)
    |> result.map_error(fn(_) { "Unknown table for field: " <> table }),
  )

  let #(enum, enums) = process_field_assert(name, info, assert_)

  use new_fields <- result.try(
    resolve_nested_field(path, name, info.fields, type_, enum, [])
    |> result.map_error(fn(_) {
      "Failed to resolve nested field: " <> node.to_string(name)
    }),
  )

  Ok(
    NodeProcessorState(tables: dict.insert(
      state.tables,
      table,
      TableInfo(..info, fields: new_fields, enums: enums),
    )),
  )
}

/// Extract the table info from a given node. This can be the creation of a new table (both normal
/// and relational) or the definition of a field.
fn do_extract_tables(
  path: String,
  state: NodeProcessorState,
  node: node.Node,
) -> Result(NodeProcessorState, String) {
  case node {
    node.DefineTable(name:, type_: node.NormalTable, as_:, ..) ->
      extract_normal_table(path, state, name, as_)
    node.DefineTable(name:, type_: node.RelationTable(..), ..) ->
      extract_relation_table(path, state, name)
    node.DefineField(name:, table:, type_:, assert_:, ..) ->
      extract_field(path, state, name, table, type_, assert_)
    _ -> Ok(state)
  }
}

/// Extract the table info from an AST (list of nodes).
pub fn extract_tables(
  path: String,
  nodes: List(node.Node),
) -> Result(dict.Dict(String, TableInfo), String) {
  use processed <- result.try(
    list.try_fold(
      nodes,
      NodeProcessorState(tables: dict.new()),
      fn(state, node) { do_extract_tables(path, state, node) },
    ),
  )

  Ok(processed.tables)
}

//-----------------------------------------------------------------------------------------------//
//                                     Complete Dependencies                                     //
//-----------------------------------------------------------------------------------------------//

/// Complete the dependencies of a field. This will sort the dependencies in alphabetical order
/// and add the missing dependencies for identifiers and records.
fn complete_field_dependencies(
  field: TableField,
  tables: dict.Dict(String, TableInfo),
) -> TableField {
  TableField(
    ..field,
    dependencies: list.sort(
      case field.type_ {
        surreal_type.Record(name) | surreal_type.Identifier(name) -> {
          set.from_list(field.dependencies)
          |> set.union(
            dict.get(tables, name)
            |> result.map(fn(info) {
              [string.remove_prefix(info.path, "./src/")]
            })
            |> result.unwrap([])
            |> set.from_list,
          )
          |> set.to_list()
        }
        _ -> field.dependencies
      },
      string.compare,
    ),
  )
}

/// Complete the dependencies of the fields for each table. This will sort the dependencies in 
/// alphabetical order and add the missing dependencies for identifiers and records. 
pub fn complete_fields_dependencies(tables: dict.Dict(String, TableInfo)) {
  dict.map_values(tables, fn(_, table) {
    TableInfo(
      ..table,
      fields: list.map(table.fields, complete_field_dependencies(_, tables)),
    )
  })
}
