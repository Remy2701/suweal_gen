import gleam/list
import gleam/string
import shellout

//-----------------------------------------------------------------------------------------------//
//                                           Position                                            //
//-----------------------------------------------------------------------------------------------//

/// A position in a source file, represented by the file name, index, line, and column.
/// The line number starts at 1, the column number starts at 1, and the index starts at 0.
pub type Position {
  Position(file: String, index: Int, line: Int, column: Int)
}

/// Advance the position by a given token, updating the index, line, and column accordingly.
pub fn advance(self: Position, token: String) -> Position {
  use position, grapheme <- list.fold(string.to_graphemes(token), self)

  case grapheme {
    "\n" ->
      Position(
        ..position,
        index: position.index + 1,
        line: position.line + 1,
        column: 1,
      )
    _ ->
      Position(
        ..position,
        index: position.index + 1,
        column: position.column + 1,
      )
  }
}

//-----------------------------------------------------------------------------------------------//
//                                          Positioned                                           //
//-----------------------------------------------------------------------------------------------//

/// A value with a position in a source file, represented by the value, the starting position, and 
/// the ending position.
pub type Positioned(a) {
  Positioned(value: a, from: Position, to: Position)
}

/// Render the span of the positioned value in the source file, highlighting the relevant lines 
/// and columns.
pub fn render(self: Positioned(a), content: String) -> String {
  string.split(content, "\n")
  |> list.drop(self.from.line - 1)
  |> list.take(self.to.line - self.from.line + 1)
  |> list.flat_map(fn(line) {
    [
      string.slice(line, 0, self.from.column - 1)
        <> string.slice(
        line,
        self.from.column - 1,
        self.to.column - self.from.column,
      )
      |> shellout.style(with: shellout.color(["red"]), custom: [])
        <> string.slice(
        line,
        self.to.column - 1,
        string.length(line) - self.to.column + 1,
      ),
      string.repeat(" ", self.from.column - 1)
        <> string.repeat("^", self.to.column - self.from.column)
      |> shellout.style(with: shellout.color(["red"]), custom: []),
    ]
  })
  |> string.join("\n")
}

/// Map a function over the value of the positioned value, preserving the position information.
pub fn map(self: Positioned(a), transform: fn(a) -> b) -> Positioned(b) {
  Positioned(..self, value: transform(self.value))
}

pub fn unpositioned(positioned: List(Positioned(a))) -> List(a) {
  list.map(positioned, fn(p) { p.value })
}
