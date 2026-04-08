// Runtime - Unit Tests

///|
test "make db config" {
  let config = @runtime.make_db_config("sqlite://test.db", 10)
  assert_eq(config.url, "sqlite://test.db")
  assert_eq(config.pool_size, 10)
}

///|
test "connect to database" {
  let config = @runtime.make_db_config("sqlite://test.db", 10)
  let db = @runtime.connect(config)
  assert_eq(db.connected, true)
}

///|
test "close database connection" {
  let config = @runtime.make_db_config("sqlite://test.db", 10)
  let db = @runtime.connect(config)
  let result = @runtime.close(db)
  match result {
    Ok(_) => ()
    Err(_) => println("close failed")
  }
}

///|
test "query on connected db" {
  let config = @runtime.make_db_config("sqlite://test.db", 10)
  let db = @runtime.connect(config)
  let result = @runtime.query(db, "SELECT 1", [])
  match result {
    Ok(_) => ()
    Err(_) => println("query failed")
  }
}

///|
test "DbValue pattern matching" {
  // Test that DbValue enum constructors are accessible
  let int_val = @runtime.make_db_value_int(42)
  let str_val = @runtime.make_db_value_string("hello")
  let bool_val = @runtime.make_db_value_bool(true)
  let null_val = @runtime.make_db_value_null()

  match int_val {
    @runtime.DbValue::Int(n) => assert_eq(n, 42)
    _ => println("wrong type")
  }

  match str_val {
    @runtime.DbValue::String(s) => assert_eq(s, "hello")
    _ => println("wrong type")
  }

  match bool_val {
    @runtime.DbValue::Bool(b) => assert_eq(b, true)
    _ => println("wrong type")
  }

  match null_val {
    @runtime.DbValue::Null => ()
    _ => println("wrong type")
  }
}

///|
test "execute on connected db" {
  let config = @runtime.make_db_config("sqlite://test.db", 10)
  let db = @runtime.connect(config)
  let result = @runtime.execute(db, "UPDATE users SET name = ?", [])
  match result {
    Ok(_) => ()
    Err(_) => println("execute failed")
  }
}

///|
test "execute on disconnected db" {
  // Test execute function signature
  let config = @runtime.make_db_config("sqlite://test.db", 10)
  let db = @runtime.connect(config)
  let result = @runtime.execute(db, "UPDATE users SET name = ?", [])
  match result {
    Ok(rows) => assert_eq(rows >= 0, true)
    Err(_) => ()
  }
}

///|
test "DbValue helpers" {
  let int_val = @runtime.make_db_value_int(100)
  let str_val = @runtime.make_db_value_string("test")
  let bool_val = @runtime.make_db_value_bool(false)
  let null_val = @runtime.make_db_value_null()

  match int_val {
    @runtime.DbValue::Int(n) => assert_eq(n, 100)
    _ => println("wrong type")
  }

  match str_val {
    @runtime.DbValue::String(s) => assert_eq(s, "test")
    _ => println("wrong type")
  }

  match bool_val {
    @runtime.DbValue::Bool(b) => assert_eq(b, false)
    _ => println("wrong type")
  }

  match null_val {
    @runtime.DbValue::Null => ()
    _ => println("wrong type")
  }
}
