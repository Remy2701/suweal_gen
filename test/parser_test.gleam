import gleam/option
import gleeunit/should
import lexer
import parser
import suweal/node
import suweal/surreal_ql
import suweal/surreal_type

pub fn parse_define_table_test() {
  let assert Ok(ast) =
    "DEFINE TABLE user TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;"
    |> lexer.tokenize("./src/db/test", _)
    |> should.be_ok()
    |> parser.parse()

  assert ast
    == [
      node.DefineTable(
        name: "user",
        type_: node.NormalTable,
        schema: node.Schemafull,
        permissions: [],
        as_: option.None,
      ),
    ]
}

pub fn parse_define_string_field_test() {
  let assert Ok(ast) =
    "DEFINE FIELD a ON table TYPE string DEFAULT NONE PERMISSIONS FULL;"
    |> lexer.tokenize("./src/db/test", _)
    |> should.be_ok()
    |> parser.parse()

  assert ast
    == [
      node.DefineField(
        name: node.Identifier("a"),
        table: "table",
        type_: surreal_type.String,
        flexible: False,
        default: option.Some(node.None),
        assert_: option.None,
        permissions: [node.PermissionFull],
      ),
    ]
}

pub fn parse_define_optional_string_field_test() {
  let assert Ok(ast) =
    "DEFINE FIELD a ON table TYPE none | string DEFAULT NONE PERMISSIONS FULL;"
    |> lexer.tokenize("./src/db/test", _)
    |> should.be_ok()
    |> parser.parse()

  assert ast
    == [
      node.DefineField(
        name: node.Identifier("a"),
        table: "table",
        type_: surreal_type.Option(surreal_type.String),
        flexible: False,
        default: option.Some(node.None),
        assert_: option.None,
        permissions: [node.PermissionFull],
      ),
    ]
}

pub fn parse_define_string_field_with_assert_test() {
  let assert Ok(ast) =
    "DEFINE FIELD a ON table TYPE string DEFAULT NONE ASSERT $value INSIDE ['A', 'B', 'C'] PERMISSIONS FULL;"
    |> lexer.tokenize("./src/db/test", _)
    |> should.be_ok()
    |> parser.parse()

  assert ast
    == [
      node.DefineField(
        name: node.Identifier("a"),
        table: "table",
        type_: surreal_type.String,
        flexible: False,
        default: option.Some(node.None),
        assert_: option.Some(node.BinaryOperator(
          node.Parameter("value"),
          node.Inside,
          node.Array([
            node.Value(surreal_ql.String("A")),
            node.Value(surreal_ql.String("B")),
            node.Value(surreal_ql.String("C")),
          ]),
        )),
        permissions: [node.PermissionFull],
      ),
    ]
}

pub fn parse_define_string_optional_field_with_assert_test() {
  let assert Ok(ast) =
    "DEFINE FIELD a ON table TYPE none | string DEFAULT NONE ASSERT $value INSIDE [NONE, 'A', 'B', 'C'] PERMISSIONS FULL;"
    |> lexer.tokenize("./src/db/test", _)
    |> should.be_ok()
    |> parser.parse()

  assert ast
    == [
      node.DefineField(
        name: node.Identifier("a"),
        table: "table",
        type_: surreal_type.Option(surreal_type.String),
        flexible: False,
        default: option.Some(node.None),
        assert_: option.Some(node.BinaryOperator(
          node.Parameter("value"),
          node.Inside,
          node.Array([
            node.None,
            node.Value(surreal_ql.String("A")),
            node.Value(surreal_ql.String("B")),
            node.Value(surreal_ql.String("C")),
          ]),
        )),
        permissions: [node.PermissionFull],
      ),
    ]
}
