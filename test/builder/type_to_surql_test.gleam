import birdie
import extractor
import gleam/option
import internal/builder/type_to_surql
import omcg/module
import suweal/surreal_type

pub fn type_to_surql_generation_test() {
  let generated =
    type_to_surql.generate(
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

  birdie.snap(module.to_string(generated), "type_to_surql_generation_test")
}

pub fn type_to_surql_generation_with_prefix_test() {
  let generated =
    type_to_surql.generate(
      "nested",
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
      ],
      "nested_",
    )

  birdie.snap(
    module.to_string(generated),
    "type_to_surql_generation_with_prefix_test",
  )
}
