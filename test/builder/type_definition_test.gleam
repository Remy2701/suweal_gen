import birdie
import extractor
import gleam/option
import internal/builder/type_definition
import omcg/module
import suweal/surreal_type

pub fn type_definition_generation_with_single_id_field_test() {
  let generated =
    type_definition.generate("User", [
      extractor.TableField(
        dependencies: [],
        name: "id",
        type_: surreal_type.Identifier("User"),
        linked_enum: option.None,
        object_fields: [],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_single_id_field",
  )
}

pub fn type_definition_generation_with_single_optional_id_field_test() {
  let generated =
    type_definition.generate("User", [
      extractor.TableField(
        dependencies: [],
        name: "id",
        type_: surreal_type.Option(surreal_type.Identifier("User")),
        linked_enum: option.None,
        object_fields: [],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_single_optional_id_field",
  )
}

pub fn type_definition_generation_with_single_record_field_test() {
  let generated =
    type_definition.generate("User", [
      extractor.TableField(
        dependencies: [],
        name: "record",
        type_: surreal_type.Record("User"),
        linked_enum: option.None,
        object_fields: [],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_single_record_field",
  )
}

pub fn type_definition_generation_with_primitive_fields_test() {
  let generated =
    type_definition.generate("Primitives", [
      extractor.TableField(
        dependencies: [],
        name: "s",
        type_: surreal_type.String,
        linked_enum: option.None,
        object_fields: [],
      ),
      extractor.TableField(
        dependencies: [],
        name: "i",
        type_: surreal_type.Int,
        linked_enum: option.None,
        object_fields: [],
      ),
      extractor.TableField(
        dependencies: [],
        name: "f",
        type_: surreal_type.Float,
        linked_enum: option.None,
        object_fields: [],
      ),
      extractor.TableField(
        dependencies: [],
        name: "b",
        type_: surreal_type.Bool,
        linked_enum: option.None,
        object_fields: [],
      ),
      extractor.TableField(
        dependencies: [],
        name: "a",
        type_: surreal_type.Array(surreal_type.String),
        linked_enum: option.None,
        object_fields: [],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_primitive_fields",
  )
}

pub fn type_definition_generation_with_single_datetime_field_test() {
  let generated =
    type_definition.generate("User", [
      extractor.TableField(
        dependencies: [],
        name: "created_at",
        type_: surreal_type.Datetime,
        linked_enum: option.None,
        object_fields: [],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_single_datetime_field",
  )
}

pub fn type_definition_generation_with_single_point_field_test() {
  let generated =
    type_definition.generate("User", [
      extractor.TableField(
        dependencies: [],
        name: "location",
        type_: surreal_type.Point,
        linked_enum: option.None,
        object_fields: [],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_single_point_field",
  )
}

pub fn type_definition_generation_with_single_object_test() {
  let generated =
    type_definition.generate("User", [
      extractor.TableField(
        dependencies: [],
        name: "object",
        type_: surreal_type.Object,
        linked_enum: option.None,
        object_fields: [],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_single_object_field",
  )
}

pub fn type_definition_generation_with_nested_object_test() {
  let generated =
    type_definition.generate("User", [
      extractor.TableField(
        dependencies: [],
        name: "my_object",
        type_: surreal_type.Object,
        linked_enum: option.None,
        object_fields: [
          extractor.TableField(
            dependencies: [],
            name: "nested",
            type_: surreal_type.Object,
            linked_enum: option.None,
            object_fields: [],
          ),
        ],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_nested_object_field",
  )
}

pub fn type_definition_generation_with_array_of_nested_object_field_test() {
  let generated =
    type_definition.generate("User", [
      extractor.TableField(
        dependencies: [],
        name: "my_object",
        type_: surreal_type.Array(surreal_type.Object),
        linked_enum: option.None,
        object_fields: [
          extractor.TableField(
            dependencies: [],
            name: "nested",
            type_: surreal_type.Object,
            linked_enum: option.None,
            object_fields: [],
          ),
        ],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_array_of_nested_object_field",
  )
}

pub fn type_definition_generation_with_string_enum_field_test() {
  let generated =
    type_definition.generate("User", [
      extractor.TableField(
        dependencies: [],
        name: "status",
        type_: surreal_type.String,
        linked_enum: option.Some("Status"),
        object_fields: [],
      ),
    ])

  birdie.snap(
    module.to_string(generated),
    "type_definition_generation_with_string_enum_field",
  )
}
