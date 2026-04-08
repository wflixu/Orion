// Code Generator - Unit Tests

///|
test "generate struct from query meta" {
  let struct_name = "User"
  let columns = [("id", "Int"), ("name", "String"), ("age", "Int")]

  let code = @codegen.gen_struct(struct_name, columns)

  assert_eq(code.contains("struct User"), true)
  assert_eq(code.contains("id : Int"), true)
  assert_eq(code.contains("name : String"), true)
  assert_eq(code.contains("age : Int"), true)
}

///|
test "to_snake_case conversion" {
  assert_eq(@codegen.to_snake_case("getUserById"), "get_user_by_id")
  assert_eq(@codegen.to_snake_case("User"), "user")
  assert_eq(@codegen.to_snake_case("createUser"), "create_user")
  assert_eq(@codegen.to_snake_case("listUsers"), "list_users")
  assert_eq(@codegen.to_snake_case("updateUser"), "update_user")
  assert_eq(@codegen.to_snake_case("deleteUser"), "delete_user")
}

///|
test "to_pascal_case conversion" {
  assert_eq(@codegen.to_pascal_case("user"), "User")
}

///|
test "gen_from_db_value" {
  let struct_name = "User"
  let columns = [("id", "Int"), ("name", "String")]

  let code = @codegen.gen_from_db_value(struct_name, columns)

  assert_eq(code.contains("user_from_db_value"), true)
  assert_eq(code.contains("DbValue"), true)
}

///|
test "infer_fields_from_sql simple" {
  let sql = "SELECT id, name, age FROM users"
  let fields = @codegen.infer_fields_from_sql(sql)
  assert_eq(Array::length(fields), 3)
  assert_eq(fields[0].0, "id")
  assert_eq(fields[1].0, "name")
  assert_eq(fields[2].0, "age")
}

///|
test "infer_fields_from_sql with star" {
  let sql = "SELECT * FROM users"
  let fields = @codegen.infer_fields_from_sql(sql)
  assert_eq(Array::length(fields), 0)
}

///|
test "infer_fields_from_sql with alias" {
  let sql = "SELECT id, name AS user_name FROM users"
  let fields = @codegen.infer_fields_from_sql(sql)
  assert_eq(Array::length(fields), 2)
  assert_eq(fields[1].0, "user_name")
}

///|
test "gen_struct_from_sql" {
  let sql = "SELECT id, name, age FROM users"
  let code = @codegen.gen_struct_from_sql("User", sql)
  assert_eq(code.contains("struct User"), true)
  assert_eq(code.contains("id : String"), true)
  assert_eq(code.contains("name : String"), true)
  assert_eq(code.contains("age : String"), true)
}
