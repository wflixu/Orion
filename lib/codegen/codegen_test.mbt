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
