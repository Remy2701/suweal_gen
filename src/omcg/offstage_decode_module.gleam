import omcg/module.{type Module}

pub fn decoder(of: Module) -> Module {
  module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("Decoder"),
  )
  |> module.function_call.create()
  |> module.function_call.add(of)
  |> module.add_import(["pont", "decode"])
}

pub fn string_enum(first: Module, rest: Module) -> Module {
  module.binop.access(
    module.identifier.create("decode"),
    module.identifier.create("string_enum"),
  )
  |> module.function_call.create()
  |> module.function_call.add(first)
  |> module.function_call.add(rest)
  |> module.add_import(["pont", "decode"])
}
