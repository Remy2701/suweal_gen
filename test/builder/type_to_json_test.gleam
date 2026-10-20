import birdie
import common
import extractor
import gleam/option
import internal/builder/type_to_json
import omcg/module
import suweal/surreal_type

pub fn type_to_json_generation_test() {
  let generated =
    type_to_json.generate(
      common.Configuration(False, False, "./src/db/test"),
      "user",
      [
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
        extractor.TableField(
          dependencies: [],
          name: "d",
          type_: surreal_type.Datetime,
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "o",
          type_: surreal_type.Option(surreal_type.String),
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "id",
          type_: surreal_type.Identifier("user"),
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "rc",
          type_: surreal_type.Record("id"),
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "obj",
          type_: surreal_type.Object,
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "nested_obj",
          type_: surreal_type.Object,
          linked_enum: option.None,
          object_fields: [
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
          ],
        ),
        extractor.TableField(
          dependencies: [],
          name: "p",
          type_: surreal_type.Point,
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "e",
          type_: surreal_type.String,
          linked_enum: option.Some("enum"),
          object_fields: [],
        ),
      ],
      "",
    )

  birdie.snap(module.to_string(generated), "type_to_json_generation_test")
}

pub fn type_to_json_generation_with_offstage_test() {
  let generated =
    type_to_json.generate(
      common.Configuration(True, False, "./src/db/test"),
      "user",
      [
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
        extractor.TableField(
          dependencies: [],
          name: "d",
          type_: surreal_type.Datetime,
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "o",
          type_: surreal_type.Option(surreal_type.String),
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "id",
          type_: surreal_type.Identifier("user"),
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "rc",
          type_: surreal_type.Record("id"),
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "obj",
          type_: surreal_type.Object,
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "nested_obj",
          type_: surreal_type.Object,
          linked_enum: option.None,
          object_fields: [
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
          ],
        ),
        extractor.TableField(
          dependencies: [],
          name: "p",
          type_: surreal_type.Point,
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "e",
          type_: surreal_type.String,
          linked_enum: option.Some("enum"),
          object_fields: [],
        ),
      ],
      "",
    )

  birdie.snap(
    module.to_string(generated),
    "type_to_json_generation_with_offstage_test",
  )
}

pub fn type_to_json_generation_with_service_test() {
  let generated =
    type_to_json.generate(
      common.Configuration(True, False, "./src/db/test"),
      "user",
      [
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
        extractor.TableField(
          dependencies: [],
          name: "d",
          type_: surreal_type.Datetime,
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "o",
          type_: surreal_type.Option(surreal_type.String),
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "id",
          type_: surreal_type.Identifier("user"),
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "rc",
          type_: surreal_type.Record("id"),
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "obj",
          type_: surreal_type.Object,
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "nested_obj",
          type_: surreal_type.Object,
          linked_enum: option.None,
          object_fields: [
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
          ],
        ),
        extractor.TableField(
          dependencies: [],
          name: "p",
          type_: surreal_type.Point,
          linked_enum: option.None,
          object_fields: [],
        ),
        extractor.TableField(
          dependencies: [],
          name: "e",
          type_: surreal_type.String,
          linked_enum: option.Some("enum"),
          object_fields: [],
        ),
      ],
      "",
    )

  birdie.snap(
    module.to_string(generated),
    "type_to_json_generation_with_service_test",
  )
}
