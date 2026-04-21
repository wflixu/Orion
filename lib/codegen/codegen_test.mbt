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

///|
test "gen_query_builder_struct" {
  let schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.add_int_field("age", [])
    |> @schema.build_schema()

  let code = @codegen.gen_query_builder_struct(schema)

  assert_eq(code.contains("pub struct UsersQuery"), true)
  assert_eq(code.contains("db : @runtime.Db"), true)
  assert_eq(code.contains("where_clauses : Array[String]"), true)
  assert_eq(code.contains("order_by : Option[String]"), true)
  assert_eq(code.contains("limit : Option[Int]"), true)
  assert_eq(code.contains("offset : Option[Int]"), true)
}

///|
test "gen_where_methods" {
  let schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.build_schema()

  let code = @codegen.gen_where_methods(schema)

  assert_eq(code.contains("pub fn UsersQuery::where_id"), true)
  assert_eq(code.contains("pub fn UsersQuery::where_name"), true)
  assert_eq(code.contains("WHERE id = ?"), true)
  assert_eq(code.contains("WHERE name = ?"), true)
}

///|
test "gen_where_like_methods" {
  let schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.add_string_field("email", [])
    |> @schema.build_schema()

  let code = @codegen.gen_where_like_methods(schema)

  assert_eq(code.contains("where_name_contains"), true)
  assert_eq(code.contains("where_name_starts_with"), true)
  assert_eq(code.contains("where_name_ends_with"), true)
  assert_eq(code.contains("where_email_contains"), true)
  // Int 字段不应该生成 like 方法
  assert_eq(code.contains("where_id_contains"), false)
}

///|
test "gen_order_by_methods" {
  let schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.build_schema()

  let code = @codegen.gen_order_by_methods(schema)

  assert_eq(code.contains("pub fn UsersQuery::order_by_id"), true)
  assert_eq(code.contains("pub fn UsersQuery::order_by_name"), true)
  assert_eq(code.contains("ORDER BY"), true)
  assert_eq(code.contains("DESC"), true)
  assert_eq(code.contains("ASC"), true)
}

///|
test "gen_limit_offset_methods" {
  let schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.build_schema()

  let code = @codegen.gen_limit_offset_methods(schema)

  assert_eq(code.contains("pub fn UsersQuery::limit"), true)
  assert_eq(code.contains("pub fn UsersQuery::offset"), true)
}

///|
test "gen_execute_method" {
  let schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.build_schema()

  let code = @codegen.gen_execute_method(schema)

  assert_eq(code.contains("pub fn UsersQuery::execute"), true)
  assert_eq(code.contains("SELECT id, name FROM users"), true)
  assert_eq(code.contains("WHERE"), true)
  assert_eq(code.contains("ORDER BY"), true)
  assert_eq(code.contains("LIMIT"), true)
  assert_eq(code.contains("OFFSET"), true)
}

///|
test "gen_first_method" {
  let schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.build_schema()

  let code = @codegen.gen_first_method(schema)

  assert_eq(code.contains("pub fn UsersQuery::first"), true)
  assert_eq(code.contains("limit(1).execute()"), true)
}

///|
test "gen_count_method" {
  let schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.build_schema()

  let code = @codegen.gen_count_method(schema)

  assert_eq(code.contains("pub fn UsersQuery::count"), true)
  assert_eq(code.contains("SELECT COUNT(*) FROM users"), true)
}

///|
test "gen_full_query_builder" {
  let schema = @schema.schema("products")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.add_int_field("price", [])
    |> @schema.build_schema()

  let code = @codegen.gen_full_query_builder(schema)

  assert_eq(code.contains("// @generated by Orion Codegen 2.0"), true)
  assert_eq(code.contains("pub struct ProductsQuery"), true)
  assert_eq(code.contains("pub fn new_products_query"), true)
  assert_eq(code.contains("where_id"), true)
  assert_eq(code.contains("where_name"), true)
  assert_eq(code.contains("where_name_contains"), true)
  assert_eq(code.contains("order_by_id"), true)
  assert_eq(code.contains("order_by_name"), true)
  assert_eq(code.contains("limit"), true)
  assert_eq(code.contains("offset"), true)
  assert_eq(code.contains("execute"), true)
  assert_eq(code.contains("first"), true)
  assert_eq(code.contains("count"), true)
}

///|
/// Integration test: Schema DSL -> Codegen -> Full Code Generation
test "e2e_schema_to_codegen" {
  // 1. Define schema using Schema DSL
  let user_schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.add_string_field("email", @schema.unique_required())
    |> @schema.add_int_field("age", [])
    |> @schema.add_bool_field("active", @schema.with_default("true"))
    |> @schema.build_schema()

  // 2. Validate schema
  let _validation = @schema.validate_schema(user_schema)

  // 3. Generate all code
  let struct_code = @codegen.gen_full_struct(user_schema)
  let crud_code = @codegen.gen_full_crud(user_schema)
  let query_code = @codegen.gen_full_query_builder(user_schema)

  // 4. Verify struct generation - Users (plural from "users" table)
  assert_eq(struct_code.contains("pub struct Users {"), true)
  assert_eq(
    struct_code.contains("#[derive(Eq, Hash, FromJson, ToJson, Show)]"),
    true,
  )
  assert_eq(struct_code.contains("make_users"), true)
  assert_eq(struct_code.contains("CreateUsersInput"), true)
  assert_eq(struct_code.contains("Users::from_row"), true)

  // 5. Verify CRUD generation
  assert_eq(crud_code.contains("pub struct UsersMapper {"), true)
  assert_eq(crud_code.contains("new_users_mapper"), true)
  assert_eq(crud_code.contains("create_users"), true)
  assert_eq(crud_code.contains("find_users_by_id"), true)
  assert_eq(crud_code.contains("find_all_users"), true)
  assert_eq(crud_code.contains("update_users"), true)
  assert_eq(crud_code.contains("delete_users_by_id"), true)

  // 6. Verify Query Builder generation
  assert_eq(query_code.contains("pub struct UsersQuery {"), true)
  assert_eq(query_code.contains("new_users_query"), true)
  assert_eq(query_code.contains("where_id"), true)
  assert_eq(query_code.contains("where_name"), true)
  assert_eq(query_code.contains("where_name_contains"), true)
  assert_eq(query_code.contains("where_name_starts_with"), true)
  assert_eq(query_code.contains("where_name_ends_with"), true)
  assert_eq(query_code.contains("order_by_id"), true)
  assert_eq(query_code.contains("order_by_name"), true)
  assert_eq(query_code.contains("limit"), true)
  assert_eq(query_code.contains("offset"), true)
  assert_eq(query_code.contains("execute"), true)
  assert_eq(query_code.contains("first"), true)
  assert_eq(query_code.contains("count"), true)
}

///|
/// Integration test: Schema validation
test "e2e_schema_validation" {
  // Valid schema with primary key and auto increment
  let valid_schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.build_schema()

  let valid_result = @schema.validate_schema(valid_schema)
  assert_eq(valid_result.length(), 0)

  // Generate DDL for different databases
  let sqlite_ddl = @schema.generate_create_table_sql(
    valid_schema,
    @schema.parse_db_type("sqlite"),
  )
  assert_eq(sqlite_ddl.contains("CREATE TABLE"), true)
  assert_eq(sqlite_ddl.contains("users"), true)
  assert_eq(sqlite_ddl.contains("INTEGER PRIMARY KEY AUTOINCREMENT"), true)

  let postgres_ddl = @schema.generate_create_table_sql(
    valid_schema,
    @schema.parse_db_type("postgres"),
  )
  assert_eq(
    postgres_ddl.contains(
      "INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY",
    ),
    true,
  )

  let mysql_ddl = @schema.generate_create_table_sql(
    valid_schema,
    @schema.parse_db_type("mysql"),
  )
  assert_eq(mysql_ddl.contains("INT PRIMARY KEY AUTO_INCREMENT"), true)
}

///|
/// Integration test: Constraint generation
test "e2e_constraint_types" {
  let schema = @schema.schema("products")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.add_string_field("sku", [@schema.unique()])
    |> @schema.add_string_field("description", [@schema.not_null()])
    |> @schema.add_string_field("category", @schema.with_default("'General'"))
    |> @schema.add_int_field("price", [@schema.not_null()])
    |> @schema.add_string_field("code", [@schema.max_length(50)])
    |> @schema.add_normal_index("idx_category", ["category"])
    |> @schema.add_unique_index("uniq_sku", ["sku"])
    |> @schema.build_schema()

  // Generate struct - Products (plural from "products" table)
  let struct_code = @codegen.gen_full_struct(schema)
  assert_eq(struct_code.contains("pub struct Products {"), true)

  // Generate CRUD
  let crud_code = @codegen.gen_full_crud(schema)
  assert_eq(crud_code.contains("pub struct ProductsMapper {"), true)

  // Generate Query Builder
  let query_code = @codegen.gen_full_query_builder(schema)
  assert_eq(query_code.contains("where_name"), true)
  assert_eq(query_code.contains("where_sku"), true)
  assert_eq(query_code.contains("where_description"), true)
  assert_eq(query_code.contains("where_category"), true)
  assert_eq(query_code.contains("where_price"), true)
}
