import gleam/io
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
        strategy: node.DefineTableRegular,
        type_: node.NormalTable,
        schema: node.Schemafull,
        permissions: [node.PermissionNone],
        as_: option.None,
      ),
    ]
}

pub fn parse_define_overwrite_table_test() {
  let str =
    "DEFINE TABLE OVERWRITE user TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Table,
      lexer.Overwrite,
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
        strategy: node.DefineTableOverwrite,
        type_: node.NormalTable,
        schema: node.Schemafull,
        permissions: [node.PermissionNone],
        as_: option.None,
      ),
    ]
}

pub fn parse_define_if_not_exists_table_test() {
  let str =
    "DEFINE TABLE IF NOT EXISTS user TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Table,
      lexer.If,
      lexer.Not,
      lexer.Exists,
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
        strategy: node.DefineTableIfNotExists,
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
        strategy: node.DefineFieldRegular,
        table: "table",
        type_: surreal_type.String,
        flexible: False,
        default: option.Some(node.None),
        assert_: option.None,
        permissions: [node.PermissionFull],
      ),
    ]
}

pub fn parse_define_overwrite_string_field_test() {
  let str =
    "DEFINE FIELD OVERWRITE a ON table TYPE string DEFAULT NONE PERMISSIONS FULL;"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Field,
      lexer.Overwrite,
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
        strategy: node.DefineFieldOverwrite,
        table: "table",
        type_: surreal_type.String,
        flexible: False,
        default: option.Some(node.None),
        assert_: option.None,
        permissions: [node.PermissionFull],
      ),
    ]
}

pub fn parse_define_if_not_exists_string_field_test() {
  let str =
    "DEFINE FIELD IF NOT EXISTS a ON table TYPE string DEFAULT NONE PERMISSIONS FULL;"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Field,
      lexer.If,
      lexer.Not,
      lexer.Exists,
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
        strategy: node.DefineFieldIfNotExists,
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
        strategy: node.DefineFieldRegular,
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
        strategy: node.DefineFieldRegular,
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
        strategy: node.DefineFieldRegular,
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

pub fn parse_define_access_test() {
  let str =
    "DEFINE ACCESS user ON DATABASE TYPE RECORD "
    <> "SIGNUP (CREATE user SET email = $email, password = crypto::argon2::generate($password)) "
    <> "SIGNIN (SELECT * FROM user WHERE email = $email AND crypto::argon2::compare(password, $password))"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Access,
      lexer.Identifier("user"),
      lexer.On,
      lexer.Database,
      lexer.Type,
      lexer.Record,
      lexer.Signup,
      lexer.LeftParenthesis,
      lexer.Create,
      lexer.Identifier("user"),
      lexer.Set,
      lexer.Identifier("email"),
      lexer.Equal,
      lexer.Parameter("email"),
      lexer.Comma,
      lexer.Identifier("password"),
      lexer.Equal,
      lexer.Identifier("crypto"),
      lexer.DoubleColon,
      lexer.Identifier("argon2"),
      lexer.DoubleColon,
      lexer.Identifier("generate"),
      lexer.LeftParenthesis,
      lexer.Parameter("password"),
      lexer.RightParenthesis,
      lexer.RightParenthesis,
      lexer.Signin,
      lexer.LeftParenthesis,
      lexer.Select,
      lexer.Asterisk,
      lexer.From,
      lexer.Identifier("user"),
      lexer.Where,
      lexer.Identifier("email"),
      lexer.Equal,
      lexer.Parameter("email"),
      lexer.And,
      lexer.Identifier("crypto"),
      lexer.DoubleColon,
      lexer.Identifier("argon2"),
      lexer.DoubleColon,
      lexer.Identifier("compare"),
      lexer.LeftParenthesis,
      lexer.Identifier("password"),
      lexer.Comma,
      lexer.Parameter("password"),
      lexer.RightParenthesis,
      lexer.RightParenthesis,
    ]

  let ast = case parser.parse(tokens) {
    Ok(ast) -> ast
    Error(e) -> {
      io.println(
        "Failed to parse input:\n" <> parser.render_error(e, str) <> "\n",
      )
      panic as "Failed to parse input"
    }
  }

  assert ast
    == [
      node.DefineAccess(
        name: "user",
        strategy: node.DefineAccessRegular,
        target: node.DefineAccessDatabase,
        type_: node.DefineAccessRecord(
          signin: option.Some(
            node.WrappedNode(node.Select(
              fields: [
                node.SelectField(
                  field: node.All,
                  alias: option.None,
                  value: False,
                ),
              ],
              only: False,
              table: "user",
              where: option.Some(node.BinaryOperator(
                lhs: node.BinaryOperator(
                  lhs: node.Identifier("email"),
                  operator: node.Equal,
                  rhs: node.Parameter("email"),
                ),
                operator: node.And,
                rhs: node.BinaryOperator(
                  lhs: node.BinaryOperator(
                    lhs: node.Identifier("crypto"),
                    operator: node.NamespaceAccess,
                    rhs: node.Identifier("argon2"),
                  ),
                  operator: node.NamespaceAccess,
                  rhs: node.FunctionCall(
                    node: node.Identifier("compare"),
                    arguments: [
                      node.Identifier("password"),
                      node.Parameter("password"),
                    ],
                  ),
                ),
              )),
              order: option.None,
              limit: option.None,
              group_all: False,
            )),
          ),
          signup: option.Some(
            node.WrappedNode(
              node.Create(only: False, target: "user", set: [
                node.BinaryOperator(
                  lhs: node.Identifier("email"),
                  operator: node.Equal,
                  rhs: node.Parameter("email"),
                ),
                node.BinaryOperator(
                  lhs: node.Identifier("password"),
                  operator: node.Equal,
                  rhs: node.BinaryOperator(
                    lhs: node.BinaryOperator(
                      lhs: node.Identifier("crypto"),
                      operator: node.NamespaceAccess,
                      rhs: node.Identifier("argon2"),
                    ),
                    operator: node.NamespaceAccess,
                    rhs: node.FunctionCall(
                      node: node.Identifier("generate"),
                      arguments: [
                        node.Parameter("password"),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]
}

pub fn parse_define_access_swapped_test() {
  let str =
    "DEFINE ACCESS user ON DATABASE TYPE RECORD "
    <> "SIGNIN (SELECT * FROM user WHERE email = $email AND crypto::argon2::compare(password, $password)) "
    <> "SIGNUP (CREATE user SET email = $email, password = crypto::argon2::generate($password))"
  let assert Ok(tokens) = lexer.tokenize("./src/db/test", str)
    as "Failed to tokenize input"

  assert positioned.unpositioned(tokens)
    == [
      lexer.Define,
      lexer.Access,
      lexer.Identifier("user"),
      lexer.On,
      lexer.Database,
      lexer.Type,
      lexer.Record,
      lexer.Signin,
      lexer.LeftParenthesis,
      lexer.Select,
      lexer.Asterisk,
      lexer.From,
      lexer.Identifier("user"),
      lexer.Where,
      lexer.Identifier("email"),
      lexer.Equal,
      lexer.Parameter("email"),
      lexer.And,
      lexer.Identifier("crypto"),
      lexer.DoubleColon,
      lexer.Identifier("argon2"),
      lexer.DoubleColon,
      lexer.Identifier("compare"),
      lexer.LeftParenthesis,
      lexer.Identifier("password"),
      lexer.Comma,
      lexer.Parameter("password"),
      lexer.RightParenthesis,
      lexer.RightParenthesis,
      lexer.Signup,
      lexer.LeftParenthesis,
      lexer.Create,
      lexer.Identifier("user"),
      lexer.Set,
      lexer.Identifier("email"),
      lexer.Equal,
      lexer.Parameter("email"),
      lexer.Comma,
      lexer.Identifier("password"),
      lexer.Equal,
      lexer.Identifier("crypto"),
      lexer.DoubleColon,
      lexer.Identifier("argon2"),
      lexer.DoubleColon,
      lexer.Identifier("generate"),
      lexer.LeftParenthesis,
      lexer.Parameter("password"),
      lexer.RightParenthesis,
      lexer.RightParenthesis,
    ]

  let ast = case parser.parse(tokens) {
    Ok(ast) -> ast
    Error(e) -> {
      io.println(
        "Failed to parse input:\n" <> parser.render_error(e, str) <> "\n",
      )
      panic as "Failed to parse input"
    }
  }

  assert ast
    == [
      node.DefineAccess(
        name: "user",
        strategy: node.DefineAccessRegular,
        target: node.DefineAccessDatabase,
        type_: node.DefineAccessRecord(
          signin: option.Some(
            node.WrappedNode(node.Select(
              fields: [
                node.SelectField(
                  field: node.All,
                  alias: option.None,
                  value: False,
                ),
              ],
              only: False,
              table: "user",
              where: option.Some(node.BinaryOperator(
                lhs: node.BinaryOperator(
                  lhs: node.Identifier("email"),
                  operator: node.Equal,
                  rhs: node.Parameter("email"),
                ),
                operator: node.And,
                rhs: node.BinaryOperator(
                  lhs: node.BinaryOperator(
                    lhs: node.Identifier("crypto"),
                    operator: node.NamespaceAccess,
                    rhs: node.Identifier("argon2"),
                  ),
                  operator: node.NamespaceAccess,
                  rhs: node.FunctionCall(
                    node: node.Identifier("compare"),
                    arguments: [
                      node.Identifier("password"),
                      node.Parameter("password"),
                    ],
                  ),
                ),
              )),
              order: option.None,
              limit: option.None,
              group_all: False,
            )),
          ),
          signup: option.Some(
            node.WrappedNode(
              node.Create(only: False, target: "user", set: [
                node.BinaryOperator(
                  lhs: node.Identifier("email"),
                  operator: node.Equal,
                  rhs: node.Parameter("email"),
                ),
                node.BinaryOperator(
                  lhs: node.Identifier("password"),
                  operator: node.Equal,
                  rhs: node.BinaryOperator(
                    lhs: node.BinaryOperator(
                      lhs: node.Identifier("crypto"),
                      operator: node.NamespaceAccess,
                      rhs: node.Identifier("argon2"),
                    ),
                    operator: node.NamespaceAccess,
                    rhs: node.FunctionCall(
                      node: node.Identifier("generate"),
                      arguments: [
                        node.Parameter("password"),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]
}
