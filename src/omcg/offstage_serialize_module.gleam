import gleam/list
import omcg/module.{type Module}

pub fn serializer() -> Module {
  module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("Serializer"),
  )
  |> module.add_import(["pont", "serialize"])
}

pub fn serializer_of(of: Module) -> Module {
  serializer()
  |> module.function_call.create()
  |> module.function_call.add(of)
}

pub fn string_enum() -> Module {
  module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("string_enum"),
  )
  |> module.add_import(["pont", "serialize"])
}

pub fn string_enum_of(values: Module, to_string: Module) -> Module {
  string_enum()
  |> module.function_call.create()
  |> module.function_call.add(values)
  |> module.function_call.add(to_string)
}

pub fn timestamp() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("timestamp"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn int() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("int"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn float() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("float"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn string() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("string"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn bool() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("bool"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn value() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("value"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn nil() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("null"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn optional() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("optional"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn optional_of(inner: Module) -> Module {
  optional()
  |> module.function_call.add(inner)
}

pub fn list() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("list"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn list_of(inner: Module) -> Module {
  list()
  |> module.function_call.add(inner)
}

pub fn identifier() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("os_identifier"),
    module.identifier.create("serializer"),
  ))
  |> module.add_aliased_import(
    ["offstage_suweal", "identifier"],
    "os_identifier",
  )
}

pub fn typed_identifier() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("os_identifier"),
    module.identifier.create("typed_serializer"),
  ))
  |> module.add_aliased_import(
    ["offstage_suweal", "identifier"],
    "os_identifier",
  )
}

pub fn typed_identifier_of(types: Module) -> Module {
  typed_identifier()
  |> module.function_call.add(types)
}

pub fn record() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("os_record"),
    module.identifier.create("serializer"),
  ))
  |> module.add_aliased_import(["offstage_suweal", "record"], "os_record")
}

pub fn record_of(inner: Module, id: Module) -> Module {
  record()
  |> module.function_call.add(inner)
  |> module.function_call.add(id)
}

pub fn typed_record() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("os_record"),
    module.identifier.create("typed_serializer"),
  ))
  |> module.add_aliased_import(["offstage_suweal", "record"], "os_record")
}

pub fn typed_record_of(inner: Module, id: Module, types: Module) -> Module {
  typed_record()
  |> module.function_call.add(inner)
  |> module.function_call.add(id)
  |> module.function_call.add(types)
}

pub fn point() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("os_point"),
    module.identifier.create("serializer"),
  ))
  |> module.add_aliased_import(["offstage_suweal", "point"], "os_point")
}

pub fn object() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("object"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn object_of(content: List(Module)) -> Module {
  object()
  |> module.function_call.add(
    module.function_definition.create()
    |> module.function_definition.add_untyped_parameter("context")
    |> list.fold(content, _, module.function_definition.add),
  )
}

pub fn field() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("field"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn field_of(
  context: Module,
  name: Module,
  serializer: Module,
  getter: Module,
) -> Module {
  field()
  |> module.function_call.add(context)
  |> module.function_call.add(name)
  |> module.function_call.add(serializer)
  |> module.function_call.add(getter)
}

pub fn optional_field() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("optional_field"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn optional_field_of(
  context: Module,
  name: Module,
  default: Module,
  serializer: Module,
  getter: Module,
) -> Module {
  optional_field()
  |> module.function_call.add(context)
  |> module.function_call.add(name)
  |> module.function_call.add(default)
  |> module.function_call.add(serializer)
  |> module.function_call.add(getter)
}

pub fn build() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("build"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn build_of(context: Module, value: Module) -> Module {
  build()
  |> module.function_call.add(context)
  |> module.function_call.add(value)
}

pub fn success() -> Module {
  module.function_call.create(module.binop.access(
    module.identifier.create("serialize"),
    module.identifier.create("success"),
  ))
  |> module.add_import(["pont", "serialize"])
}

pub fn success_of(inner: Module) -> Module {
  success()
  |> module.function_call.add(inner)
}
