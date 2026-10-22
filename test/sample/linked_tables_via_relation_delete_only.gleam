import birdie
import common
import gleam/list
import gleam/string
import sample/linked_tables_via_relation
import suweal_gen

pub const input_from_a = "DELETE ONLY $a->c;"

pub const path_from_a = "./src/db/test/linked_tables_via_relation_delete_only_from_a"

pub fn linked_tables_via_relation_delete_only_from_a_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: False, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_a,
          content: linked_tables_via_relation.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_b,
          content: linked_tables_via_relation.input_table_b,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_c,
          content: linked_tables_via_relation.input_table_c,
        ),
        suweal_gen.File(path: path_from_a, content: input_from_a),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path_from_a) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesViaRelationDeleteOnlyFromA[offstage = False, service = False]",
  )
}

pub fn linked_tables_via_relation_delete_only_from_a_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_a,
          content: linked_tables_via_relation.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_b,
          content: linked_tables_via_relation.input_table_b,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_c,
          content: linked_tables_via_relation.input_table_c,
        ),
        suweal_gen.File(path: path_from_a, content: input_from_a),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path_from_a) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesViaRelationDeleteOnlyFromA[offstage = True, service = False]",
  )
}

pub fn linked_tables_via_relation_delete_only_from_a_with_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: True, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_a,
          content: linked_tables_via_relation.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_b,
          content: linked_tables_via_relation.input_table_b,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_c,
          content: linked_tables_via_relation.input_table_c,
        ),
        suweal_gen.File(path: path_from_a, content: input_from_a),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path_from_a) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesViaRelationDeleteOnlyFromA[offstage = True, service = True]",
  )
}

pub const input_from_b = "DELETE ONLY $b<-c;"

pub const path_from_b = "./src/db/test/linked_tables_via_relation_delete_only_from_b"

pub fn linked_tables_via_relation_delete_only_from_b_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: False, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_a,
          content: linked_tables_via_relation.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_b,
          content: linked_tables_via_relation.input_table_b,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_c,
          content: linked_tables_via_relation.input_table_c,
        ),
        suweal_gen.File(path: path_from_b, content: input_from_b),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path_from_b) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesViaRelationDeleteOnlyFromB[offstage = False, service = False]",
  )
}

pub fn linked_tables_via_relation_delete_only_from_b_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_a,
          content: linked_tables_via_relation.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_b,
          content: linked_tables_via_relation.input_table_b,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_c,
          content: linked_tables_via_relation.input_table_c,
        ),
        suweal_gen.File(path: path_from_b, content: input_from_b),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path_from_b) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesViaRelationDeleteOnlyFromB[offstage = True, service = False]",
  )
}

pub fn linked_tables_via_relation_delete_only_from_b_with_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: True, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_a,
          content: linked_tables_via_relation.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_b,
          content: linked_tables_via_relation.input_table_b,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_c,
          content: linked_tables_via_relation.input_table_c,
        ),
        suweal_gen.File(path: path_from_b, content: input_from_b),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path_from_b) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesViaRelationDeleteOnlyFromB[offstage = True, service = True]",
  )
}

pub const input_a_to_b = "DELETE ONLY $a->c->$b;"

pub const path_a_to_b = "./src/db/test/linked_tables_via_relation_delete_only_a_to_b"

pub fn linked_tables_via_relation_delete_only_a_to_b_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: False, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_a,
          content: linked_tables_via_relation.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_b,
          content: linked_tables_via_relation.input_table_b,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_c,
          content: linked_tables_via_relation.input_table_c,
        ),
        suweal_gen.File(path: path_a_to_b, content: input_a_to_b),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path_a_to_b) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesViaRelationDeleteOnlyAtoB[offstage = False, service = False]",
  )
}

pub fn linked_tables_via_relation_delete_only_a_to_b_with_offstage_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: False, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_a,
          content: linked_tables_via_relation.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_b,
          content: linked_tables_via_relation.input_table_b,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_c,
          content: linked_tables_via_relation.input_table_c,
        ),
        suweal_gen.File(path: path_a_to_b, content: input_a_to_b),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path_a_to_b) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesViaRelationDeleteOnlyAtoB[offstage = True, service = False]",
  )
}

pub fn linked_tables_via_relation_delete_only_a_to_b_with_service_test() {
  let assert Ok(content) =
    suweal_gen.generate_files(
      common.Configuration(offstage: True, service: True, path: "./src"),
      [
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_a,
          content: linked_tables_via_relation.input_table_a,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_b,
          content: linked_tables_via_relation.input_table_b,
        ),
        suweal_gen.File(
          path: linked_tables_via_relation.path_table_c,
          content: linked_tables_via_relation.input_table_c,
        ),
        suweal_gen.File(path: path_a_to_b, content: input_a_to_b),
      ],
    )

  let assert Ok(focused) =
    list.find(content, fn(file) { string.starts_with(file.path, path_a_to_b) })
    as "No matching file found"

  birdie.snap(
    focused.content,
    "LinkedTablesViaRelationDeleteOnlyAtoB[offstage = True, service = True]",
  )
}
