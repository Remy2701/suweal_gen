import extractor
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import omcg/id_case
import omcg/module
import omcg/module_common
import omcg/option_module
import suweal/surreal_type

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                     Table Type Definition                                     //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

/// Generate the field for the type definition based on the table field information.
fn generate_type_definition_field(
  module: module.Module,
  field: extractor.TableField,
) -> module.Module {
  module
  |> module.type_variant.field(Some(field.name), case field.linked_enum {
    Some(enum) -> {
      let inner = case string.split_once(enum, ".") {
        Ok(#(module_str, name)) -> {
          module.identifier.create(module_str)
          |> module.binop.access(module_common.type_identifier(name))
        }
        _ -> module_common.type_identifier(enum)
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
              |> module.function_call.add(module_common.type_identifier(
                field.name,
              ))
            }

            surreal_type.Object -> module_common.type_identifier(field.name)

            _ -> {
              io.println(
                "Warning: unsupported object field type for `"
                <> field.name
                <> "`: "
                <> module.module_node_to_string(surreal_type.to_gleam_type(
                  field.type_,
                )),
              )
              module_common.type_identifier(field.name)
            }
          }
      }
    }
  })
}

/// Generate the definition for the type based on the table name and its fields.
pub fn generate(
  name: String,
  fields: List(extractor.TableField),
) -> module.Module {
  module.type_definition.create(id_case.string_to_pascal_case(name))
  |> module.type_definition.public()
  |> module.type_definition.add(
    module.type_variant.create(id_case.string_to_pascal_case(name))
    |> list.fold(fields, _, generate_type_definition_field),
  )
}
