import common
import gleam/dict
import gleam/function
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import omcg/id_case
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
    raw_string: String,
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
          raw_string: field.raw_string,
        ),
      ])
    _ -> [field, ..acc]
  }
}

pub type TableInfo {
  TableInfo(
    name: id_case.IdentifierCase,
    path: String,
    type_: node.TableType,
    fields: List(TableField),
    enums: List(#(String, List(String))),
    delegated: option.Option(node.Node),
    raw_string: String,
  )
}

pub type AccessInfo {
  AccessInfo(name: String, path: String, raw_string: String)
}

pub type IndexInfo {
  IndexInfo(name: String, path: String, raw_string: String)
}

pub type ExtractorResult {
  ExtractorResult(
    tables: dict.Dict(String, TableInfo),
    accesses: dict.Dict(String, AccessInfo),
    indexes: dict.Dict(String, IndexInfo),
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
  raw: node.Node,
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
          raw_string: raw |> common.force_if_not_exists() |> node.to_string(),
        ),
      ])
      |> Ok
    node.BinaryOperator(_, node.Access, node.All) -> Ok(fields)
    node.BinaryOperator(lhs, node.Access, rhs) -> {
      use resolved <- result.try(resolve_nested_field(
        path,
        lhs,
        [],
        surreal_type.Object,
        option.None,
        [
          TableField(
            dependencies: [],
            name: node.to_string(rhs),
            type_: type_,
            linked_enum: enum,
            object_fields: object_fields,
            raw_string: raw |> common.force_if_not_exists() |> node.to_string(),
          ),
        ],
        raw,
      ))

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
  NodeProcessorState(
    tables: dict.Dict(String, TableInfo),
    view_tables: dict.Dict(String, TableInfo),
    accesses: dict.Dict(String, AccessInfo),
    indexes: dict.Dict(String, IndexInfo),
  )
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
  raw: node.Node,
) -> Result(NodeProcessorState, String) {
  Ok(
    NodeProcessorState(
      ..state,
      tables: dict.insert(
        state.tables,
        name,
        TableInfo(
          name: id_case.identify_case(name),
          path: path,
          type_: node.NormalTable,
          fields: case as_ {
            option.None -> [
              TableField(
                dependencies: [
                  string.remove_prefix(path, "./src/"),
                ],
                name: "id",
                type_: surreal_type.Identifier(id_case.string_to_pascal_case(
                  name,
                )),
                linked_enum: option.None,
                object_fields: [],
                raw_string: "__IGNORE__",
              ),
            ]
            _ -> []
          },
          enums: [],
          delegated: as_,
          raw_string: raw |> common.force_if_not_exists() |> node.to_string(),
        ),
      ),
    ),
  )
}

/// Extract the table information from a DefineRelationTable node.
fn extract_relation_table(
  path: String,
  in: String,
  out: String,
  state: NodeProcessorState,
  name: String,
  node: node.Node,
) -> Result(NodeProcessorState, String) {
  Ok(
    NodeProcessorState(
      ..state,
      tables: dict.insert(
        state.tables,
        name,
        TableInfo(
          name: id_case.identify_case(name),
          type_: node.RelationTable(in: in, out: out),
          path: path,
          fields: [
            TableField(
              dependencies: [
                string.remove_prefix(path, "./src/"),
              ],
              name: "id",
              type_: surreal_type.Identifier(id_case.string_to_pascal_case(name)),
              linked_enum: option.None,
              object_fields: [],
              raw_string: "__IGNORE__",
            ),
          ],
          enums: [],
          delegated: option.None,
          raw_string: node |> common.force_if_not_exists() |> node.to_string(),
        ),
      ),
    ),
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
  node: node.Node,
) -> Result(NodeProcessorState, String) {
  use info <- result.try(
    dict.get(state.tables, table)
    |> result.map_error(fn(_) { "Unknown table for field: " <> table }),
  )

  let #(enum, enums) = process_field_assert(name, info, assert_)

  use new_fields <- result.try(
    resolve_nested_field(path, name, info.fields, type_, enum, [], node)
    |> result.map_error(fn(_) {
      "Failed to resolve nested field: " <> node.to_string(name)
    }),
  )

  Ok(
    NodeProcessorState(
      ..state,
      tables: dict.insert(
        state.tables,
        table,
        TableInfo(..info, fields: new_fields, enums: enums),
      ),
    ),
  )
}

/// Extract field information from a DefineField node.
fn extract_access(
  path: String,
  state: NodeProcessorState,
  name: String,
  node: node.Node,
) -> Result(NodeProcessorState, String) {
  Ok(
    NodeProcessorState(
      ..state,
      accesses: dict.insert(
        state.accesses,
        name,
        AccessInfo(
          name: name,
          path: string.remove_prefix(path, "./src/"),
          raw_string: node.to_string(node),
        ),
      ),
    ),
  )
}

/// Extract field information from a DefineField node.
fn extract_index(
  path: String,
  state: NodeProcessorState,
  name: String,
  node: node.Node,
) -> Result(NodeProcessorState, String) {
  Ok(
    NodeProcessorState(
      ..state,
      indexes: dict.insert(
        state.indexes,
        name,
        IndexInfo(
          name: name,
          path: string.remove_prefix(path, "./src/"),
          raw_string: node.to_string(node),
        ),
      ),
    ),
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
      extract_normal_table(path, state, name, as_, node)
    node.DefineTable(name:, type_: node.RelationTable(in:, out:), ..) ->
      extract_relation_table(path, in, out, state, name, node)
    node.DefineField(name:, table:, type_:, assert_:, ..) ->
      extract_field(path, state, name, table, type_, assert_, node)
    node.DefineAccess(name:, ..) -> extract_access(path, state, name, node)
    node.DefineIndex(name:, ..) -> extract_index(path, state, name, node)
    _ -> Ok(state)
  }
}

/// Extract the table info from an AST (list of nodes).
pub fn extract_tables(
  path: String,
  nodes: List(node.Node),
) -> Result(ExtractorResult, String) {
  use processed <- result.try(
    list.try_fold(
      nodes,
      NodeProcessorState(
        tables: dict.new(),
        view_tables: dict.new(),
        accesses: dict.new(),
        indexes: dict.new(),
      ),
      fn(state, node) { do_extract_tables(path, state, node) },
    ),
  )

  Ok(ExtractorResult(
    tables: processed.tables,
    accesses: processed.accesses,
    indexes: processed.indexes,
  ))
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
pub fn complete_fields_dependencies(result: ExtractorResult) {
  ExtractorResult(
    ..result,
    tables: dict.map_values(result.tables, fn(_, table) {
      TableInfo(
        ..table,
        fields: list.map(table.fields, complete_field_dependencies(
          _,
          result.tables,
        )),
      )
    }),
  )
}
