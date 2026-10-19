import gleam/float
import gleam/int
import gleam/list
import gleam/string
import positioned.{type Position, type Positioned, Positioned}

pub type Token {
  // Keywords
  And
  All
  AllInside
  AnyInside
  As
  Assert
  By
  Contains
  ContainsNot
  ContainsAll
  ContainsAny
  ContainsNone
  Count
  Create
  Default
  Define
  Delete
  Desc
  Else
  End
  Field
  Fields
  Flexible
  From
  Group
  If
  In
  Index
  Inside
  Intersect
  Is
  Limit
  NoneInside
  Not
  NotInside
  Normal
  On
  Only
  Or
  Order
  Out
  Outside
  Permissions
  Relation
  Relate
  Schemafull
  Schemaless
  Select
  Set
  Table
  Then
  Type
  Unique
  Update
  Value
  Where

  // Keywords as value
  Full
  None

  // Symbols
  Asterisk
  AsteriskEqual
  AsteriskTilde
  DoubleAsterisk
  Comma
  Semicolon
  Pipe
  Colon
  DoubleColon
  LeftParenthesis
  RightParenthesis
  RightAngle
  LeftAngle
  RightAngleEqual
  LeftAngleEqual
  Equal
  DoubleEqual
  LeftCurlyBracket
  RightCurlyBracket
  Dot
  LeftBracket
  LeftArrow
  LeftRightArrow
  RightBracket
  RightArrow
  DoubleAmpersand
  DoublePipe
  Bang
  DoubleBang
  BangEqual
  BangTilde
  DoubleQuestion
  QuestionColon
  QuestionTilde
  Tilde
  Plus
  Multiply
  Slash
  Divide

  // Literals
  Parameter(String)
  Identifier(String)
  Reference(String, String)
  String(String)
  Number(Float)
}

pub type LexerError {
  UnexpectedCharacter(message: String, position: Position)
  UnexpectedFormat(message: String, position: Position)
}

type LexerState {
  LexerState(
    position: Position,
    last_position: Position,
    tokens: List(Positioned(Token)),
  )
}

fn advance(state: LexerState, token: String) -> LexerState {
  LexerState(..state, position: positioned.advance(state.position, token))
}

fn add_token(state: LexerState, token: Token) -> LexerState {
  LexerState(
    ..state,
    last_position: state.position,
    tokens: list.append(state.tokens, [
      Positioned(token, state.last_position, state.position),
    ]),
  )
}

fn discard(state: LexerState, token: String) -> LexerState {
  let state = advance(state, token)
  LexerState(..state, last_position: state.position)
}

type LexerResult {
  Failure(LexerError)
  EOF(List(Positioned(Token)))
  Next(String)
}

fn discard_comment(
  state: LexerState,
  input: String,
) -> #(LexerState, LexerResult) {
  case input {
    "" -> #(state, EOF(state.tokens))
    "\n" <> remaining -> #(advance(state, "\n"), Next(remaining))
    _ ->
      case string.pop_grapheme(input) {
        Error(_) -> #(state, EOF(state.tokens))
        Ok(#(value, remaining)) ->
          discard_comment(advance(state, value), remaining)
      }
  }
}

type IdentifierProcessingMode {
  IdentifierMode
  ParameterMode
  ReferenceMode(String)
}

fn do_end_identifier(
  state: LexerState,
  buffer: String,
  mode: IdentifierProcessingMode,
) -> LexerState {
  case mode, buffer {
    ParameterMode, _ ->
      state |> add_token(Parameter(string.drop_start(buffer, 1)))
    ReferenceMode(lhs), _ ->
      state |> add_token(Reference(lhs, string.drop_start(buffer, 1)))
    _, "AND" -> state |> add_token(And)
    _, "ALLINSIDE" -> state |> add_token(AllInside)
    _, "ALL" -> state |> add_token(All)
    _, "ANYINSIDE" -> state |> add_token(AnyInside)
    _, "AS" -> state |> add_token(As)
    _, "ASSERT" -> state |> add_token(Assert)
    _, "BY" -> state |> add_token(By)
    _, "CONTAINS" -> state |> add_token(Contains)
    _, "CONTAINSNOT" -> state |> add_token(ContainsNot)
    _, "CONTAINSALL" -> state |> add_token(ContainsAll)
    _, "CONTAINSANY" -> state |> add_token(ContainsAny)
    _, "CONTAINSNONE" -> state |> add_token(ContainsNone)
    _, "COUNT" -> state |> add_token(Count)
    _, "CREATE" -> state |> add_token(Create)
    _, "DEFAULT" -> state |> add_token(Default)
    _, "DEFINE" -> state |> add_token(Define)
    _, "DELETE" -> state |> add_token(Delete)
    _, "DESC" -> state |> add_token(Desc)
    _, "ELSE" -> state |> add_token(Else)
    _, "END" -> state |> add_token(End)
    _, "FIELD" -> state |> add_token(Field)
    _, "FIELDS" -> state |> add_token(Fields)
    _, "FLEXIBLE" -> state |> add_token(Flexible)
    _, "GROUP" -> state |> add_token(Group)
    _, "FROM" -> state |> add_token(From)
    _, "FULL" -> state |> add_token(Full)
    _, "IF" -> state |> add_token(If)
    _, "IN" -> state |> add_token(In)
    _, "INDEX" -> state |> add_token(Index)
    _, "INSIDE" -> state |> add_token(Inside)
    _, "INTERSECT" -> state |> add_token(Intersect)
    _, "IS" -> state |> add_token(Is)
    _, "LIMIT" -> state |> add_token(Limit)
    _, "NOT" -> state |> add_token(Not)
    _, "NOTINSIDE" -> state |> add_token(NotInside)
    _, "NORMAL" -> state |> add_token(Normal)
    _, "NONE" -> state |> add_token(None)
    _, "NONEINSIDE" -> state |> add_token(NoneInside)
    _, "ON" -> state |> add_token(On)
    _, "ONLY" -> state |> add_token(Only)
    _, "ORDER" -> state |> add_token(Order)
    _, "OR" -> state |> add_token(Or)
    _, "OUT" -> state |> add_token(Out)
    _, "OUTSIDE" -> state |> add_token(Outside)
    _, "PERMISSIONS" -> state |> add_token(Permissions)
    _, "RELATION" -> state |> add_token(Relation)
    _, "RELATE" -> state |> add_token(Relate)
    _, "SCHEMAFULL" -> state |> add_token(Schemafull)
    _, "SCHEMALESS" -> state |> add_token(Schemaless)
    _, "SELECT" -> state |> add_token(Select)
    _, "SET" -> state |> add_token(Set)
    _, "TABLE" -> state |> add_token(Table)
    _, "THEN" -> state |> add_token(Then)
    _, "TYPE" -> state |> add_token(Type)
    _, "UNIQUE" -> state |> add_token(Unique)
    _, "UPDATE" -> state |> add_token(Update)
    _, "VALUE" -> state |> add_token(Value)
    _, "WHERE" -> state |> add_token(Where)
    _, _ -> state |> add_token(Identifier(buffer))
  }
}

fn do_identifier(
  state: LexerState,
  input: String,
  buffer: String,
  mode: IdentifierProcessingMode,
) -> #(LexerState, LexerResult) {
  case string.pop_grapheme(input) {
    Error(_) -> {
      let state = do_end_identifier(state, buffer, mode)
      #(state, EOF(state.tokens))
    }
    Ok(#(grapheme, remaining)) ->
      case mode, grapheme {
        // IdentifierMode, ":" ->
        //   do_identifier(advance(state), remaining, "", ReferenceMode(buffer))
        _, "a"
        | _, "b"
        | _, "c"
        | _, "d"
        | _, "e"
        | _, "f"
        | _, "g"
        | _, "h"
        | _, "i"
        | _, "j"
        | _, "k"
        | _, "l"
        | _, "m"
        | _, "n"
        | _, "o"
        | _, "p"
        | _, "q"
        | _, "r"
        | _, "s"
        | _, "t"
        | _, "u"
        | _, "v"
        | _, "w"
        | _, "x"
        | _, "y"
        | _, "z"
        | _, "A"
        | _, "B"
        | _, "C"
        | _, "D"
        | _, "E"
        | _, "F"
        | _, "G"
        | _, "H"
        | _, "I"
        | _, "J"
        | _, "K"
        | _, "L"
        | _, "M"
        | _, "N"
        | _, "O"
        | _, "P"
        | _, "Q"
        | _, "R"
        | _, "S"
        | _, "T"
        | _, "U"
        | _, "V"
        | _, "W"
        | _, "X"
        | _, "Y"
        | _, "Z"
        | _, "0"
        | _, "1"
        | _, "2"
        | _, "3"
        | _, "4"
        | _, "5"
        | _, "6"
        | _, "7"
        | _, "8"
        | _, "9"
        | _, "_"
        ->
          do_identifier(
            advance(state, grapheme),
            remaining,
            buffer <> grapheme,
            mode,
          )
        _, _ -> #(do_end_identifier(state, buffer, mode), Next(input))
      }
  }
}

fn do_string(
  state: LexerState,
  input: String,
  buffer: String,
  single: Bool,
) -> #(LexerState, LexerResult) {
  case string.pop_grapheme(input) {
    Error(_) -> #(state, Failure(UnexpectedCharacter("EOF", state.position)))
    Ok(#(grapheme, remaining)) ->
      case grapheme {
        "'" if single -> #(
          advance(state, "'") |> add_token(String(buffer)),
          Next(remaining),
        )
        "\"" if !single -> #(
          advance(state, "\"") |> add_token(String(buffer)),
          Next(remaining),
        )
        _ ->
          do_string(
            advance(state, grapheme),
            remaining,
            buffer <> grapheme,
            single,
          )
      }
  }
}

fn do_number(
  state: LexerState,
  input: String,
  buffer: String,
) -> #(LexerState, LexerResult) {
  case string.pop_grapheme(input) {
    Error(_) ->
      case float.parse(buffer) {
        Error(_) ->
          case int.parse(buffer) {
            Error(_) -> #(
              state,
              Failure(UnexpectedFormat(buffer, state.position)),
            )
            Ok(number) -> #(
              state,
              EOF(
                list.append(state.tokens, [
                  Positioned(
                    Number(int.to_float(number)),
                    state.last_position,
                    state.position,
                  ),
                ]),
              ),
            )
          }
        Ok(number) -> #(
          state,
          EOF(
            list.append(state.tokens, [
              Positioned(Number(number), state.last_position, state.position),
            ]),
          ),
        )
      }
    Ok(#(grapheme, remaining)) ->
      case grapheme {
        "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "." ->
          do_number(advance(state, grapheme), remaining, buffer <> grapheme)
        _ ->
          case float.parse(buffer) {
            Error(_) ->
              case int.parse(buffer) {
                Error(_) -> #(
                  state,
                  Failure(UnexpectedFormat(buffer, state.position)),
                )
                Ok(number) -> #(
                  state |> add_token(Number(int.to_float(number))),
                  Next(input),
                )
              }
            Ok(number) -> #(state |> add_token(Number(number)), Next(input))
          }
      }
  }
}

fn next(state: LexerState, input: String) -> #(LexerState, LexerResult) {
  case input {
    // Comments
    "--" <> rest -> discard_comment(state, rest)

    // Identifier / Keyword
    "a" <> _
    | "b" <> _
    | "c" <> _
    | "d" <> _
    | "e" <> _
    | "f" <> _
    | "g" <> _
    | "h" <> _
    | "i" <> _
    | "j" <> _
    | "k" <> _
    | "l" <> _
    | "m" <> _
    | "n" <> _
    | "o" <> _
    | "p" <> _
    | "q" <> _
    | "r" <> _
    | "s" <> _
    | "t" <> _
    | "u" <> _
    | "v" <> _
    | "w" <> _
    | "x" <> _
    | "y" <> _
    | "z" <> _
    | "A" <> _
    | "B" <> _
    | "C" <> _
    | "D" <> _
    | "E" <> _
    | "F" <> _
    | "G" <> _
    | "H" <> _
    | "I" <> _
    | "J" <> _
    | "K" <> _
    | "L" <> _
    | "M" <> _
    | "N" <> _
    | "O" <> _
    | "P" <> _
    | "Q" <> _
    | "R" <> _
    | "S" <> _
    | "T" <> _
    | "U" <> _
    | "V" <> _
    | "W" <> _
    | "X" <> _
    | "Y" <> _
    | "Z" <> _
    | "_" <> _ -> do_identifier(state, input, "", IdentifierMode)

    // Parameter
    "$" <> rest ->
      do_identifier(state |> advance("$"), rest, "$", ParameterMode)

    // String
    "'" <> rest -> do_string(advance(state, "'"), rest, "", True)
    "\"" <> rest -> do_string(advance(state, "\""), rest, "", False)

    // Number
    "0" <> _
    | "1" <> _
    | "2" <> _
    | "3" <> _
    | "4" <> _
    | "5" <> _
    | "6" <> _
    | "7" <> _
    | "8" <> _
    | "9" <> _ -> do_number(state, input, "")

    // Symbols
    "->" <> rest -> #(advance(state, "->") |> add_token(RightArrow), Next(rest))
    "<->" <> rest -> #(
      advance(state, "<->") |> add_token(LeftRightArrow),
      Next(rest),
    )
    "<-" <> rest -> #(advance(state, "<-") |> add_token(LeftArrow), Next(rest))
    "**" <> rest -> #(
      advance(state, "**") |> add_token(DoubleAsterisk),
      Next(rest),
    )
    "*=" <> rest -> #(
      advance(state, "*=") |> add_token(AsteriskEqual),
      Next(rest),
    )
    "*~" <> rest -> #(
      advance(state, "*~") |> add_token(AsteriskTilde),
      Next(rest),
    )
    "*" <> rest -> #(advance(state, "*") |> add_token(Asterisk), Next(rest))
    "," <> rest -> #(advance(state, ",") |> add_token(Comma), Next(rest))
    ";" <> rest -> #(advance(state, ";") |> add_token(Semicolon), Next(rest))
    "&&" <> rest -> #(
      advance(state, "&&") |> add_token(DoubleAmpersand),
      Next(rest),
    )
    "||" <> rest -> #(advance(state, "||") |> add_token(DoublePipe), Next(rest))
    "|" <> rest -> #(advance(state, "|") |> add_token(Pipe), Next(rest))
    "::" <> rest -> #(
      advance(state, "::") |> add_token(DoubleColon),
      Next(rest),
    )
    ":" <> rest -> #(advance(state, ":") |> add_token(Colon), Next(rest))
    "(" <> rest -> #(
      advance(state, "(") |> add_token(LeftParenthesis),
      Next(rest),
    )
    ")" <> rest -> #(
      advance(state, ")") |> add_token(RightParenthesis),
      Next(rest),
    )
    ">=" <> rest -> #(
      advance(state, ">=") |> add_token(RightAngleEqual),
      Next(rest),
    )
    "<=" <> rest -> #(
      advance(state, "<=") |> add_token(LeftAngleEqual),
      Next(rest),
    )
    ">" <> rest -> #(advance(state, ">") |> add_token(RightAngle), Next(rest))
    "<" <> rest -> #(advance(state, "<") |> add_token(LeftAngle), Next(rest))
    "==" <> rest -> #(
      advance(state, "==") |> add_token(DoubleEqual),
      Next(rest),
    )
    "=" <> rest -> #(advance(state, "=") |> add_token(Equal), Next(rest))
    "{" <> rest -> #(
      advance(state, "{") |> add_token(LeftCurlyBracket),
      Next(rest),
    )
    "}" <> rest -> #(
      advance(state, "}") |> add_token(RightCurlyBracket),
      Next(rest),
    )
    "." <> rest -> #(advance(state, ".") |> add_token(Dot), Next(rest))
    "[" <> rest -> #(advance(state, "[") |> add_token(LeftBracket), Next(rest))
    "]" <> rest -> #(advance(state, "]") |> add_token(RightBracket), Next(rest))
    "!!" <> rest -> #(advance(state, "!!") |> add_token(DoubleBang), Next(rest))
    "!=" <> rest -> #(advance(state, "!=") |> add_token(BangEqual), Next(rest))
    "!~" <> rest -> #(advance(state, "!~") |> add_token(BangTilde), Next(rest))
    "!" <> rest -> #(advance(state, "!") |> add_token(Bang), Next(rest))
    "??" <> rest -> #(
      advance(state, "??") |> add_token(DoubleQuestion),
      Next(rest),
    )
    "?:" <> rest -> #(
      advance(state, "?:") |> add_token(QuestionColon),
      Next(rest),
    )
    "?~" <> rest -> #(
      advance(state, "?~") |> add_token(QuestionTilde),
      Next(rest),
    )
    "~" <> rest -> #(advance(state, "~") |> add_token(Tilde), Next(rest))
    "+" <> rest -> #(advance(state, "+") |> add_token(Plus), Next(rest))
    "×" <> rest -> #(advance(state, "×") |> add_token(Multiply), Next(rest))
    "/" <> rest -> #(advance(state, "/") |> add_token(Slash), Next(rest))
    "÷" <> rest -> #(advance(state, "÷") |> add_token(Divide), Next(rest))
    "∋" <> rest -> #(advance(state, "∋") |> add_token(Contains), Next(rest))
    "∌" <> rest -> #(advance(state, "∌") |> add_token(ContainsNot), Next(rest))
    "⊇" <> rest -> #(advance(state, "⊇") |> add_token(ContainsAll), Next(rest))
    "⊃" <> rest -> #(advance(state, "⊃") |> add_token(ContainsAny), Next(rest))
    "⊅" <> rest -> #(advance(state, "⊅") |> add_token(ContainsNone), Next(rest))
    "∈" <> rest -> #(advance(state, "∈") |> add_token(Inside), Next(rest))
    "∉" <> rest -> #(advance(state, "∉") |> add_token(NotInside), Next(rest))
    "⊆" <> rest -> #(advance(state, "⊆") |> add_token(AllInside), Next(rest))
    "⊂" <> rest -> #(advance(state, "⊂") |> add_token(AnyInside), Next(rest))
    "⊄" <> rest -> #(advance(state, "⊄") |> add_token(NoneInside), Next(rest))

    // Whitesapce
    " " <> rest -> #(discard(state, " "), Next(rest))
    "\n" <> rest -> #(discard(state, "\n"), Next(rest))
    "\t" <> rest -> #(discard(state, "\t"), Next(rest))

    // Else
    _ ->
      case string.pop_grapheme(input) {
        Error(_) -> #(state, EOF(state.tokens))
        Ok(#(grapheme, _)) -> #(
          state,
          Failure(UnexpectedCharacter(grapheme, state.position)),
        )
      }
  }
}

fn do_lex(
  state: LexerState,
  input: String,
) -> Result(List(Positioned(Token)), LexerError) {
  case next(state, input) {
    #(_, EOF(tokens)) -> Ok(tokens)
    #(_, Failure(error)) -> Error(error)
    #(new_state, Next(remaining)) -> do_lex(new_state, remaining)
  }
}

pub fn tokenize(
  file: String,
  input: String,
) -> Result(List(Positioned(Token)), LexerError) {
  let pos = positioned.Position(file, 0, 1, 1)
  do_lex(LexerState(pos, pos, []), input)
}

pub fn split_statements(tokens: List(Token)) -> List(List(Token)) {
  let #(statements, current) =
    list.fold(tokens, #([], []), fn(entry, token) {
      let #(statements, current) = entry
      case token {
        Semicolon -> #(list.append(statements, [current]), [])
        _ -> #(statements, list.append(current, [token]))
      }
    })

  case current {
    [] -> statements
    _ -> list.append(statements, [current])
  }
}

pub fn render_error(error: LexerError, content: String) -> String {
  positioned.render(
    positioned.Positioned(Nil, error.position, error.position),
    content,
  )
  <> "\n\n"
  <> error.message
}
