import birdie
import gleam/int
import gleam/list
import gleam/option.{None}
import gleam/string
import gleeunit
import gleeunit/should
import jenny/generator

pub fn main() {
  gleeunit.main()
}

pub fn json_decoder_less_than_9_test() {
  let fields =
    list.range(from: 0, to: 4)
    |> list.map(fn(num) { "v" <> int.to_string(num) })
    |> list.map(fn(name) { #(name, "string") })
  let assert Ok(module) = generator.create_module("user", fields)
  let decoder = generator.generate_json_decoder(module)

  birdie.snap(decoder, title: "JSON decoder for type with less than 9 fields")
}

pub fn json_decoder_more_than_9_test() {
  let fields =
    list.range(from: 0, to: 9)
    |> list.map(fn(num) { "v" <> int.to_string(num) })
    |> list.map(fn(name) { #(name, "string") })
  let assert Ok(module) = generator.create_module("user", fields)
  let decoder = generator.generate_json_decoder(module)

  birdie.snap(decoder, "JSON decoder for type with more than 9 fields")
}

pub fn sql_decoder_less_than_9_test() {
  let fields =
    list.range(from: 0, to: 4)
    |> list.map(fn(num) { "v" <> int.to_string(num) })
    |> list.map(fn(name) { #(name, "string") })
  let assert Ok(module) = generator.create_module("user", fields)
  let decoder = generator.generate_sql_decoder(module)

  birdie.snap(
    decoder,
    title: "Decoder for SQL return value of type with less than 9 fields",
  )
}

pub fn sql_decoder_more_than_9_test() {
  let fields =
    list.range(from: 0, to: 9)
    |> list.map(fn(num) { "v" <> int.to_string(num) })
    |> list.map(fn(name) { #(name, "string") })
  let assert Ok(module) = generator.create_module("user", fields)
  let decoder = generator.generate_sql_decoder(module)

  birdie.snap(
    decoder,
    title: "Decoder for SQL return value of type with more than 9 fields",
  )
}
