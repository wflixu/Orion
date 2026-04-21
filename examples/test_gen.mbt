// Test script to demonstrate Schema DSL + Codegen 2.0

///|
fn main {
  // 使用 Schema DSL 定义表结构
  let user_schema = @schema.schema("users")
    |> @schema.add_int_field("id", @schema.pk_auto_inc())
    |> @schema.add_string_field("name", @schema.required())
    |> @schema.add_string_field("email", @schema.unique_required())
    |> @schema.add_int_field("age", [])
    |> @schema.add_bool_field("active", @schema.with_default("true"))
    |> @schema.build_schema()

  // 生成 Struct 代码
  let struct_code = @codegen.gen_full_struct(user_schema)
  println("=== Generated Struct ===")
  println(struct_code)

  // 生成 CRUD 代码
  let crud_code = @codegen.gen_full_crud(user_schema)
  println("\n=== Generated CRUD ===")
  println(crud_code)

  // 生成 Query Builder 代码
  let query_code = @codegen.gen_full_query_builder(user_schema)
  println("\n=== Generated Query Builder ===")
  println(query_code)

  // 验证 schema
  let validation = @schema.validate_schema(user_schema)
  if validation.length() > 0 {
    println("\nValidation errors:")
    for err in validation {
      println("  - [" + err.field + "] " + err.message)
    }
  } else {
    println("\nSchema validation passed!")
  }

  // 生成 DDL
  println("\n=== Generated DDL (SQLite) ===")
  let sqlite_ddl = @schema.generate_create_table_sql(user_schema, @schema.parse_db_type("sqlite"))
  println(sqlite_ddl)

  println("\n=== Generated DDL (PostgreSQL) ===")
  let postgres_ddl = @schema.generate_create_table_sql(user_schema, @schema.parse_db_type("postgres"))
  println(postgres_ddl)
}
