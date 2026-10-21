import extractor
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import omcg/module
import omcg/module_common
import suweal/surreal_type.{type SurrealType}

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

pub fn generate(
  name: String,
  fields: List(extractor.TableField),
  prefix: String,
) -> module.Module {
  module.function_definition.create()
  |> module.function_definition.public()
  |> module.function_definition.with_name(prefix <> "to_surql")
  |> module.function_definition.add_parameter(
    "self",
    module_common.type_identifier(name),
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
