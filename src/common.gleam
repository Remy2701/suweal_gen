import gleam/bool
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/string
import suweal/surreal_type

pub type Configuration {
  Configuration(offstage: Bool, service: Bool, path: String)
}

pub type ParameterProperty {
  ParameterProperty(
    name: String,
    type_: surreal_type.SurrealType,
    linked_enum: option.Option(String),
    dependencies: List(String),
  )
}

//-----------------------------------------------------------------------------------------------//
//                                        Identifier Case                                        //
//-----------------------------------------------------------------------------------------------//

/// An identifier can be in one of the following cases: PascalCase, camelCase, snake_case or 
/// unknown.
pub type IdentifierCase {
  PascalCase(value: String)
  SnakeCase(value: String)
  CamelCase(value: String)
  SpaceCase(value: String)
  UnknownCase(value: String)
}

/// Checks if a grapheme is a lowercase letter.
fn is_lowercase(grapheme: String) -> Bool {
  string.compare(grapheme, "a") != order.Lt
  && string.compare(grapheme, "z") != order.Gt
}

/// Checks if a grapheme is an uppercase letter.
fn is_uppercase(grapheme: String) -> Bool {
  string.compare(grapheme, "A") != order.Lt
  && string.compare(grapheme, "Z") != order.Gt
}

/// Checks if a grapheme is a digit.
fn is_digit(grapheme: String) -> Bool {
  string.compare(grapheme, "0") != order.Lt
  && string.compare(grapheme, "9") != order.Gt
}

fn is_snake_case_internal(string: String, start: Bool) -> Bool {
  case string.pop_grapheme(string) {
    Ok(#(grapheme, rest)) -> {
      let is_allowed = is_lowercase(grapheme) || is_digit(grapheme)
      let is_underscore = grapheme == "_"

      case is_allowed {
        True -> is_snake_case_internal(rest, False)
        False if is_underscore && !start -> is_snake_case_internal(rest, True)
        False -> False
      }
    }
    _ -> True
  }
}

/// A snake_case string is a string that is all lowercase and contains only letters, numbers and underscores. It cannot start or end with an underscore, and it cannot contain consecutive underscores.
pub fn is_snake_case(string: String) -> Bool {
  is_snake_case_internal(string, True)
}

fn is_pascal_case_internal(string: String, start: Bool) -> Bool {
  case string.pop_grapheme(string) {
    Ok(#(grapheme, rest)) -> {
      let is_uppercase = is_uppercase(grapheme)
      let is_allowed =
        is_lowercase(grapheme) || is_digit(grapheme) || is_uppercase
      case start {
        True -> is_uppercase && is_pascal_case_internal(rest, False)
        False -> is_allowed && is_pascal_case_internal(rest, False)
      }
    }
    _ -> True
  }
}

/// A PascalCase string is a string that starts with an uppercase letter and contains only letters and numbers. Each new word starts with an uppercase letter.
pub fn is_pascal_case(string: String) -> Bool {
  is_pascal_case_internal(string, True)
}

fn is_camel_case_internal(string: String, start: Bool) -> Bool {
  case string.pop_grapheme(string) {
    Ok(#(grapheme, rest)) -> {
      let is_uppercase = is_uppercase(grapheme)
      let is_allowed = is_lowercase(grapheme) || is_digit(grapheme)
      case start {
        True -> is_allowed && is_camel_case_internal(rest, False)
        False ->
          { is_allowed || is_uppercase } && is_camel_case_internal(rest, False)
      }
    }
    _ -> True
  }
}

/// A camelCase string is a string that starts with a lowercase letter and contains only letters and numbers. Each new word starts with an uppercase letter.
pub fn is_camel_case(string: String) -> Bool {
  is_camel_case_internal(string, True)
}

/// Identifies the case of a string. It can be PascalCase, camelCase, snake_case or unknown. If 
/// the string is in an unknown case, it will be returned as-is.
pub fn identify_case(string: String) -> IdentifierCase {
  use <- bool.guard(is_snake_case(string), SnakeCase(string))
  use <- bool.guard(is_pascal_case(string), PascalCase(string))
  use <- bool.guard(is_camel_case(string), CamelCase(string))
  UnknownCase(string)
}

//-----------------------------------------------------------------------------------------------//
//                                       Capitalise First                                        //
//-----------------------------------------------------------------------------------------------//

/// Capitalises the first letter of a string. If the string is empty, returns an empty string.
pub fn capitalise_first(string: String) -> String {
  case string.pop_grapheme(string) {
    Ok(#(first, rest)) ->
      string.append(to: string.uppercase(first), suffix: rest)
    Error(_) -> ""
  }
}

//-----------------------------------------------------------------------------------------------//
//                                        Case Conversion                                        //
//-----------------------------------------------------------------------------------------------//

/// Splits a string on uppercase letters. For example, "HelloWorld" becomes ["hello", "world"].
/// This is used to split PascalCase and camelCase strings into their constituent parts.
fn split_on_uppercase(str: String) -> List(String) {
  let #(buffer, list) =
    string.to_graphemes(str)
    |> list.fold(#("", []), fn(state, grapheme) {
      let is_uppercase = {
        string.compare(grapheme, "A") != order.Lt
        && string.compare(grapheme, "Z") != order.Gt
      }
      case state {
        #("", acc) -> #("" <> string.lowercase(grapheme), acc)
        #(previous, acc) if is_uppercase -> #(string.lowercase(grapheme), [
          previous,
          ..acc
        ])
        #(previous, acc) -> #(previous <> grapheme, acc)
      }
    })

  // The output needs to be reverse because the the words are prepended to the list in the reverse
  // order as it is more efficient. Prepending is O(1) while appending is O(n). Reversing the list 
  // at the end is O(n) so the overall complexity is O(n) instead of O(n^2).
  case buffer {
    "" -> list
    _ -> [buffer, ..list]
  }
  |> list.reverse()
}

/// Split the identifier into its constituent parts (aka words). 
/// This supports PascalCase, camelCase and snake_case identifiers. If the identifier is in an 
/// unknown case, it will be returned as a single part.
fn split_parts(identifier: IdentifierCase) -> List(String) {
  case identifier {
    SnakeCase(value:) -> string.split(value, "_")
    PascalCase(value:) | CamelCase(value:) -> split_on_uppercase(value)
    SpaceCase(value:) -> string.split(value, " ")
    UnknownCase(value:) -> [value]
  }
}

/// Converts an identifier to PascalCase. This supports PascalCase, camelCase and snake_case 
/// identifiers. If the identifier is in an unknown case, it will be returned as-is.
pub fn to_pascal_case(identifier: IdentifierCase) -> IdentifierCase {
  split_parts(identifier)
  |> list.map(fn(word) { capitalise_first(word) })
  |> string.join("")
  |> PascalCase
}

/// Converts an identifier to camelCase. This supports PascalCase, camelCase and snake_case 
/// identifiers. If the identifier is in an unknown case, it will be returned as-is.
pub fn to_camel_case(identifier: IdentifierCase) -> IdentifierCase {
  split_parts(identifier)
  |> list.index_map(fn(word, index) {
    case index {
      0 -> word
      _ -> capitalise_first(word)
    }
  })
  |> string.join("")
  |> CamelCase
}

/// Converts an identifier to snake_case. This supports PascalCase, camelCase and snake_case 
/// identifiers. If the identifier is in an unknown case, it will be returned as-is.
pub fn to_snake_case(identifier: IdentifierCase) -> IdentifierCase {
  split_parts(identifier)
  |> string.join("_")
  |> SnakeCase
}

pub fn to_space_case(identifier: IdentifierCase) -> IdentifierCase {
  split_parts(identifier)
  |> string.join(" ")
  |> SpaceCase
}

//-----------------------------------------------------------------------------------------------//
//                                    String Case Conversion                                     //
//-----------------------------------------------------------------------------------------------//

/// Converts a string to PascalCase. 
/// This supports snake_case, camelCase and PascalCase strings. If the string is in an unknown 
/// case, it will be returned as-is.
pub fn string_to_pascal_case(string: String) -> String {
  to_pascal_case(identify_case(string)).value
}

/// Converts a string to snake_case.
/// This supports snake_case, camelCase and PascalCase strings. If the string is in an unknown 
/// case, it will be returned as-is.
pub fn string_to_snake_case(string: String) -> String {
  to_snake_case(identify_case(string)).value
}

pub fn string_to_space_case(string: String) -> String {
  to_space_case(identify_case(string)).value
}

//-----------------------------------------------------------------------------------------------//
//                                        Case Comparison                                        //
//-----------------------------------------------------------------------------------------------//

pub fn compare(
  a: IdentifierCase,
  b: IdentifierCase,
  ignore_case: Bool,
) -> order.Order {
  case ignore_case {
    True -> string.compare(to_snake_case(a).value, to_snake_case(b).value)
    False -> string.compare(a.value, b.value)
  }
}

//-----------------------------------------------------------------------------------------------//
//                                        Path Utilities                                         //
//-----------------------------------------------------------------------------------------------//

pub fn to_gleam_path(path: String) -> String {
  string.remove_prefix(path, "./src/")
  |> string.remove_suffix(".surql")
}

pub fn namespace_of(path: String) -> String {
  let path = to_gleam_path(path)
  path
  |> string.split("/")
  |> list.last()
  |> result.unwrap(path)
}

pub fn without_namespace(name: String) -> String {
  case string.split_once(name, ".") {
    Ok(#(_, value)) -> value
    Error(_) -> name
  }
}

pub fn namespace_only(name: String) -> String {
  case string.split_once(name, ".") {
    Ok(#(value, _)) -> value
    Error(_) -> ""
  }
}
