import birdie
import common
import gleam/option
import internal/builder/parameters_builder
import omcg/module
import suweal/surreal_type

pub fn parameters_builder_generation_test() {
  let generated =
    parameters_builder.generate([
      common.ParameterProperty(
        dependencies: [],
        name: "s",
        type_: surreal_type.String,
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "i",
        type_: surreal_type.Int,
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "f",
        type_: surreal_type.Float,
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "b",
        type_: surreal_type.Bool,
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "a",
        type_: surreal_type.Array(surreal_type.String),
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "d",
        type_: surreal_type.Datetime,
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "o",
        type_: surreal_type.Option(surreal_type.String),
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "id",
        type_: surreal_type.Identifier("user"),
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "rc",
        type_: surreal_type.Record("id"),
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "obj",
        type_: surreal_type.Object,
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "nested_obj",
        type_: surreal_type.Object,
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "p",
        type_: surreal_type.Point,
        linked_enum: option.None,
      ),
      common.ParameterProperty(
        dependencies: [],
        name: "e",
        type_: surreal_type.String,
        linked_enum: option.Some("enum"),
      ),
    ])

  birdie.snap(module.to_string(generated), "parameters_builder_generation_test")
}
