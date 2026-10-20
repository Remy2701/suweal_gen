import omcg/id_case
import omcg/module.{type Module}

pub fn type_identifier(name: String) -> Module {
  name |> id_case.string_to_pascal_case |> module.identifier.create
}
