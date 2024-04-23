import argv
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glint
import glint/flag
import jenny/generator
import simplifile
import snag.{type Snag}
import tom

// TODO:  primary key?
/// `gleam run -m jenny <--no-sql> --type=<type name> --table=<table name> --directory=<path> ...<column:type>`
fn generate(input: glint.CommandInput) -> Result(Nil, Snag) {
  use type_ <- result.try(flag.get_string(input.flags, "type"))
  let _no_sql = result.unwrap(flag.get_bool(input.flags, "no-sql"), False)
  let directory = flag.get_string(input.flags, "directory")
  let columns =
    input.args
    |> list.map(string.split(_, ":"))
    |> list.map(fn(pair) {
      let assert [key, value] = pair
      #(key, value)
    })

  use module <- result.try(generator.create_module(type_, columns))
  let contents = generator.generate(module)

  case directory {
    Ok(dir) -> {
      let filename = dir <> "/" <> type_ <> ".gleam"
      simplifile.write(to: filename, contents: contents)
      |> result.map_error(fn(err) {
        snag.new("Failed to write file: " <> string.inspect(err))
      })
    }
    Error(_missing) -> {
      let toml = simplifile.read(from: "gleam.toml")
      use toml <- result.try(
        result.map_error(toml, fn(err) {
          snag.new("Failed to read `gleam.toml`: " <> string.inspect(err))
        }),
      )
      use parsed <- result.try(
        result.map_error(tom.parse(toml), fn(err) {
          snag.new("Failed to parse `gleam.toml`: " <> string.inspect(err))
        }),
      )
      use name <- result.try(
        result.map_error(tom.get_string(parsed, ["name"]), fn(err) {
          snag.new(
            "Failed to get project name from `gleam.toml`: "
            <> string.inspect(err),
          )
        }),
      )
      // TODO:  do we care if this fails?  if it exists already, no, if there is
      // like a permission error or something... yes?
      let path = "./src/" <> name
      let _ = simplifile.create_directory(path)

      let filename = path <> "/" <> type_ <> ".gleam"

      simplifile.write(to: filename, contents: contents)
      |> result.map_error(fn(err) {
        snag.new("Failed to write contents to file: " <> string.inspect(err))
      })
    }
  }
}

pub fn main() {
  glint.new()
  |> glint.as_gleam_module
  |> glint.with_name("jenny")
  |> glint.with_pretty_help(glint.default_pretty_help())
  |> glint.add(
    at: [],
    do: glint.command(generate)
      |> glint.flag(
      "no-sql",
      flag.bool()
        |> flag.default(False)
        |> flag.description("don't generate SQL or encoders/decoders"),
    )
      |> glint.flag(
      "type",
      flag.string()
        |> flag.description(
        "required, this is the type generated for the model",
      ),
    )
      |> glint.flag(
      "table",
      flag.string()
        |> flag.description("if outputting SQL, this is the table name"),
    )
      |> glint.flag(
      "directory",
      flag.string()
        |> flag.description("where should we put the generated file"),
    )
      |> glint.unnamed_args(glint.MinArgs(1)),
  )
  |> glint.run_and_handle(argv.load().arguments, fn(res) {
    case res {
      Ok(_) -> io.println("Successfully created!")
      Error(reason) -> io.println(snag.pretty_print(reason))
    }
  })
}
