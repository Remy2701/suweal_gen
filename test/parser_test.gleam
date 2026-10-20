import gleam/option
import lexer
import parser
import positioned
import suweal/node
import suweal/surreal_ql
import suweal/surreal_type

pub fn parse_define_table_test() {
  let str = "DEFINE TABLE user TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Table,
      lexer.Identifier("user"),
      lexer.Type,
      lexer.Normal,
      lexer.Schemafull,
      lexer.Permissions,
      lexer.None,
      lexer.Semicolon,
    ]

  let assert Ok(ast) = parser.parse(tokens) as "Failed to parse input"

  assert ast
    == [
      node.DefineTable(
        name: "user",
        type_: node.NormalTable,
        schema: node.Schemafull,
        permissions: [node.PermissionNone],
        as_: option.None,
      ),
    ]
}

pub fn parse_define_string_field_test() {
  let str = "DEFINE FIELD a ON table TYPE string DEFAULT NONE PERMISSIONS FULL;"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Field,
      lexer.Identifier("a"),
      lexer.On,
      lexer.Identifier("table"),
      lexer.Type,
      lexer.Identifier("string"),
      lexer.Default,
      lexer.None,
      lexer.Permissions,
      lexer.Full,
      lexer.Semicolon,
    ]

  let assert Ok(ast) = parser.parse(tokens) as "Failed to parse input"

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
  let str =
    "DEFINE FIELD a ON table TYPE none | string DEFAULT NONE PERMISSIONS FULL;"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Field,
      lexer.Identifier("a"),
      lexer.On,
      lexer.Identifier("table"),
      lexer.Type,
      lexer.Identifier("none"),
      lexer.Pipe,
      lexer.Identifier("string"),
      lexer.Default,
      lexer.None,
      lexer.Permissions,
      lexer.Full,
      lexer.Semicolon,
    ]

  let assert Ok(ast) = parser.parse(tokens) as "Failed to parse input"

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
  let str =
    "DEFINE FIELD a ON table TYPE string DEFAULT NONE ASSERT $value INSIDE ['A', 'B', 'C'] PERMISSIONS FULL;"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Field,
      lexer.Identifier("a"),
      lexer.On,
      lexer.Identifier("table"),
      lexer.Type,
      lexer.Identifier("string"),
      lexer.Default,
      lexer.None,
      lexer.Assert,
      lexer.Parameter("value"),
      lexer.Inside,
      lexer.LeftBracket,
      lexer.String("A"),
      lexer.Comma,
      lexer.String("B"),
      lexer.Comma,
      lexer.String("C"),
      lexer.RightBracket,
      lexer.Permissions,
      lexer.Full,
      lexer.Semicolon,
    ]

  let assert Ok(ast) = parser.parse(tokens) as "Failed to parse input"

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
  let str =
    "DEFINE FIELD a ON table TYPE none | string DEFAULT NONE ASSERT $value INSIDE [NONE, 'A', 'B', 'C'] PERMISSIONS FULL;"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Field,
      lexer.Identifier("a"),
      lexer.On,
      lexer.Identifier("table"),
      lexer.Type,
      lexer.Identifier("none"),
      lexer.Pipe,
      lexer.Identifier("string"),
      lexer.Default,
      lexer.None,
      lexer.Assert,
      lexer.Parameter("value"),
      lexer.Inside,
      lexer.LeftBracket,
      lexer.None,
      lexer.Comma,
      lexer.String("A"),
      lexer.Comma,
      lexer.String("B"),
      lexer.Comma,
      lexer.String("C"),
      lexer.RightBracket,
      lexer.Permissions,
      lexer.Full,
      lexer.Semicolon,
    ]

  let assert Ok(ast) = parser.parse(tokens) as "Failed to parse input"

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
