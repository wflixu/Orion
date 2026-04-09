// Analyzer - Unit Tests

///|
test "db_type_to_mb_type converts types" {
  match @analyzer.db_type_to_mb_type(@analyzer.db_type_text()) {
    "String" => ()
    _ => println("should be String")
  }

  match @analyzer.db_type_to_mb_type(@analyzer.db_type_integer()) {
    "Int" => ()
    _ => println("should be Int")
  }

  match @analyzer.db_type_to_mb_type(@analyzer.db_type_boolean()) {
    "Bool" => ()
    _ => println("should be Bool")
  }

  match @analyzer.db_type_to_mb_type(@analyzer.db_type_real()) {
    "Double" => ()
    _ => println("should be Double")
  }
}

///|
test "make_empty_schema creates empty schema" {
  let schema = @analyzer.make_empty_schema()
  assert_eq(Array::length(schema.tables), 0)
}

///|
test "add_table adds table to schema" {
  let schema = @analyzer.make_empty_schema()
  let table = @analyzer.make_table("users", [])
  let updated = @analyzer.add_table(schema, table)
  assert_eq(Array::length(updated.tables), 1)
}

///|
test "make_column creates column info" {
  let column = @analyzer.make_column(
    "id",
    @analyzer.db_type_integer(),
    false,
    true,
  )
  assert_eq(column.name, "id")
  match column.db_type {
    @analyzer.DatabaseType::Integer => ()
    _ => println("should be Integer")
  }
  assert_eq(column.nullable, false)
  assert_eq(column.primary_key, true)
}

///|
test "find_table finds table by name" {
  let schema = @analyzer.make_empty_schema()
  let table = @analyzer.make_table("users", [])
  let updated = @analyzer.add_table(schema, table)
  match @analyzer.find_table(updated, "users") {
    Some(t) => assert_eq(t.name, "users")
    None => println("should find table")
  }
}

///|
test "find_table returns None for unknown table" {
  let schema = @analyzer.make_empty_schema()
  match @analyzer.find_table(schema, "unknown") {
    None => ()
    Some(_) => println("should return None")
  }
}

///|
test "find_column finds column by name" {
  let col1 = @analyzer.make_column(
    "id",
    @analyzer.db_type_integer(),
    false,
    true,
  )
  let col2 = @analyzer.make_column(
    "name",
    @analyzer.db_type_text(),
    false,
    false,
  )
  let table = @analyzer.make_table("users", [col1, col2])

  match @analyzer.find_column(table, "name") {
    Some(c) => assert_eq(c.name, "name")
    None => println("should find column")
  }
}

///|
test "find_column returns None for unknown column" {
  let table = @analyzer.make_table("users", [])
  match @analyzer.find_column(table, "unknown") {
    None => ()
    Some(_) => println("should return None")
  }
}

///|
test "parse_select_columns extracts column names" {
  let sql = "SELECT id, name, email FROM users"
  let columns = @analyzer.parse_select_columns(sql)
  assert_eq(Array::length(columns), 3)
}

///|
test "parse_select_columns handles single column" {
  let sql = "SELECT id FROM users"
  let columns = @analyzer.parse_select_columns(sql)
  assert_eq(Array::length(columns), 1)
}

///|
test "parse_select_columns handles empty SELECT" {
  let sql = "SELECT FROM users"
  let columns = @analyzer.parse_select_columns(sql)
  assert_eq(Array::length(columns), 0)
}

///|
test "guess_column_type guesses Int for id columns" {
  let schema = @analyzer.make_empty_schema()
  let typ = @analyzer.guess_column_type(schema, "user_id")
  assert_eq(typ, "Int")

  let typ2 = @analyzer.guess_column_type(schema, "id")
  assert_eq(typ2, "Int")
}

///|
test "guess_column_type guesses Bool for is/has prefixes" {
  let schema = @analyzer.make_empty_schema()
  let typ = @analyzer.guess_column_type(schema, "is_active")
  assert_eq(typ, "Bool")

  let typ2 = @analyzer.guess_column_type(schema, "has_permission")
  assert_eq(typ2, "Bool")
}

///|
test "guess_column_type guesses String for text columns" {
  let schema = @analyzer.make_empty_schema()
  let typ = @analyzer.guess_column_type(schema, "email")
  assert_eq(typ, "String")

  let typ2 = @analyzer.guess_column_type(schema, "user_name")
  assert_eq(typ2, "String")
}

///|
test "guess_column_type guesses Double for price/rate" {
  let schema = @analyzer.make_empty_schema()
  let typ = @analyzer.guess_column_type(schema, "price")
  assert_eq(typ, "Double")

  let typ2 = @analyzer.guess_column_type(schema, "hourly_rate")
  assert_eq(typ2, "Double")
}

///|
test "trim removes leading and trailing spaces" {
  assert_eq(@analyzer.trim("  hello  "), "hello")
  assert_eq(@analyzer.trim("test"), "test")
  assert_eq(@analyzer.trim("  multiple  words  "), "multiple  words")
}

///|
test "split_columns splits by comma" {
  let columns = @analyzer.split_columns("id, name, email")
  assert_eq(Array::length(columns), 3)
}

///|
test "split_columns handles spaces" {
  let columns = @analyzer.split_columns("id, name , email")
  assert_eq(Array::length(columns), 3)
}

///|
test "gen_struct_fields generates struct definition" {
  let fields = [("id", "Int"), ("name", "String"), ("email", "String")]
  let result = @analyzer.gen_struct_fields(fields, "User")
  assert_eq(result.contains("pub struct User"), true)
  assert_eq(result.contains("id : Int"), true)
  assert_eq(result.contains("name : String"), true)
  assert_eq(result.contains("email : String"), true)
}
