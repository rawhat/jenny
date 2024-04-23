import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import snag.{type Snag}

pub type FieldType {
  StringField
  IntField
  FloatField
  BoolField
}

pub type Module {
  Module(
    type_name: String,
    record_name: String,
    fields: List(#(String, FieldType)),
  )
}

pub fn create_module(
  name: String,
  fields: List(#(String, String)),
) -> Result(Module, Snag) {
  use parsed_fields <- result.map(parse_fields(fields))
  Module(
    type_name: string.capitalise(name),
    record_name: string.lowercase(name),
    fields: parsed_fields,
  )
}

pub fn generate(module: Module) -> String {
  let type_definition = generate_type_definition(module)
  let json_decoder = generate_json_decoder(module)
  let json_encoder = generate_json_encoder(module)
  let sql_decoder = generate_sql_decoder(module)

  [
    "import gleam/json.{type Json}",
    "import gleam/list",
    "import gleam/dynamic",
    "",
    type_definition,
    "",
    json_decoder,
    "",
    json_encoder,
    "",
    sql_decoder,
  ]
  |> string.join("\n")
}

pub fn generate_type_definition(module: Module) -> String {
  let start =
    "pub type " <> module.type_name <> " {\n  " <> module.type_name <> "("

  list.fold(module.fields, [start], fn(strings, field) {
    let #(name, field_type) = field

    let type_string = case field_type {
      StringField -> "String"
      IntField -> "Int"
      FloatField -> "Float"
      BoolField -> "Bool"
    }

    ["    " <> name <> ": " <> type_string <> ",", ..strings]
  })
  |> fn(strings) {
    ["  )\n}", ..strings]
    |> list.reverse
    |> string.join("\n")
  }
}

pub fn generate_json_decoder(module: Module) -> String {
  let function_definition =
    "pub fn "
    <> module.record_name
    <> "_from_json(str: String) -> Result("
    <> module.type_name
    <> ", json.DecodeError) {"

  let body = case list.length(module.fields) {
    n if n > 9 -> {
      let top = "  json.decode(\n    str,\n    fn(dyn) {\n"
      let body =
        list.index_map(module.fields, fn(item, index) {
          let #(_name, field_type) = item
          "      let v"
          <> int.to_string(index)
          <> " = dynamic."
          <> decoder_from_field_type(field_type)
          <> "(dyn)"
        })
        |> string.join("\n")
      let variables =
        list.index_map(module.fields, fn(_item, index) {
          "v" <> int.to_string(index)
        })
      let ok_values =
        list.index_map(module.fields, fn(_item, index) {
          "Ok(v" <> int.to_string(index) <> ")"
        })
      let errors = "[" <> string.join(variables, ", ") <> "]
          |> list.filter_map(fn(val) {
            case val {
              Ok(_val) -> Error(Nil)
              Error(decode_error) -> Ok(decode_error)
            }
          })
          |> list.flatten
          |> Error"

      let case_statement = "      case " <> string.join(variables, ", ") <> " {
        " <> string.join(ok_values, ", ") <> " -> Ok(" <> module.type_name <> "(" <> string.join(
          variables,
          ", ",
        ) <> "))
        " <> string.join(list.repeat("_", n), ", ") <> " -> {
          " <> errors <> "
        }
      }\n"

      top <> body <> "\n" <> case_statement <> "    }\n  )"
    }
    n -> {
      let decoders =
        module.fields
        |> decoders_from_fields
        |> list.map(fn(decoder) { "      " <> decoder })
      [
        "  json.decode(",
        "    str,",
        "    dynamic.decode" <> int.to_string(n) <> "(",
        "      " <> module.type_name <> ",",
        ..decoders
      ]
      |> string.join("\n")
      |> fn(s) { s <> "\n    )\n  )" }
    }
  }

  string.join([function_definition, body, "}"], "\n")
}

pub fn generate_json_encoder(module: Module) -> String {
  let function_definition =
    "pub fn "
    <> module.record_name
    <> "_to_json("
    <> module.record_name
    <> ": "
    <> module.type_name
    <> ") -> Json {"
  let fields =
    module.fields
    |> list.map(fn(field) {
      let #(name, field_type) = field
      let json_func = case field_type {
        StringField -> "json.string"
        IntField -> "json.int"
        FloatField -> "json.float"
        BoolField -> "json.bool"
      }
      "    #(\""
      <> name
      <> "\", "
      <> json_func
      <> "("
      <> module.record_name
      <> "."
      <> name
      <> ")"
      <> "),"
    })

  let body = list.concat([["  json.object(["], fields, ["  ])"]])

  [function_definition, ..body]
  |> list.append(["}"])
  |> string.join("\n")
}

pub fn generate_sql_decoder(module: Module) -> String {
  let function_definition =
    "pub fn "
    <> module.record_name
    <> "_from_sql() -> dynamic.Decoder("
    <> module.type_name
    <> ") {"

  let body = case list.length(module.fields) {
    n if n > 9 -> {
      let top = "  fn(dyn) {\n"
      let body =
        list.index_map(module.fields, fn(item, index) {
          let #(_name, field_type) = item
          "    let v"
          <> int.to_string(index)
          <> " = dynamic."
          <> decoder_from_field_type(field_type)
          <> "(dyn)"
        })
        |> string.join("\n")
      let variables =
        list.index_map(module.fields, fn(_item, index) {
          "v" <> int.to_string(index)
        })
      let ok_values =
        list.index_map(module.fields, fn(_item, index) {
          "Ok(v" <> int.to_string(index) <> ")"
        })
      let errors = "[" <> string.join(variables, ", ") <> "]
        |> list.filter_map(fn(val) {
          case val {
            Ok(_val) -> Error(Nil)
            Error(decode_error) -> Ok(decode_error)
          }
        })
        |> list.flatten
        |> Error"

      let case_statement = "    case " <> string.join(variables, ", ") <> " {
      " <> string.join(ok_values, ", ") <> " -> Ok(" <> module.type_name <> "(" <> string.join(
          variables,
          ", ",
        ) <> "))
      " <> string.join(list.repeat("_", n), ", ") <> " -> {
        " <> errors <> "
      }\n"

      top <> body <> "\n" <> case_statement <> "    }\n  }"
    }
    n -> {
      let decoders =
        module.fields
        |> field_decoders_of_tuple
        |> list.map(fn(decoder) { "    " <> decoder })
      [
        "  dynamic.decode" <> int.to_string(n) <> "(",
        "    " <> module.type_name <> ",",
        ..decoders
      ]
      |> string.join("\n")
      |> fn(s) { s <> "\n  )" }
    }
  }

  string.join([function_definition, body, "}"], "\n")
}

pub fn generate_sql_insert(module: Module) -> String {
  ""
}

pub fn generate_sql_delete(module: Module) -> String {
  ""
}

pub fn generate_sql_list(module: Module) -> String {
  ""
}

@internal
pub fn parse_fields(fields: List(#(String, String))) -> Result(
  List(#(String, FieldType)),
  Snag,
) {
  list.try_map(fields, fn(field) {
    let #(field, field_type_str) = field

    use field_type <- result.try(case field_type_str {
      "string" -> Ok(StringField)
      "int" -> Ok(IntField)
      "float" -> Ok(FloatField)
      "bool" -> Ok(BoolField)
      str -> Error(snag.new("Unknown field type: " <> str))
    })
    Ok(#(field, field_type))
  })
}

@internal
pub fn decoders_from_fields(fields: List(#(String, FieldType))) -> List(String) {
  list.map(fields, fn(pair) {
    let #(field, field_type) = pair

    let decoder = case field_type {
      StringField -> "dynamic.string"
      IntField -> "dynamic.int"
      FloatField -> "dynamic.float"
      BoolField -> "dynamic.bool"
    }

    "dynamic.field(\"" <> field <> "\"" <> ", " <> decoder <> "),"
  })
}

@internal
pub fn field_decoders_of_tuple(fields: List(#(String, FieldType))) -> List(
  String,
) {
  list.index_map(fields, fn(pair, index) {
    let #(_field, field_type) = pair

    let decoder = case field_type {
      StringField -> "dynamic.string"
      IntField -> "dynamic.int"
      FloatField -> "dynamic.float"
      BoolField -> "dynamic.bool"
    }

    "dynamic.element(" <> int.to_string(index) <> ", " <> decoder <> "),"
  })
}

fn decoder_from_field_type(field_type: FieldType) -> String {
  case field_type {
    StringField -> "string"
    IntField -> "int"
    FloatField -> "float"
    BoolField -> "bool"
  }
}
