// Schema DSL 示例 - Orion v0.2.0
// 本文件展示如何使用 Schema DSL 定义表结构

// 注意：实际使用时，请通过 Orion 包导入
// import wflixu/Orion.{schema, pk_auto_inc, required, unique_required, with_default}

let user_schema = schema("users")
  |> add_int_field("id", pk_auto_inc())
  |> add_string_field("name", required())
  |> add_string_field("email", unique_required())
  |> add_int_field("age", [])
  |> add_bool_field("active", with_default("true"))
  |> build_schema()

// 生成的代码：
// pub struct Users {
//   id: Int,
//   name: String,
//   email: String,
//   age: Int,
//   active: Bool
// } derive(Eq, Hash, FromJson, ToJson, Show)
