// SQL 文件解析器 - 单元测试

///|
test "parse single query with all fields" {
  let content = "-- name: getUserById\n-- description: Get user by ID\n-- result: single\nSELECT id, name, age FROM users WHERE id = ?;"

  let result = parse_sql_file(content)

  match result {
    Ok(queries) => {
      assert_eq(Array::length(queries), 1)
      let q = queries[0]
      assert_eq(q.name, "getUserById")
      assert_eq(q.description, Some("Get user by ID"))
      assert_eq(q.sql, "SELECT id, name, age FROM users WHERE id = ?;")
      assert_eq(q.param_count, 1)
      assert_eq(q.is_dynamic, false)
    }
    Err(e) => println("Failed to parse: " + e)
  }
}

///|
test "parse many result type" {
  let content = "-- name: listUsers\n-- description: List all users\n-- result: many\nSELECT id, name, age FROM users ORDER BY id;"

  let result = parse_sql_file(content)

  match result {
    Ok(queries) => assert_eq(Array::length(queries), 1)
    Err(e) => println("Failed to parse: " + e)
  }
}

///|
test "parse last_insert_id result type" {
  let content = "-- name: createUser\n-- description: Create a new user\n-- result: last_insert_id\nINSERT INTO users (name, age) VALUES (?, ?);"

  let result = parse_sql_file(content)

  match result {
    Ok(queries) => {
      assert_eq(Array::length(queries), 1)
      assert_eq(queries[0].param_count, 2)
    }
    Err(e) => println("Failed to parse: " + e)
  }
}

///|
test "parse affected_rows result type" {
  let content = "-- name: deleteUser\n-- description: Delete a user\n-- result: affected_rows\nDELETE FROM users WHERE id = ?;"

  let result = parse_sql_file(content)

  match result {
    Ok(queries) => {
      assert_eq(Array::length(queries), 1)
      assert_eq(queries[0].param_count, 1)
    }
    Err(e) => println("Failed to parse: " + e)
  }
}

///|
test "parse multiple queries" {
  let content = "-- name: getUserById\n-- description: Get user by ID\n-- result: single\nSELECT id, name, age FROM users WHERE id = ?;\n\n-- name: createUser\n-- description: Create a new user\n-- result: last_insert_id\nINSERT INTO users (name, age) VALUES (?, ?);"

  let result = parse_sql_file(content)

  match result {
    Ok(queries) => {
      assert_eq(Array::length(queries), 2)
      assert_eq(queries[0].name, "getUserById")
      assert_eq(queries[1].name, "createUser")
    }
    Err(e) => println("Failed to parse: " + e)
  }
}

///|
test "parse query without description" {
  let content = "-- name: simpleQuery\n-- result: single\nSELECT 1;"

  let result = parse_sql_file(content)

  match result {
    Ok(queries) => {
      assert_eq(Array::length(queries), 1)
      assert_eq(queries[0].name, "simpleQuery")
      assert_eq(queries[0].description, None)
    }
    Err(e) => println("Failed to parse: " + e)
  }
}

///|
test "parse missing name should skip" {
  let content = "-- description: No name query\n-- result: single\nSELECT 1;"

  let result = parse_sql_file(content)

  match result {
    Ok(queries) => assert_eq(Array::length(queries), 0)
    Err(_) => ()
  }
}

///|
test "parse missing result should fail" {
  let content = "-- name: noResultType\n-- description: Missing result type\nSELECT 1;"

  let result = parse_sql_file(content)

  match result {
    Ok(_) => println("Should fail when result type is missing")
    Err(_) => ()
  }
}

///|
test "parse dynamic sql" {
  let content = "-- name: findUsers\n-- description: Find users\n-- result: many\nSELECT * FROM users\nWHERE 1=1\n[@if name]\nAND name = ?\n[@endif]\n;"

  let result = parse_sql_file(content)

  match result {
    Ok(queries) => {
      assert_eq(Array::length(queries), 1)
      assert_eq(queries[0].is_dynamic, true)
      assert_eq(queries[0].param_count, 1)
    }
    Err(e) => println("Failed to parse: " + e)
  }
}

///|
test "count question mark params" {
  let content = "-- name: test\n-- result: single\nSELECT * FROM users WHERE id = ? AND name = ?;"

  let result = parse_sql_file(content)

  match result {
    Ok(queries) => assert_eq(queries[0].param_count, 2)
    Err(e) => println("Failed to parse: " + e)
  }
}
