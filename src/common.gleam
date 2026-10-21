import gleam/option
import suweal/surreal_type

pub type Configuration {
  Configuration(offstage: Bool, service: Bool, path: String)
}

pub type ParameterProperty {
  ParameterProperty(
    name: String,
    type_: surreal_type.SurrealType,
    linked_enum: option.Option(String),
    dependencies: List(String),
    nested: option.Option(String),
  )
}
