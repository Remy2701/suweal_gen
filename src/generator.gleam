import common.{type ParameterProperty, ParameterProperty}
import extractor
import gleam/dict
import gleam/function
import gleam/io
import gleam/list
import gleam/option
import gleam/order
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import internal/builder/enum_decoder
import internal/builder/enum_definition
import internal/builder/enum_to_string
import internal/builder/parameters_builder
import internal/builder/query_builder
import internal/builder/table_spec
import internal/builder/type_decoder
import internal/builder/type_definition
import internal/builder/type_to_json
import internal/builder/type_to_surql
import omcg/id_case
import omcg/module
import omcg/module_common
import suweal/node
import suweal/surreal_type.{type SurrealType}

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
            id_case.string_to_snake_case(id_case.without_namespace(name)),
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
            id_case.string_to_snake_case(id_case.without_namespace(name)),
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
            id_case.string_to_snake_case(id_case.without_namespace(name)),
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
            id_case.string_to_snake_case(id_case.without_namespace(name)),
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
                  <> id_case.string_to_pascal_case(name),
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
                  <> id_case.string_to_pascal_case(name),
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
                  <> id_case.string_to_pascal_case(name),
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
            id_case.namespace_of(current.path)
            <> "."
            <> id_case.string_to_pascal_case(inner),
          )
        surreal_type.Record(inner) ->
          case
            id_case.compare(current.name, id_case.identify_case(inner), True)
          {
            order.Eq ->
              surreal_type.Record(
                id_case.namespace_of(current.path)
                <> "."
                <> id_case.string_to_pascal_case(inner),
              )
            _ -> {
              let current = dict.get(tables, string.lowercase(inner))

              case current {
                Ok(current) ->
                  surreal_type.Record(
                    id_case.namespace_of(current.path)
                    <> "."
                    <> id_case.string_to_pascal_case(inner),
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
          False -> id_case.namespace_of(current.path) <> "." <> enum
          True -> enum
        }
      }),
      object_fields: field.object_fields,
    ),
    dependencies: case field.type_ {
      surreal_type.Identifier(inner) ->
        case id_case.compare(current.name, id_case.identify_case(inner), True) {
          order.Eq -> set.from_list([id_case.to_gleam_path(current.path)])
          _ -> {
            let current = dict.get(tables, string.lowercase(inner))

            case current {
              Ok(current) ->
                set.from_list([
                  id_case.to_gleam_path(current.path),
                ])
              _ -> {
                io.println("Warning: Could not resolve table `" <> inner <> "`")
                set.new()
              }
            }
          }
        }
      surreal_type.Record(inner) ->
        case id_case.compare(current.name, id_case.identify_case(inner), True) {
          order.Eq -> set.from_list([id_case.to_gleam_path(current.path)])
          _ -> {
            let current = dict.get(tables, string.lowercase(inner))

            case current {
              Ok(current) ->
                set.from_list([
                  id_case.to_gleam_path(current.path),
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

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                         Nested Fields                                         //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn generate_nest_field(
  config: common.Configuration,
  field: extractor.TableField,
) -> Result(module.Module, Nil) {
  case field.object_fields {
    [] -> Error(Nil)
    fields -> {
      let name = id_case.string_to_space_case(field.name)
      let module =
        module.root.create()
        |> list.fold(
          fields |> list.filter_map(generate_nest_field(config, _)),
          _,
          module.root.add,
        )
        |> module.root.add(module.section_comment(name))
        |> module.root.add(type_definition.generate(field.name, fields))
        |> module.root.add(type_decoder.generate(
          config,
          field.name,
          fields,
          field.name <> "_",
        ))
        |> module.root.add(type_to_json.generate(
          config,
          field.name,
          fields,
          field.name <> "_",
        ))
        |> module.root.add(type_to_surql.generate(
          field.name,
          fields,
          field.name <> "_",
        ))

      Ok(module)
    }
  }
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                       Fields Resolution                                       //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

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
          type_: surreal_type.Record(id_case.to_pascal_case(current.name).value),
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
                        id_case.namespace_of(table.path)
                        <> "."
                        <> id_case.to_pascal_case(table.name).value,
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
                id_case.without_namespace(inner),
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
                id_case.without_namespace(inner),
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
                id_case.string_to_snake_case(id_case.without_namespace(inner)),
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
                module.module_node_to_string(surreal_type.to_gleam_type(t))
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

/// Extracts the parameters from a given node based on the expected type and table information.
fn extract_parameters(
  node: node.Node,
  expected_type: Result(SurrealType, Nil),
  table_info: extractor.TableInfo,
  tables: dict.Dict(String, extractor.TableInfo),
  namespace: String,
) {
  case node {
    // Equality check with None `${name} = none`
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
          nested: option.None,
        ),
      ])
    }
    // Equality | Comparison check for parameters `lhs >= rhs`
    node.BinaryOperator(lhs:, operator: node.Equal, rhs:)
    | node.BinaryOperator(lhs:, operator: node.NotEqual, rhs:)
    | node.BinaryOperator(lhs:, operator: node.GreaterThan, rhs:)
    | node.BinaryOperator(lhs:, operator: node.GreaterThanOrEqual, rhs:)
    | node.BinaryOperator(lhs:, operator: node.LessThan, rhs:)
    | node.BinaryOperator(lhs:, operator: node.LessThanOrEqual, rhs:) ->
      case rhs {
        node.Parameter(name) -> {
          // Assigning parameter property to a value.
          // Figure out the type of the lhs and add it to the parameters list
          pick_field(table_info.fields, lhs)
          |> result.map(fn(f) {
            case f.name, f.type_ {
              "id", surreal_type.Identifier(identifier_name) -> {
                case string.contains(identifier_name, ".") {
                  True ->
                    ParameterProperty(
                      name: name,
                      type_: f.type_,
                      linked_enum: option.None,
                      dependencies: [],
                      nested: option.None,
                    )
                  _ ->
                    ParameterProperty(
                      name: name,
                      type_: surreal_type.Identifier(
                        namespace <> "." <> identifier_name,
                      ),
                      linked_enum: option.None,
                      dependencies: [],
                      nested: option.None,
                    )
                }
              }
              _, surreal_type.Record(record_name) ->
                case dict.get(tables, record_name) {
                  Ok(info) ->
                    ParameterProperty(
                      name: name,
                      type_: surreal_type.Identifier(
                        id_case.namespace_of(info.path)
                        <> "."
                        <> id_case.string_to_pascal_case(record_name),
                      ),
                      linked_enum: option.None,
                      dependencies: [],
                      nested: option.None,
                    )
                  _ ->
                    ParameterProperty(
                      name: name,
                      type_: surreal_type.Identifier(name),
                      linked_enum: option.None,
                      dependencies: [],
                      nested: option.None,
                    )
                }
              _, surreal_type.String ->
                ParameterProperty(
                  name: name,
                  type_: surreal_type.String,
                  linked_enum: option.map(f.linked_enum, fn(enum) {
                    case string.contains(enum, ".") {
                      False ->
                        namespace <> "." <> id_case.string_to_pascal_case(enum)
                      True -> enum
                    }
                  }),
                  dependencies: f.dependencies,
                  nested: option.None,
                )
              _, surreal_type.Option(surreal_type.String) ->
                ParameterProperty(
                  name: name,
                  type_: surreal_type.Option(surreal_type.String),
                  linked_enum: option.map(f.linked_enum, fn(enum) {
                    case string.contains(enum, ".") {
                      False ->
                        namespace <> "." <> id_case.string_to_pascal_case(enum)
                      True -> enum
                    }
                  }),
                  dependencies: f.dependencies,
                  nested: option.None,
                )
              _, surreal_type.Object -> {
                ParameterProperty(
                  name: name,
                  type_: f.type_,
                  linked_enum: option.None,
                  dependencies: [],
                  nested: case f.object_fields {
                    [] -> option.None
                    _ ->
                      option.Some(
                        namespace
                        <> "."
                        <> id_case.string_to_pascal_case(f.name),
                      )
                  },
                )
              }
              _, _ ->
                ParameterProperty(
                  name: name,
                  type_: f.type_,
                  linked_enum: option.None,
                  dependencies: [],
                  nested: option.None,
                )
            }
          })
          |> result.unwrap(ParameterProperty(
            name: name,
            type_: surreal_type.Object,
            linked_enum: option.None,
            dependencies: [],
            nested: option.None,
          ))
          |> list.wrap()
          |> Ok
        }
        _ -> Error(Nil)
      }
    // And | Or logical operators for combining conditions.
    node.BinaryOperator(lhs:, operator: node.And, rhs:)
    | node.BinaryOperator(lhs:, operator: node.Or, rhs:) ->
      [
        extract_parameters(lhs, Error(Nil), table_info, tables, namespace),
        extract_parameters(rhs, Error(Nil), table_info, tables, namespace),
      ]
      |> list.filter_map(function.identity)
      |> list.flatten()
      |> Ok
    // Single parameter `${name}
    node.Parameter(name) ->
      case expected_type {
        Ok(type_) ->
          Ok([
            ParameterProperty(
              name: name,
              type_: type_,
              linked_enum: option.None,
              dependencies: [],
              nested: option.None,
            ),
          ])
        _ -> Error(Nil)
      }
    // Wrapped node containing another node `({inner})`.
    node.WrappedNode(inner) -> {
      extract_parameters(inner, expected_type, table_info, tables, namespace)
    }
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
//                                         Normal Table                                          //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

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
      |> module.root.add(enum_definition.generate(enum_name, values))
      |> module.root.add(enum_to_string.generate(enum_name, values))
      |> module.root.add(enum_decoder.generate(config, enum_name, values))
    })

  let #(module, fields) = resolve_dependencies(module, info.fields, tables)

  let module =
    module
    |> module.root.add(
      module.section_comment(id_case.string_to_space_case(name)),
    )
    |> module.root.add(type_definition.generate(name, fields))
    |> module.root.add(type_decoder.generate(config, name, fields, ""))
    |> module.root.add(type_to_json.generate(config, name, fields, ""))
    |> module.root.add(type_to_surql.generate(name, fields, ""))
    |> module.root.add(table_spec.generate(config, name))

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

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                        Relation Table                                         //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

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
      |> module.root.add(enum_definition.generate(enum_name, values))
      |> module.root.add(enum_to_string.generate(enum_name, values))
      |> module.root.add(enum_decoder.generate(config, enum_name, values))
    })

  let #(module, fields) = resolve_dependencies(module, info.fields, tables)

  // Generate table type definition, decoder, `to_json` and `to_surql` functions
  let module =
    module
    |> module.root.add(
      module.section_comment(id_case.string_to_space_case(name)),
    )
    |> module.root.add(type_definition.generate(name, fields))
    |> module.root.add(type_decoder.generate(config, name, fields, ""))
    |> module.root.add(type_to_json.generate(config, name, fields, ""))
    |> module.root.add(type_to_surql.generate(name, fields, ""))
    |> module.root.add(table_spec.generate(config, name))

  Ok(module)
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                            Select                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn do_select_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.Select(only:, fields:, table:, where:, limit:, ..) = node
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
              module.identifier.create(id_case.string_to_pascal_case(table)),
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
              |> module.root.add(type_definition.generate(
                id_case.string_to_pascal_case(field.name),
                fields,
              ))
              |> module.root.add(type_decoder.generate(
                config,
                id_case.string_to_pascal_case(field.name),
                fields,
                "",
              ))
              |> module.root.add(type_to_json.generate(
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
        |> module.root.add(type_definition.generate("QueryResult", fields))
        |> module.root.add(type_decoder.generate(
          config,
          "QueryResult",
          fields,
          "",
        ))
        |> module.root.add(type_to_json.generate(
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
      |> module.root.add(parameters_builder.generate(parameters))
    }
  }

  let module = case config.service {
    True ->
      module.root.add(
        module,
        query_builder.generate(
          parameters,
          "QueryResult",
          option.Some(namespace),
          "Read",
          only: only,
        ),
      )
    False -> module
  }

  Ok(module)
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                            Update                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn do_update_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.Update(only:, target:, set:, where:) = node

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
    _ -> module.root.add(module, parameters_builder.generate(parameters))
  }

  let module = case config.service {
    True ->
      module.root.add(
        module,
        query_builder.generate(
          parameters,
          "QueryResult",
          option.Some(namespace),
          "Update",
          only: only,
        ),
      )
    False -> module
  }

  Ok(module)
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                            Create                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

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
    _ -> module.root.add(module, parameters_builder.generate(parameters))
  }

  let module = case config.service {
    True ->
      module.root.add(
        module,
        query_builder.generate(
          parameters,
          "QueryResult",
          option.Some(namespace),
          "Create",
          only: only,
        ),
      )
    False -> module
  }

  Ok(module)
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                            Delete                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn do_delete_node(
  config: common.Configuration,
  node: node.Node,
  tables: dict.Dict(String, extractor.TableInfo),
) -> Result(module.Module, String) {
  let assert node.Delete(only:, target:, where:) = node

  case target {
    node.BinaryOperator(
      lhs: node.BinaryOperator(
        lhs: from,
        operator: node.RelationTo,
        rhs: node.Identifier(name),
      ),
      operator: node.RelationTo,
      rhs: to,
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
                        id_case.namespace_of(info.path)
                        <> "."
                        <> id_case.to_pascal_case(info.name).value,
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
                        id_case.namespace_of(info.path)
                        <> "."
                        <> id_case.to_pascal_case(info.name).value,
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
          [#(from, Ok(in.type_)), #(to, Ok(out.type_))]
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
        _ -> module.root.add(module, parameters_builder.generate(parameters))
      }

      let module = case config.service {
        True ->
          module.root.add(
            module,
            query_builder.generate(
              parameters,
              "QueryResult",
              option.Some(namespace),
              "Delete",
              only: only,
            ),
          )
        False -> module
      }

      Ok(module)
    }
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
                        id_case.namespace_of(info.path)
                        <> "."
                        <> id_case.to_pascal_case(info.name).value,
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
        _ -> module.root.add(module, parameters_builder.generate(parameters))
      }

      let module = case config.service {
        True ->
          module.root.add(
            module,
            query_builder.generate(
              parameters,
              "QueryResult",
              option.Some(namespace),
              "Delete",
              only: only,
            ),
          )
        False -> module
      }

      Ok(module)
    }
    node.BinaryOperator(
      lhs: to,
      operator: node.RelationFrom,
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

      let out =
        table_info.fields
        |> list.find(fn(f) { f.name == "out" })
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
                        id_case.namespace_of(info.path)
                        <> "."
                        <> id_case.to_pascal_case(info.name).value,
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
          [#(to, Ok(out.type_))]
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
        _ -> module.root.add(module, parameters_builder.generate(parameters))
      }

      let module = case config.service {
        True ->
          module.root.add(
            module,
            query_builder.generate(
              parameters,
              "QueryResult",
              option.Some(namespace),
              "Delete",
              only: only,
            ),
          )
        False -> module
      }

      Ok(module)
    }
    node.Identifier(target) -> {
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

      let parameters =
        list.filter_map(
          case where {
            option.Some(item) -> [#(item, Ok(surreal_type.Bool))]
            _ -> []
          },
          fn(item) {
            extract_parameters(item.0, item.1, table_info, tables, namespace)
          },
        )
        |> list.flatten()
        |> complete_parameter_extraction()

      let module = case parameters {
        [] -> module
        _ -> module.root.add(module, parameters_builder.generate(parameters))
      }

      let module = case config.service {
        True ->
          module.root.add(
            module,
            query_builder.generate(
              parameters,
              "QueryResult",
              option.Some(namespace),
              "Delete",
              only: only,
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

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                            Relate                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

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
                  type_: surreal_type.Identifier(
                    id_case.namespace_of(info.path)
                    <> "."
                    <> id_case.to_pascal_case(info.name).value,
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
                  type_: surreal_type.Identifier(
                    id_case.namespace_of(info.path)
                    <> "."
                    <> id_case.to_pascal_case(info.name).value,
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
    _ -> module.root.add(module, parameters_builder.generate(parameters))
  }

  let module = case config.service {
    True ->
      module.root.add(
        module,
        query_builder.generate(
          parameters,
          "QueryResult",
          option.Some(namespace),
          "Create",
          only: False,
        ),
      )
    False -> module
  }

  Ok(module)
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             Node                                              //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

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

  let content = module.to_string(module)

  Ok(content)
}
