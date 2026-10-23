import gleam/list
import gleam/option
import gleam/string
import lexer
import positioned.{type Positioned, Positioned}
import suweal/node
import suweal/surreal_ql
import suweal/surreal_type

type ParserState {
  ParserState(ast: List(node.Node))
}

pub type ParserExpectation {
  NodeExpression
  NodeType
  Token(lexer.Token)
}

pub type ParserError {
  UnexpectedToken(
    expected: List(ParserExpectation),
    actual: Positioned(lexer.Token),
  )
  UnexpectedEOF(expected: List(ParserExpectation))
}

type ParserResult(a) {
  Next(data: a)
  EOF(ast: List(node.Node))
  Failure(ParserError)
}

fn add_node(node: node.Node, state: ParserState) -> ParserState {
  ParserState(list.append(state.ast, [node]))
}

fn consume_identifier(
  input: List(Positioned(lexer.Token)),
  next: fn(String, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  case input {
    [Positioned(lexer.Identifier(name), ..), ..rest] -> next(name, rest)
    [token, ..] -> #(
      ParserState([]),
      Failure(UnexpectedToken([Token(lexer.Identifier(""))], token)),
    )
    [] -> #(
      ParserState([]),
      Failure(UnexpectedEOF([Token(lexer.Identifier(""))])),
    )
  }
}

fn consume_object(
  input: List(Positioned(lexer.Token)),
  fields: List(#(String, node.Node)),
  next: fn(List(#(String, node.Node)), List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  use input <-
    fn(next) {
      case fields {
        [] -> next(input)
        _ ->
          case input {
            [Positioned(lexer.Comma, ..), ..rest] -> next(rest)
            [Positioned(lexer.RightCurlyBracket, ..), ..] -> next(input)
            [token, ..] -> #(
              ParserState([]),
              Failure(UnexpectedToken(
                [Token(lexer.Comma), Token(lexer.RightCurlyBracket)],
                token,
              )),
            )
            [] -> #(
              ParserState([]),
              Failure(
                UnexpectedEOF([
                  Token(lexer.Comma),
                  Token(lexer.RightCurlyBracket),
                ]),
              ),
            )
          }
      }
    }

  case input {
    [Positioned(lexer.RightCurlyBracket, ..), ..rest] -> next(fields, rest)
    [
      Positioned(lexer.Identifier(field), ..),
      Positioned(lexer.Colon, ..),
      ..rest
    ] -> {
      use expression, input <- consume_expression(rest)

      consume_object(input, list.append(fields, [#(field, expression)]), next)
    }
    [token, ..] -> #(
      ParserState([]),
      Failure(UnexpectedToken(
        [Token(lexer.Identifier("")), Token(lexer.RightCurlyBracket)],
        token,
      )),
    )
    [] -> #(
      ParserState([]),
      Failure(
        UnexpectedEOF([
          Token(lexer.Identifier("")),
          Token(lexer.RightCurlyBracket),
        ]),
      ),
    )
  }
}

fn consume_array(
  input: List(Positioned(lexer.Token)),
  values: List(node.Node),
  next: fn(List(node.Node), List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  use input <-
    fn(next) {
      case values {
        [] -> next(input)
        _ ->
          case input {
            [Positioned(lexer.Comma, ..), ..rest] -> next(rest)
            [Positioned(lexer.RightBracket, ..), ..] -> next(input)
            [token, ..] -> #(
              ParserState([]),
              Failure(UnexpectedToken(
                [Token(lexer.Comma), Token(lexer.RightBracket)],
                token,
              )),
            )
            [] -> #(
              ParserState([]),
              Failure(
                UnexpectedEOF([Token(lexer.Comma), Token(lexer.RightBracket)]),
              ),
            )
          }
      }
    }

  case input {
    [Positioned(lexer.RightBracket, ..), ..rest] -> next(values, rest)
    rest -> {
      use expression, input <- consume_expression(rest)

      consume_array(input, list.append(values, [expression]), next)
    }
  }
}

fn consume_lambda_parameters(
  parameters: List(String),
  input: List(Positioned(lexer.Token)),
  next: fn(List(String), List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  case input {
    [Positioned(lexer.Pipe, ..), ..] -> next(parameters, input)
    _ -> {
      case input {
        [Positioned(lexer.Parameter(param), ..), ..rest] -> {
          case rest {
            [Positioned(lexer.Comma, ..), ..rest] ->
              consume_lambda_parameters(
                list.append(parameters, [param]),
                rest,
                next,
              )
            _ -> next(list.append(parameters, [param]), rest)
          }
        }
        [value, ..] -> #(
          ParserState([]),
          Failure(UnexpectedToken([Token(lexer.Parameter(""))], value)),
        )
        [] -> #(
          ParserState([]),
          Failure(UnexpectedEOF([Token(lexer.Parameter(""))])),
        )
      }
    }
  }
}

fn consume_lambda(
  input: List(Positioned(lexer.Token)),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  use input <- consume_keyword(lexer.Pipe, input)
  use parameters, input <- consume_lambda_parameters([], input)
  use input <- consume_keyword(lexer.Pipe, input)
  use body, input <- consume_expression(input)

  next(node.Lambda(parameters: parameters, body: body), input)
}

fn consume_else_ifs(
  input: List(Positioned(lexer.Token)),
  accumulator: List(#(node.Node, node.Node)),
  next: fn(List(#(node.Node, node.Node)), List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  case input {
    [
      positioned.Positioned(lexer.Else, _, _),
      positioned.Positioned(lexer.If, _, _),
      ..input
    ] -> {
      use condition, input <- consume_expression(input)
      use input <- consume_keyword(lexer.LeftCurlyBracket, input)
      use expression, input <- consume_expression(input)
      use input <- consume_keyword(lexer.RightCurlyBracket, input)

      consume_else_ifs(input, [#(condition, expression), ..accumulator], next)
    }
    _ -> next(list.reverse(accumulator), input)
  }
}

fn consume_value(
  input: List(Positioned(lexer.Token)),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  // For now we only support string literals as expressions
  case input {
    [Positioned(lexer.None, ..), ..rest] -> next(node.None, rest)
    [Positioned(lexer.Asterisk, ..), ..rest] -> next(node.All, rest)
    [Positioned(lexer.Number(value), ..), ..rest] ->
      next(node.Number(value), rest)
    [Positioned(lexer.Parameter(value), ..), ..rest] ->
      next(node.Parameter(value), rest)
    [Positioned(lexer.String(value), ..), ..rest] ->
      next(node.Value(surreal_ql.String(value)), rest)
    [
      Positioned(lexer.Identifier(lhs), ..),
      Positioned(lexer.DoubleColon, ..),
      Positioned(lexer.Identifier(rhs), ..),
      Positioned(lexer.LeftParenthesis, ..),
      ..rest
    ] -> consume_function_call(option.Some(lhs), rhs, rest, next)
    [
      Positioned(lexer.Identifier(rhs), ..),
      Positioned(lexer.LeftParenthesis, ..),
      ..rest
    ] -> consume_function_call(option.None, rhs, rest, next)
    [Positioned(lexer.Identifier(value), ..), ..rest] ->
      next(node.Identifier(value), rest)
    [Positioned(lexer.LeftCurlyBracket, ..), ..rest] -> {
      use fields, input <- consume_object(rest, [])
      next(node.Object(fields), input)
    }
    [Positioned(lexer.LeftBracket, ..), ..rest] -> {
      use fields, input <- consume_array(rest, [])
      next(node.Array(fields), input)
    }
    [Positioned(lexer.LeftArrow, ..), ..] -> next(node.Self, input)
    [Positioned(lexer.RightArrow, ..), ..] -> next(node.Self, input)
    [Positioned(lexer.LeftRightArrow, ..), ..] -> next(node.Self, input)
    [Positioned(lexer.If, ..), ..rest] -> {
      use condition, input <- consume_expression(rest)
      use with_curly_bracket, input <- consume_keyword_one_of(
        [
          #(lexer.Then, False),
          #(lexer.LeftCurlyBracket, True),
        ],
        input,
      )
      use expression, input <- consume_expression(input)
      use input <-
        case with_curly_bracket {
          True -> consume_keyword(lexer.RightCurlyBracket, input, _)
          False -> fn(next) { next(input) }
        }
      use else_ifs, input <-
        case with_curly_bracket {
          True -> consume_else_ifs(input, [], _)
          False -> fn(next) { next([], input) }
        }
      use input <- consume_keyword(lexer.Else, input)
      use else_branch, input <- consume_expression(input)
      use input <-
        case with_curly_bracket {
          True -> consume_keyword(lexer.LeftCurlyBracket, input, _)
          False -> fn(next) { next(input) }
        }
      use input <- consume_keyword(lexer.End, input)
      use input <-
        case with_curly_bracket {
          True -> consume_keyword(lexer.RightCurlyBracket, input, _)
          False -> fn(next) { next(input) }
        }
      next(
        node.If(condition:, then_: expression, else_ifs:, else_: else_branch),
        input,
      )
    }
    [Positioned(lexer.Select, ..), ..] -> {
      use select, input <- consume_select(ParserState([]), input)
      next(select, input)
    }
    [Positioned(lexer.LeftParenthesis, ..), ..rest] -> {
      use expression, input <- consume_expression(rest)
      use input <- consume_keyword(lexer.RightParenthesis, input)
      next(node.WrappedNode(expression), input)
    }
    [Positioned(lexer.Pipe, ..), ..] -> {
      use lambda, input <- consume_lambda(input)
      next(lambda, input)
    }
    [token, ..] -> #(
      ParserState([]),
      Failure(UnexpectedToken([NodeExpression], token)),
    )
    [] -> #(ParserState([]), Failure(UnexpectedEOF([NodeExpression])))
  }
}

fn access_expression_loop(
  lhs: node.Node,
  input: List(Positioned(lexer.Token)),
  excluded: List(node.Operator),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  let is_access_allowed = !list.contains(excluded, node.Access)
  let is_relation_to_allowed = !list.contains(excluded, node.RelationTo)
  let is_relation_from_allowed = !list.contains(excluded, node.RelationFrom)
  let is_relation_to_from_allowed =
    !list.contains(excluded, node.RelationToFrom)
  let is_indexing_allowed = !list.contains(excluded, node.Indexing)
  let op = case input {
    [positioned.Positioned(lexer.RightArrow, _, _), ..rest]
      if is_relation_to_allowed
    -> {
      Ok(#(node.RelationTo, rest))
    }
    [positioned.Positioned(lexer.LeftArrow, _, _), ..rest]
      if is_relation_from_allowed
    -> {
      Ok(#(node.RelationFrom, rest))
    }
    [positioned.Positioned(lexer.LeftRightArrow, _, _), ..rest]
      if is_relation_to_from_allowed
    -> {
      Ok(#(node.RelationToFrom, rest))
    }
    [positioned.Positioned(lexer.Dot, _, _), ..rest] if is_access_allowed -> {
      Ok(#(node.Access, rest))
    }
    [positioned.Positioned(lexer.LeftBracket, _, _), ..rest]
      if is_indexing_allowed
    -> {
      Ok(#(node.Indexing, rest))
    }
    _ -> Error(Nil)
  }

  case op {
    Ok(#(node.Indexing, rest)) -> {
      use value, input <- consume_expression(rest)
      use input <- consume_keyword(lexer.RightBracket, input)

      or_expression_loop(
        node.BinaryOperator(lhs, node.Indexing, value),
        input,
        excluded,
        next,
      )
    }
    Ok(#(op, rest)) -> {
      use value, input <- consume_value(rest)

      or_expression_loop(
        node.BinaryOperator(lhs, op, value),
        input,
        excluded,
        next,
      )
    }
    _ -> next(lhs, input)
  }
}

fn relation_expression_loop(
  lhs: node.Node,
  input: List(Positioned(lexer.Token)),
  excluded: List(node.Operator),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  let is_less_or_equal_allowed = !list.contains(excluded, node.LessThanOrEqual)
  let is_less_allowed = !list.contains(excluded, node.LessThan)
  let is_greater_or_equal_allowed =
    !list.contains(excluded, node.GreaterThanOrEqual)
  let is_greater_allowed = !list.contains(excluded, node.GreaterThan)
  let is_inside_allowed = !list.contains(excluded, node.Inside)
  let op = case input {
    [positioned.Positioned(lexer.LeftAngleEqual, _, _), ..rest]
      if is_less_or_equal_allowed
    -> {
      Ok(#(node.LessThanOrEqual, rest))
    }
    [positioned.Positioned(lexer.LeftAngle, _, _), ..rest] if is_less_allowed -> {
      Ok(#(node.LessThan, rest))
    }
    [positioned.Positioned(lexer.RightAngleEqual, _, _), ..rest]
      if is_greater_or_equal_allowed
    -> {
      Ok(#(node.GreaterThanOrEqual, rest))
    }
    [positioned.Positioned(lexer.RightAngle, _, _), ..rest]
      if is_greater_allowed
    -> {
      Ok(#(node.GreaterThan, rest))
    }
    [positioned.Positioned(lexer.Inside, _, _), ..rest] if is_inside_allowed -> {
      Ok(#(node.Inside, rest))
    }
    _ -> Error(Nil)
  }

  case op {
    Ok(#(op, rest)) -> {
      use value, input <- consume_value(rest)
      use rhs, input <- access_expression_loop(value, input, excluded)
      or_expression_loop(
        node.BinaryOperator(lhs, op, rhs),
        input,
        excluded,
        next,
      )
    }
    _ -> access_expression_loop(lhs, input, excluded, next)
  }
}

fn equality_expression_loop(
  lhs: node.Node,
  input: List(Positioned(lexer.Token)),
  excluded: List(node.Operator),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  let is_equal_allowed = !list.contains(excluded, node.Equal)
  let is_not_equal_allowed = !list.contains(excluded, node.NotEqual)
  let op = case input {
    [positioned.Positioned(lexer.DoubleEqual, _, _), ..rest]
      | [positioned.Positioned(lexer.Equal, _, _), ..rest]
      | [positioned.Positioned(lexer.Is, _, _), ..rest]
      if is_equal_allowed
    -> {
      Ok(#(node.Equal, rest))
    }
    [
      positioned.Positioned(lexer.Is, _, _),
      positioned.Positioned(lexer.Not, _, _),
      ..rest
    ]
      | [positioned.Positioned(lexer.BangEqual, _, _), ..rest]
      if is_not_equal_allowed
    -> {
      Ok(#(node.NotEqual, rest))
    }
    _ -> Error(Nil)
  }

  case op {
    Ok(#(op, rest)) -> {
      use value, input <- consume_value(rest)
      use rhs, input <- relation_expression_loop(value, input, excluded)
      or_expression_loop(
        node.BinaryOperator(lhs, op, rhs),
        input,
        excluded,
        next,
      )
    }
    _ -> relation_expression_loop(lhs, input, excluded, next)
  }
}

fn and_expression_loop(
  lhs: node.Node,
  input: List(Positioned(lexer.Token)),
  excluded: List(node.Operator),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  let is_allowed = !list.contains(excluded, node.And)
  case input {
    [positioned.Positioned(lexer.DoubleAmpersand, _, _), ..rest]
      | [positioned.Positioned(lexer.And, _, _), ..rest]
      if is_allowed
    -> {
      use value, input <- consume_value(rest)
      use rhs, input <- equality_expression_loop(value, input, excluded)
      or_expression_loop(
        node.BinaryOperator(lhs, node.And, rhs),
        input,
        excluded,
        next,
      )
    }
    _ -> equality_expression_loop(lhs, input, excluded, next)
  }
}

fn or_expression_loop(
  lhs: node.Node,
  input: List(Positioned(lexer.Token)),
  excluded: List(node.Operator),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  let is_allowed = !list.contains(excluded, node.Or)
  case input {
    [positioned.Positioned(lexer.DoublePipe, _, _), ..rest]
      | [positioned.Positioned(lexer.Or, _, _), ..rest]
      if is_allowed
    -> {
      use value, input <- consume_value(rest)
      use rhs, input <- and_expression_loop(value, input, excluded)
      or_expression_loop(
        node.BinaryOperator(lhs, node.Or, rhs),
        input,
        excluded,
        next,
      )
    }
    _ -> and_expression_loop(lhs, input, excluded, next)
  }
}

fn consume_expression(
  input: List(Positioned(lexer.Token)),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  use value, input <- consume_value(input)

  // expression_loop(value, input, [], next)
  or_expression_loop(value, input, [], next)
}

fn consume_expression_excluding(
  input: List(Positioned(lexer.Token)),
  excluded: List(node.Operator),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  use value, input <- consume_value(input)

  // expression_loop(value, input, excluded, next)
  or_expression_loop(value, input, excluded, next)
}

fn consume_keyword(
  token: lexer.Token,
  input: List(Positioned(lexer.Token)),
  next: fn(List(Positioned(lexer.Token))) -> #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  case input {
    [Positioned(tk, ..), ..rest] if tk == token -> next(rest)
    [tk, ..] -> #(ParserState([]), Failure(UnexpectedToken([Token(token)], tk)))
    [] -> #(ParserState([]), Failure(UnexpectedEOF([Token(token)])))
  }
}

fn consume_keyword_one_of(
  token: List(#(lexer.Token, a)),
  input: List(Positioned(lexer.Token)),
  next: fn(a, List(Positioned(lexer.Token))) -> #(ParserState, ParserResult(b)),
) -> #(ParserState, ParserResult(b)) {
  case input {
    [tk, ..rest] ->
      case list.key_find(token, tk.value) {
        Ok(value) -> next(value, rest)
        Error(_) -> #(
          ParserState([]),
          Failure(UnexpectedToken(
            list.map(token, fn(pair) { Token(pair.0) }),
            tk,
          )),
        )
      }
    [] -> #(
      ParserState([]),
      Failure(UnexpectedEOF(list.map(token, fn(pair) { Token(pair.0) }))),
    )
  }
}

fn consume_single_type(
  input: List(Positioned(lexer.Token)),
  next: fn(surreal_type.SurrealType, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  case input {
    [
      Positioned(lexer.Identifier("record"), ..),
      Positioned(lexer.LeftAngle, ..),
      Positioned(lexer.Identifier(name), ..),
      Positioned(lexer.RightAngle, ..),
      ..rest
    ] -> next(surreal_type.Record(name), rest)
    [Positioned(lexer.Identifier("string"), ..), ..rest] ->
      next(surreal_type.String, rest)
    [Positioned(lexer.Identifier("datetime"), ..), ..rest] ->
      next(surreal_type.Datetime, rest)
    [Positioned(lexer.Identifier("int"), ..), ..rest] ->
      next(surreal_type.Int, rest)
    [Positioned(lexer.Identifier("float"), ..), ..rest] ->
      next(surreal_type.Float, rest)
    [Positioned(lexer.Identifier("bool"), ..), ..rest] ->
      next(surreal_type.Bool, rest)
    [Positioned(lexer.Identifier("object"), ..), ..rest] ->
      next(surreal_type.Object, rest)
    [Positioned(lexer.Identifier("array"), ..), ..rest] -> {
      use input <- consume_keyword(lexer.LeftAngle, rest)
      use inner, input <- consume_type(input)
      use input <- consume_keyword(lexer.RightAngle, input)
      next(surreal_type.Array(inner), input)
    }
    [
      Positioned(lexer.Identifier("geometry"), ..),
      Positioned(lexer.LeftAngle, ..),
      Positioned(lexer.Identifier("point"), ..),
      Positioned(lexer.RightAngle, ..),
      ..rest
    ] -> {
      next(surreal_type.Point, rest)
    }
    [Positioned(lexer.Identifier("none"), ..), ..rest] -> {
      use input <- consume_keyword(lexer.Pipe, rest)
      use type_, input <- consume_single_type(input)
      next(surreal_type.Option(type_), input)
    }
    [token, ..] -> #(
      ParserState([]),
      Failure(UnexpectedToken([NodeType], token)),
    )
    [] -> #(ParserState([]), Failure(UnexpectedEOF([NodeType])))
  }
}

fn consume_type(
  input: List(Positioned(lexer.Token)),
  next: fn(surreal_type.SurrealType, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  use type_, input <- consume_single_type(input)
  case input {
    [Positioned(lexer.Pipe, ..), ..input] -> {
      use input <- consume_keyword(lexer.Identifier("none"), input)
      next(surreal_type.Option(type_), input)
    }
    _ -> next(type_, input)
  }
}

fn consume_function_args(
  fields: List(node.Node),
  input: List(Positioned(lexer.Token)),
  next: fn(List(node.Node), List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  case input {
    [Positioned(lexer.RightParenthesis, ..), ..] -> next(fields, input)
    _ -> {
      use arg, input <- consume_expression(input)
      case input {
        [Positioned(lexer.Comma, ..), ..rest] ->
          consume_function_args(list.append(fields, [arg]), rest, next)
        _ -> next(list.append(fields, [arg]), input)
      }
    }
  }
}

fn consume_function_call(
  lhs: option.Option(String),
  rhs: String,
  input: List(Positioned(lexer.Token)),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  use args, input <- consume_function_args([], input)
  use input <- consume_keyword(lexer.RightParenthesis, input)

  next(node.FunctionCall(lhs, rhs, args), input)
}

fn on_token(
  expected: lexer.Token,
  input: List(Positioned(lexer.Token)),
  on_match: fn(List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(#(a, List(Positioned(lexer.Token))))),
  next: fn(option.Option(a), List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(b)),
) -> #(ParserState, ParserResult(b)) {
  case input {
    [tk, ..rest] if tk.value == expected ->
      case on_match(rest) {
        #(_, Next(data)) -> next(option.Some(data.0), data.1)
        #(state, EOF(data)) -> #(state, EOF(data))
        #(state, Failure(data)) -> #(state, Failure(data))
      }
    [_, ..] -> next(option.None, input)
    [] -> next(option.None, input)
  }
}

fn do_define_normal_table(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
  name: String,
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  use schema, input <- consume_keyword_one_of(
    [#(lexer.Schemafull, node.Schemafull), #(lexer.Schemaless, node.Schemaless)],
    input,
  )
  use as_, input <- on_token(lexer.As, input, fn(input) {
    use node, input <- consume_select(state, input)
    #(state, Next(#(node, input)))
  })
  use input <- consume_keyword(lexer.Permissions, input)
  use permissions, input <- consume_keyword_one_of(
    [#(lexer.Full, node.PermissionFull), #(lexer.None, node.PermissionNone)],
    input,
  )

  #(
    add_node(
      node.DefineTable(
        name: name,
        type_: node.NormalTable,
        schema: schema,
        permissions: [permissions],
        as_: as_,
      ),
      state,
    ),
    Next(input),
  )
}

/// TODO: Support for permission for
fn do_define_relation_table(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
  name: String,
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  use input <- consume_keyword(lexer.In, input)
  use in, input <- consume_identifier(input)
  use input <- consume_keyword(lexer.Out, input)
  use out, input <- consume_identifier(input)
  use schema, input <- consume_keyword_one_of(
    [#(lexer.Schemafull, node.Schemafull), #(lexer.Schemaless, node.Schemaless)],
    input,
  )
  use input <- consume_keyword(lexer.Permissions, input)
  use permissions, input <- consume_keyword_one_of(
    [#(lexer.Full, node.PermissionFull), #(lexer.None, node.PermissionNone)],
    input,
  )

  #(
    add_node(
      node.DefineTable(
        name: name,
        type_: node.RelationTable(in: in, out: out),
        schema: schema,
        permissions: [permissions],
        as_: option.None,
      ),
      state,
    ),
    Next(input),
  )
}

/// TODO: Support for permission for
fn do_define_table(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  use identifier, input <- consume_identifier(input)
  use input <- consume_keyword(lexer.Type, input)
  case input {
    [Positioned(lexer.Normal, ..), ..rest] ->
      do_define_normal_table(state, rest, identifier)
    [Positioned(lexer.Relation, ..), ..rest] ->
      do_define_relation_table(state, rest, identifier)
    [value, ..] -> #(
      state,
      Failure(UnexpectedToken(
        [Token(lexer.Normal), Token(lexer.Relation)],
        value,
      )),
    )
    [] -> #(
      state,
      Failure(UnexpectedEOF([Token(lexer.Normal), Token(lexer.Relation)])),
    )
  }
}

fn do_define_field(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  use name, input <- consume_expression(input)
  use input <- consume_keyword(lexer.On, input)
  use table, input <- consume_identifier(input)
  let #(input, flexible) = case input {
    [Positioned(lexer.Flexible, ..), ..rest] -> #(rest, True)
    _ -> #(input, False)
  }
  use input <- consume_keyword(lexer.Type, input)
  use type_, input <- consume_type(input)
  let #(input, flexible) = case input {
    [Positioned(lexer.Flexible, ..), ..rest] -> #(rest, True)
    _ -> #(input, flexible)
  }
  use default, input <- on_token(lexer.Default, input, fn(input) {
    use expression, input <- consume_expression(input)
    #(state, Next(#(expression, input)))
  })
  use assert_, input <- on_token(lexer.Assert, input, fn(input) {
    use expression, input <- consume_expression(input)
    #(state, Next(#(expression, input)))
  })
  use permissions, input <- on_token(lexer.Permissions, input, fn(input) {
    use permissions, input <- consume_keyword_one_of(
      [#(lexer.Full, node.PermissionFull), #(lexer.None, node.PermissionNone)],
      input,
    )
    #(state, Next(#(permissions, input)))
  })

  #(
    add_node(
      node.DefineField(
        name: name,
        table: table,
        type_: type_,
        default: default,
        assert_: assert_,
        permissions: permissions |> option.map(list.wrap) |> option.unwrap([]),
        flexible: flexible,
      ),
      state,
    ),
    Next(input),
  )
}

/// TODO: Support for permission for
fn do_define_index(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  use identifier, input <- consume_identifier(input)
  use input <- consume_keyword(lexer.On, input)
  use table, input <- consume_identifier(input)
  use input <- consume_keyword(lexer.Fields, input)
  // TODO: Support multiple fields
  use field, input <- consume_identifier(input)
  let #(input, unique) = case input {
    [Positioned(lexer.Unique, ..), ..rest] -> #(rest, True)
    _ -> #(input, False)
  }

  #(
    add_node(
      node.DefineIndex(
        name: identifier,
        table: table,
        fields: [field],
        unique: unique,
      ),
      state,
    ),
    Next(input),
  )
}

fn do_select_field(
  fields: List(node.SelectField),
  input: List(Positioned(lexer.Token)),
  next: fn(List(node.SelectField), List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  let #(value, input) = case input {
    [Positioned(lexer.Value, ..), ..rest] -> #(True, rest)
    _ -> #(False, input)
  }
  use field, input <- consume_expression(input)
  let #(alias, input) = case input {
    [Positioned(lexer.As, ..), Positioned(lexer.Identifier(alias), ..), ..rest] -> #(
      option.Some(alias),
      rest,
    )
    _ -> #(option.None, input)
  }
  case input {
    [Positioned(lexer.Comma, ..), ..rest] ->
      do_select_field(
        list.append(fields, [node.SelectField(field:, alias:, value:)]),
        rest,
        next,
      )
    _ ->
      next(
        list.append(fields, [
          node.SelectField(field:, alias:, value:),
        ]),
        input,
      )
  }
}

fn consume_select(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
  next: fn(node.Node, List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  // FIELDS
  use input <- consume_keyword(lexer.Select, input)
  use fields, input <- do_select_field([], input)
  use input <- consume_keyword(lexer.From, input)
  let #(only, input) = case input {
    [Positioned(lexer.Only, ..), ..rest] -> #(True, rest)
    _ -> #(False, input)
  }
  use table, input <- consume_identifier(input)
  use where, input <- on_token(lexer.Where, input, fn(input) {
    use expression, input <- consume_expression(input)
    #(state, Next(#(expression, input)))
  })
  use order, input <- on_token(lexer.Order, input, fn(input) {
    let input = case input {
      [Positioned(lexer.By, ..), ..rest] -> rest
      _ -> input
    }
    use order_field, input <- consume_expression(input)
    let token = list.first(input)
    let #(direction, input) = case token {
      Ok(Positioned(lexer.Desc, ..)) -> {
        let assert [_, ..rest] = input
        #(node.Descending, rest)
      }
      _ -> #(node.Ascending, input)
    }

    #(state, Next(#([#(order_field, direction)], input)))
  })
  use group_all, input <- on_token(lexer.Group, input, fn(input) {
    use input <- consume_keyword(lexer.All, input)
    #(state, Next(#(True, input)))
  })
  use limit, input <- on_token(lexer.Limit, input, fn(input) {
    use expression, input <- consume_expression(input)
    #(state, Next(#(expression, input)))
  })

  next(
    node.Select(
      fields: fields,
      only: only,
      table: table,
      where: where,
      order: order,
      limit: limit,
      group_all: option.unwrap(group_all, False),
    ),
    input,
  )
}

fn do_select(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  use node, input <- consume_select(state, input)

  #(add_node(node, state), Next(input))
}

fn do_update_set_field(
  set: List(node.Node),
  input: List(Positioned(lexer.Token)),
  next: fn(List(node.Node), List(Positioned(lexer.Token))) ->
    #(ParserState, ParserResult(a)),
) -> #(ParserState, ParserResult(a)) {
  use field, input <- consume_expression(input)
  case input {
    [Positioned(lexer.Comma, ..), ..rest] ->
      do_update_set_field(list.append(set, [field]), rest, next)
    _ -> next(list.append(set, [field]), input)
  }
}

fn do_update(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  let #(only, input) = case input {
    [Positioned(lexer.Only, ..), ..rest] -> #(True, rest)
    _ -> #(False, input)
  }
  use target, input <- consume_identifier(input)
  use input <- consume_keyword(lexer.Set, input)
  use set, input <- do_update_set_field([], input)
  use where, input <- on_token(lexer.Where, input, fn(input) {
    use expression, input <- consume_expression(input)
    #(state, Next(#(expression, input)))
  })

  #(add_node(node.Update(only:, target:, set:, where:), state), Next(input))
}

fn do_create(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  let #(only, input) = case input {
    [Positioned(lexer.Only, ..), ..rest] -> #(True, rest)
    _ -> #(False, input)
  }
  use target, input <- consume_identifier(input)
  use input <- consume_keyword(lexer.Set, input)
  use set, input <- do_update_set_field([], input)

  #(add_node(node.Create(only:, target:, set:), state), Next(input))
}

fn do_delete(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  let input = case input {
    [Positioned(lexer.From, ..), ..rest] -> rest
    _ -> input
  }
  let #(only, input) = case input {
    [Positioned(lexer.Only, ..), ..rest] -> #(True, rest)
    _ -> #(False, input)
  }
  use target, input <- consume_expression(input)
  use where, input <- on_token(lexer.Where, input, fn(input) {
    use expression, input <- consume_expression(input)
    #(state, Next(#(expression, input)))
  })

  #(add_node(node.Delete(only:, target:, where:), state), Next(input))
}

fn do_relate(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  use from, input <- consume_expression_excluding(input, [node.RelationTo])
  use input <- consume_keyword(lexer.RightArrow, input)
  use table, input <- consume_identifier(input)
  use input <- consume_keyword(lexer.RightArrow, input)
  use to, input <- consume_expression(input)

  use set, input <- on_token(lexer.Set, input, fn(input) {
    use set, input <- do_update_set_field([], input)

    #(state, Next(#(set, input)))
  })

  #(
    add_node(
      node.Relate(
        table: table,
        from: from,
        to: to,
        set: set |> option.unwrap([]),
      ),
      state,
    ),
    Next(input),
  )
}

fn next(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> #(ParserState, ParserResult(List(Positioned(lexer.Token)))) {
  case input {
    [Positioned(lexer.Semicolon, ..)] | [] -> #(state, EOF(state.ast))
    _ -> {
      let next = fn(input: List(Positioned(lexer.Token))) {
        case input {
          [] -> panic as "Unexpected end of input"
          [Positioned(lexer.Define, ..), Positioned(lexer.Table, ..), ..rest] ->
            do_define_table(state, rest)
          [Positioned(lexer.Define, ..), Positioned(lexer.Field, ..), ..rest] ->
            do_define_field(state, rest)
          [Positioned(lexer.Define, ..), Positioned(lexer.Index, ..), ..rest] ->
            do_define_index(state, rest)
          [Positioned(lexer.Select, ..), ..] -> do_select(state, input)
          [Positioned(lexer.Update, ..), ..rest] -> do_update(state, rest)
          [Positioned(lexer.Create, ..), ..rest] -> do_create(state, rest)
          [Positioned(lexer.Delete, ..), ..rest] -> do_delete(state, rest)
          [Positioned(lexer.Relate, ..), ..rest] -> do_relate(state, rest)
          [token, ..] -> #(
            state,
            Failure(UnexpectedToken(
              [
                Token(lexer.Define),
                Token(lexer.Select),
                Token(lexer.Update),
                Token(lexer.Relate),
              ],
              token,
            )),
          )
        }
      }

      case state.ast {
        [] -> next(input)
        _ -> {
          use input <- consume_keyword(lexer.Semicolon, input)
          next(input)
        }
      }
    }
  }
}

fn do_parse(
  state: ParserState,
  input: List(Positioned(lexer.Token)),
) -> Result(List(node.Node), ParserError) {
  case next(state, input) {
    #(_, EOF(ast)) -> Ok(ast)
    #(_, Failure(error)) -> Error(error)
    #(new_state, Next(rest)) -> do_parse(new_state, rest)
  }
}

pub fn parse(
  input: List(Positioned(lexer.Token)),
) -> Result(List(node.Node), ParserError) {
  do_parse(ParserState([]), input)
}

pub fn render_error(error: ParserError, content: String) -> String {
  case error {
    UnexpectedToken(expected:, actual:) -> {
      positioned.render(actual, content)
      <> "\n\n"
      <> "Unexpected token: "
      <> string.inspect(actual.value)
      <> "\nExpected one of: "
      <> string.join(
        list.map(expected, fn(e) {
          case e {
            NodeExpression -> "NodeExpression"
            NodeType -> "NodeType"
            Token(token) -> "Token(" <> string.inspect(token) <> ")"
          }
        }),
        ", ",
      )
    }
    UnexpectedEOF(expected:) -> {
      "Unexpected end of file\nExpected one of: "
      <> string.join(
        list.map(expected, fn(e) {
          case e {
            NodeExpression -> "NodeExpression"
            NodeType -> "NodeType"
            Token(token) -> "Token(" <> string.inspect(token) <> ")"
          }
        }),
        ", ",
      )
    }
  }
}
