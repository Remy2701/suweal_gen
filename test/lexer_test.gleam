import lexer
import positioned

//-----------------------------------------------------------------------------------------------//
//                                            Keyword                                            //
//-----------------------------------------------------------------------------------------------//

pub fn lexer_token_and_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "AND")
  assert tokens
    == [
      positioned.Positioned(
        lexer.And,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 3, 1, 4),
      ),
    ]
}

pub fn lexer_token_lowercase_and_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "and")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Identifier("and"),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 3, 1, 4),
      ),
    ]
}

pub fn lexer_token_algorithm_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "ALGORITHM")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Algorithm,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 9, 1, 10),
      ),
    ]
}

pub fn lexer_token_all_inside_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "ALLINSIDE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.AllInside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 9, 1, 10),
      ),
    ]
}

pub fn lexer_token_all_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "ALL")
  assert tokens
    == [
      positioned.Positioned(
        lexer.All,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 3, 1, 4),
      ),
    ]
}

pub fn lexer_token_any_inside_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "ANYINSIDE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.AnyInside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 9, 1, 10),
      ),
    ]
}

pub fn lexer_token_as_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "AS")
  assert tokens
    == [
      positioned.Positioned(
        lexer.As,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_assert_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "ASSERT")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Assert,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_by_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "BY")
  assert tokens
    == [
      positioned.Positioned(
        lexer.By,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_contains_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "CONTAINS")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Contains,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 8, 1, 9),
      ),
    ]
}

pub fn lexer_token_contains_not_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "CONTAINSNOT")
  assert tokens
    == [
      positioned.Positioned(
        lexer.ContainsNot,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 11, 1, 12),
      ),
    ]
}

pub fn lexer_token_contains_all_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "CONTAINSALL")
  assert tokens
    == [
      positioned.Positioned(
        lexer.ContainsAll,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 11, 1, 12),
      ),
    ]
}

pub fn lexer_token_contains_any_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "CONTAINSANY")
  assert tokens
    == [
      positioned.Positioned(
        lexer.ContainsAny,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 11, 1, 12),
      ),
    ]
}

pub fn lexer_token_contains_none_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "CONTAINSNONE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.ContainsNone,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 12, 1, 13),
      ),
    ]
}

pub fn lexer_token_count_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "COUNT")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Count,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

pub fn lexer_token_create_none_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "CREATE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Create,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_default_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "DEFAULT")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Default,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 7, 1, 8),
      ),
    ]
}

pub fn lexer_token_define_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "DEFINE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Define,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_delete_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "DELETE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Delete,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_desc_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "DESC")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Desc,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 4, 1, 5),
      ),
    ]
}

pub fn lexer_token_else_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "ELSE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Else,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 4, 1, 5),
      ),
    ]
}

pub fn lexer_token_end_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "END")
  assert tokens
    == [
      positioned.Positioned(
        lexer.End,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 3, 1, 4),
      ),
    ]
}

pub fn lexer_token_field_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "FIELD")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Field,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

pub fn lexer_token_fields_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "FIELDS")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Fields,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_flexible_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "FLEXIBLE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Flexible,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 8, 1, 9),
      ),
    ]
}

pub fn lexer_token_from_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "FROM")
  assert tokens
    == [
      positioned.Positioned(
        lexer.From,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 4, 1, 5),
      ),
    ]
}

pub fn lexer_token_group_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "GROUP")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Group,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

pub fn lexer_token_if_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "IF")
  assert tokens
    == [
      positioned.Positioned(
        lexer.If,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_in_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "IN")
  assert tokens
    == [
      positioned.Positioned(
        lexer.In,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_index_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "INDEX")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Index,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

pub fn lexer_token_inside_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "INSIDE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Inside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_intersect_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "INTERSECT")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Intersect,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 9, 1, 10),
      ),
    ]
}

pub fn lexer_token_is_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "IS")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Is,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_limit_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "LIMIT")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Limit,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

pub fn lexer_token_none_inside_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "NONEINSIDE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.NoneInside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 10, 1, 11),
      ),
    ]
}

pub fn lexer_token_not_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "NOT")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Not,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 3, 1, 4),
      ),
    ]
}

pub fn lexer_token_not_inside_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "NOTINSIDE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.NotInside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 9, 1, 10),
      ),
    ]
}

pub fn lexer_token_normal_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "NORMAL")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Normal,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_on_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "ON")
  assert tokens
    == [
      positioned.Positioned(
        lexer.On,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_only_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "ONLY")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Only,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 4, 1, 5),
      ),
    ]
}

pub fn lexer_token_or_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "OR")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Or,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_order_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "ORDER")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Order,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

pub fn lexer_token_out_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "OUT")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Out,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 3, 1, 4),
      ),
    ]
}

pub fn lexer_token_outside_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "OUTSIDE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Outside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 7, 1, 8),
      ),
    ]
}

pub fn lexer_token_permissions_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "PERMISSIONS")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Permissions,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 11, 1, 12),
      ),
    ]
}

pub fn lexer_token_relation_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "RELATION")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Relation,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 8, 1, 9),
      ),
    ]
}

pub fn lexer_token_schemafull_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "SCHEMAFULL")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Schemafull,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 10, 1, 11),
      ),
    ]
}

pub fn lexer_token_select_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "SELECT")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Select,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_set_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "SET")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Set,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 3, 1, 4),
      ),
    ]
}

pub fn lexer_token_table_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "TABLE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Table,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

pub fn lexer_token_then_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "THEN")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Then,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 4, 1, 5),
      ),
    ]
}

pub fn lexer_token_type_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "TYPE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Type,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 4, 1, 5),
      ),
    ]
}

pub fn lexer_token_unique_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "UNIQUE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Unique,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_update_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "UPDATE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Update,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 6, 1, 7),
      ),
    ]
}

pub fn lexer_token_value_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "VALUE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Value,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

pub fn lexer_token_where_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "WHERE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Where,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

//-----------------------------------------------------------------------------------------------//
//                                       Keyword as value                                        //
//-----------------------------------------------------------------------------------------------//

pub fn lexer_token_full_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "FULL")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Full,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 4, 1, 5),
      ),
    ]
}

pub fn lexer_token_none_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "NONE")
  assert tokens
    == [
      positioned.Positioned(
        lexer.None,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 4, 1, 5),
      ),
    ]
}

//-----------------------------------------------------------------------------------------------//
//                                      Symbols as keywords                                      //
//-----------------------------------------------------------------------------------------------//

pub fn lexer_token_contains_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "∋")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Contains,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_contains_not_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "∌")
  assert tokens
    == [
      positioned.Positioned(
        lexer.ContainsNot,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_contains_all_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "⊇")
  assert tokens
    == [
      positioned.Positioned(
        lexer.ContainsAll,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_contains_any_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "⊃")
  assert tokens
    == [
      positioned.Positioned(
        lexer.ContainsAny,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_contains_none_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "⊅")
  assert tokens
    == [
      positioned.Positioned(
        lexer.ContainsNone,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_contains_inside_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "∈")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Inside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_contains_not_inside_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "∉")
  assert tokens
    == [
      positioned.Positioned(
        lexer.NotInside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_contains_all_inside_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "⊆")
  assert tokens
    == [
      positioned.Positioned(
        lexer.AllInside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_contains_any_inside_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "⊂")
  assert tokens
    == [
      positioned.Positioned(
        lexer.AnyInside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_contains_none_inside_symbol_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "⊄")
  assert tokens
    == [
      positioned.Positioned(
        lexer.NoneInside,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

//-----------------------------------------------------------------------------------------------//
//                                            Symbols                                            //
//-----------------------------------------------------------------------------------------------//

pub fn lexer_token_asterisk_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "*")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Asterisk,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_asterisk_equal_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "*=")
  assert tokens
    == [
      positioned.Positioned(
        lexer.AsteriskEqual,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_asterisk_tilde_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "*~")
  assert tokens
    == [
      positioned.Positioned(
        lexer.AsteriskTilde,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_double_asterisk_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "**")
  assert tokens
    == [
      positioned.Positioned(
        lexer.DoubleAsterisk,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_comma_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, ",")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Comma,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_semicolon_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, ";")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Semicolon,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_pipe_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "|")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Pipe,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_colon_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, ":")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Colon,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_double_colon_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "::")
  assert tokens
    == [
      positioned.Positioned(
        lexer.DoubleColon,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_left_parenthesis_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "(")
  assert tokens
    == [
      positioned.Positioned(
        lexer.LeftParenthesis,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_right_parenthesis_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, ")")
  assert tokens
    == [
      positioned.Positioned(
        lexer.RightParenthesis,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_right_angle_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, ">")
  assert tokens
    == [
      positioned.Positioned(
        lexer.RightAngle,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_left_angle_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "<")
  assert tokens
    == [
      positioned.Positioned(
        lexer.LeftAngle,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_right_angle_equal_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, ">=")
  assert tokens
    == [
      positioned.Positioned(
        lexer.RightAngleEqual,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_left_angle_equal_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "<=")
  assert tokens
    == [
      positioned.Positioned(
        lexer.LeftAngleEqual,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_equal_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "=")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Equal,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_double_equal_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "==")
  assert tokens
    == [
      positioned.Positioned(
        lexer.DoubleEqual,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_left_curly_bracket_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "{")
  assert tokens
    == [
      positioned.Positioned(
        lexer.LeftCurlyBracket,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_right_curly_bracket_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "}")
  assert tokens
    == [
      positioned.Positioned(
        lexer.RightCurlyBracket,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_dot_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, ".")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Dot,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_left_bracket_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "[")
  assert tokens
    == [
      positioned.Positioned(
        lexer.LeftBracket,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_left_arrow_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "<-")
  assert tokens
    == [
      positioned.Positioned(
        lexer.LeftArrow,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_left_right_arrow_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "<->")
  assert tokens
    == [
      positioned.Positioned(
        lexer.LeftRightArrow,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 3, 1, 4),
      ),
    ]
}

pub fn lexer_token_right_bracket_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "]")
  assert tokens
    == [
      positioned.Positioned(
        lexer.RightBracket,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_right_arrow_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "->")
  assert tokens
    == [
      positioned.Positioned(
        lexer.RightArrow,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_double_ampersand_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "&&")
  assert tokens
    == [
      positioned.Positioned(
        lexer.DoubleAmpersand,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_double_pipe_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "||")
  assert tokens
    == [
      positioned.Positioned(
        lexer.DoublePipe,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_bang_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "!")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Bang,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_double_bang_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "!!")
  assert tokens
    == [
      positioned.Positioned(
        lexer.DoubleBang,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_bang_equal_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "!=")
  assert tokens
    == [
      positioned.Positioned(
        lexer.BangEqual,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_bang_tilde_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "!~")
  assert tokens
    == [
      positioned.Positioned(
        lexer.BangTilde,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_double_question_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "??")
  assert tokens
    == [
      positioned.Positioned(
        lexer.DoubleQuestion,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_question_colon_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "?:")
  assert tokens
    == [
      positioned.Positioned(
        lexer.QuestionColon,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_question_tilde_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "?~")
  assert tokens
    == [
      positioned.Positioned(
        lexer.QuestionTilde,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 2, 1, 3),
      ),
    ]
}

pub fn lexer_token_tilde_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "~")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Tilde,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_plus_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "+")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Plus,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_multiply_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "×")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Multiply,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_slash_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "/")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Slash,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

pub fn lexer_token_divide_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "÷")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Divide,
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 1, 1, 2),
      ),
    ]
}

//-----------------------------------------------------------------------------------------------//
//                                           Literals                                            //
//-----------------------------------------------------------------------------------------------//

pub fn lexer_token_parameter_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "$parameter")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Parameter("parameter"),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 10, 1, 11),
      ),
    ]
}

pub fn lexer_token_parameter_with_number_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "$parameter01")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Parameter("parameter01"),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 12, 1, 13),
      ),
    ]
}

pub fn lexer_token_parameter_with_underscore_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "$parameter_a")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Parameter("parameter_a"),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 12, 1, 13),
      ),
    ]
}

pub fn lexer_token_identifier_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "parameter")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Identifier("parameter"),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 9, 1, 10),
      ),
    ]
}

pub fn lexer_token_identifier_with_number_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "parameter01")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Identifier("parameter01"),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 11, 1, 12),
      ),
    ]
}

pub fn lexer_token_identifier_with_underscore_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "parameter_a")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Identifier("parameter_a"),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 11, 1, 12),
      ),
    ]
}

pub fn lexer_token_string_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "\"hello\"")
  assert tokens
    == [
      positioned.Positioned(
        lexer.String("hello"),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 7, 1, 8),
      ),
    ]
}

pub fn lexer_token_string_single_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "'hello'")
  assert tokens
    == [
      positioned.Positioned(
        lexer.String("hello"),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 7, 1, 8),
      ),
    ]
}

pub fn lexer_token_string_error_test() {
  let file = "_test_file"
  let assert Error(lexer.UnexpectedCharacter("EOF", _)) =
    lexer.tokenize(file, "\"hello")
}

pub fn lexer_token_number_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "12345")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Number(12_345.0),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 5, 1, 6),
      ),
    ]
}

pub fn lexer_token_decimal_number_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "12345.6")
  assert tokens
    == [
      positioned.Positioned(
        lexer.Number(12_345.6),
        positioned.Position(file, 0, 1, 1),
        positioned.Position(file, 7, 1, 8),
      ),
    ]
}

pub fn lexer_token_number_error_test() {
  let file = "_test_file"
  let assert Error(lexer.UnexpectedFormat("12345.6.7", _)) =
    lexer.tokenize(file, "12345.6.7")
}

//-----------------------------------------------------------------------------------------------//
//                                          Whitespaces                                          //
//-----------------------------------------------------------------------------------------------//

pub fn lexer_token_space_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, " ")
  assert tokens == []
}

pub fn lexer_token_tab_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "\t")
  assert tokens == []
}

pub fn lexer_token_line_break_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "\n")
  assert tokens == []
}

//-----------------------------------------------------------------------------------------------//
//                                           Comments                                            //
//-----------------------------------------------------------------------------------------------//

pub fn lexer_token_comment_test() {
  let file = "_test_file"
  let assert Ok(tokens) = lexer.tokenize(file, "-- This is a comment")
  assert tokens == []
}

//-----------------------------------------------------------------------------------------------//
//                                             Error                                             //
//-----------------------------------------------------------------------------------------------//

pub fn lexer_token_error_test() {
  let assert Error(lexer.UnexpectedCharacter(
    "�",
    positioned.Position("_test_file", 0, 1, 1),
  )) = lexer.tokenize("_test_file", "�")
}
