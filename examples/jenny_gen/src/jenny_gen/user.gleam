import gleam/json.{type Json}
import gleam/list
import gleam/dynamic

pub type User {
  User(
    v0: String,
    v1: String,
    v2: String,
    v3: String,
    v4: String,
    v5: String,
    v6: String,
    v7: String,
    v8: String,
    v9: String,
  )
}

pub fn user_from_json(str: String) -> Result(User, json.DecodeError) {
  json.decode(
    str,
    fn(dyn) {
      let v0 = dynamic.string(dyn)
      let v1 = dynamic.string(dyn)
      let v2 = dynamic.string(dyn)
      let v3 = dynamic.string(dyn)
      let v4 = dynamic.string(dyn)
      let v5 = dynamic.string(dyn)
      let v6 = dynamic.string(dyn)
      let v7 = dynamic.string(dyn)
      let v8 = dynamic.string(dyn)
      let v9 = dynamic.string(dyn)
      case v0, v1, v2, v3, v4, v5, v6, v7, v8, v9 {
        Ok(v0), Ok(v1), Ok(v2), Ok(v3), Ok(v4), Ok(v5), Ok(v6), Ok(v7), Ok(v8), Ok(v9) -> Ok(User(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9))
        _, _, _, _, _, _, _, _, _, _ -> {
          [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9]
          |> list.filter_map(fn(val) {
            case val {
              Ok(_val) -> Error(Nil)
              Error(decode_error) -> Ok(decode_error)
            }
          })
          |> list.flatten
          |> Error
        }
      }
    }
  )
}

pub fn user_to_json(user: User) -> Json {
  json.object([
    #("v0", json.string(user.v0)),
    #("v1", json.string(user.v1)),
    #("v2", json.string(user.v2)),
    #("v3", json.string(user.v3)),
    #("v4", json.string(user.v4)),
    #("v5", json.string(user.v5)),
    #("v6", json.string(user.v6)),
    #("v7", json.string(user.v7)),
    #("v8", json.string(user.v8)),
    #("v9", json.string(user.v9)),
  ])
}

pub fn user_from_sql() -> dynamic.Decoder(User) {
  fn(dyn) {
    let v0 = dynamic.string(dyn)
    let v1 = dynamic.string(dyn)
    let v2 = dynamic.string(dyn)
    let v3 = dynamic.string(dyn)
    let v4 = dynamic.string(dyn)
    let v5 = dynamic.string(dyn)
    let v6 = dynamic.string(dyn)
    let v7 = dynamic.string(dyn)
    let v8 = dynamic.string(dyn)
    let v9 = dynamic.string(dyn)
    case v0, v1, v2, v3, v4, v5, v6, v7, v8, v9 {
      Ok(v0), Ok(v1), Ok(v2), Ok(v3), Ok(v4), Ok(v5), Ok(v6), Ok(v7), Ok(v8), Ok(v9) -> Ok(User(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9))
      _, _, _, _, _, _, _, _, _, _ -> {
        [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9]
        |> list.filter_map(fn(val) {
          case val {
            Ok(_val) -> Error(Nil)
            Error(decode_error) -> Ok(decode_error)
          }
        })
        |> list.flatten
        |> Error
      }
    }
  }
}