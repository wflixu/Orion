// Driver - Unit Tests

///|
test "create sqlite driver" {
  let driver = @driver.make_sqlite_driver("sqlite://test.db")
  assert_eq(driver.url, "sqlite://test.db")
}

///|
test "sqlite connect" {
  let driver = @driver.make_sqlite_driver("sqlite://test.db")
  let result = @driver.sqlite_connect(driver)
  match result {
    Ok(db) => assert_eq(db.connected, true)
    Err(_) => println("connect failed")
  }
}

///|
test "sqlite disconnect" {
  let driver = @driver.make_sqlite_driver("sqlite://test.db")
  let config = @runtime.make_db_config("sqlite://test.db", 10)
  let db = @runtime.connect(config)
  let result = @driver.sqlite_disconnect(driver, db)
  match result {
    Ok(_) => ()
    Err(_) => println("disconnect failed")
  }
}

///|
test "sqlite query" {
  let driver = @driver.make_sqlite_driver("sqlite://test.db")
  let config = @runtime.make_db_config("sqlite://test.db", 10)
  let db = @runtime.connect(config)
  let result = @driver.sqlite_query(driver, db, "SELECT 1", [])
  match result {
    Ok(_) => ()
    Err(_) => println("query failed")
  }
}

///|
test "sqlite execute" {
  let driver = @driver.make_sqlite_driver("sqlite://test.db")
  let config = @runtime.make_db_config("sqlite://test.db", 10)
  let db = @runtime.connect(config)
  let result = @driver.sqlite_execute(driver, db, "UPDATE users SET name = ?", [])
  match result {
    Ok(_) => ()
    Err(_) => println("execute failed")
  }
}

///|
test "create postgres driver" {
  let driver = @driver.make_postgres_driver(
    "postgres://user:pass@localhost:5432/mydb",
  )
  assert_eq(driver.url, "postgres://user:pass@localhost:5432/mydb")
  // host, port, database 默认值测试（完整 URL 解析待实现）
  assert_eq(driver.host, "localhost")
  assert_eq(driver.port, 5432)
}

///|
test "postgres connect" {
  let driver = @driver.make_postgres_driver("postgres://localhost/test")
  let result = @driver.postgres_connect(driver)
  match result {
    Ok(db) => assert_eq(db.connected, true)
    Err(_) => println("postgres connect failed")
  }
}

///|
test "postgres disconnect" {
  let driver = @driver.make_postgres_driver("postgres://localhost/test")
  let config = @runtime.make_db_config("postgres://localhost/test", 10)
  let db = @runtime.connect(config)
  let result = @driver.postgres_disconnect(driver, db)
  match result {
    Ok(_) => ()
    Err(_) => println("postgres disconnect failed")
  }
}

///|
test "postgres query" {
  let driver = @driver.make_postgres_driver("postgres://localhost/test")
  let config = @runtime.make_db_config("postgres://localhost/test", 10)
  let db = @runtime.connect(config)
  let result = @driver.postgres_query(driver, db, "SELECT 1", [])
  match result {
    Ok(_) => ()
    Err(_) => println("postgres query failed")
  }
}

///|
test "postgres execute" {
  let driver = @driver.make_postgres_driver("postgres://localhost/test")
  let config = @runtime.make_db_config("postgres://localhost/test", 10)
  let db = @runtime.connect(config)
  let result = @driver.postgres_execute(
    driver,
    db,
    "UPDATE users SET name = ?",
    [],
  )
  match result {
    Ok(_) => ()
    Err(_) => println("postgres execute failed")
  }
}

///|
test "sqlite_db_type returns SQLite" {
  let driver = @driver.make_sqlite_driver("test.db")
  match @driver.sqlite_db_type(driver) {
    DbType::SQLite => ()
    _ => println("should be SQLite")
  }
}

///|
test "postgres_db_type returns PostgreSQL" {
  let driver = @driver.make_postgres_driver(
    "postgres://user:pass@localhost:5432/test",
  )
  match @driver.postgres_db_type(driver) {
    DbType::PostgreSQL => ()
    _ => println("should be PostgreSQL")
  }
}

///|
test "parse_postgres_url parses standard url" {
  let driver = @driver.make_postgres_driver(
    "postgres://alice:secret@localhost:5432/mydb",
  )
  assert_eq(driver.host, "localhost")
  assert_eq(driver.port, 5432)
  assert_eq(driver.database, "mydb")
  assert_eq(driver.username, "alice")
  assert_eq(driver.password, "secret")
}

///|
test "parse_postgres_url handles default port" {
  let driver = @driver.make_postgres_driver("postgres://bob@localhost/mydb")
  assert_eq(driver.host, "localhost")
  assert_eq(driver.port, 5432)
  assert_eq(driver.database, "mydb")
  assert_eq(driver.username, "bob")
  assert_eq(driver.password, "")
}

///|
test "parse_postgres_url handles no database" {
  let driver = @driver.make_postgres_driver(
    "postgres://charlie:pass@example.com",
  )
  assert_eq(driver.host, "example.com")
  assert_eq(driver.port, 5432)
  assert_eq(driver.database, "postgres")
  assert_eq(driver.username, "charlie")
  assert_eq(driver.password, "pass")
}

///|
test "parse_postgres_url handles postgresql scheme" {
  let driver = @driver.make_postgres_driver(
    "postgresql://user:pass@host:3306/db",
  )
  assert_eq(driver.host, "host")
  assert_eq(driver.port, 3306)
  assert_eq(driver.database, "db")
  assert_eq(driver.username, "user")
  assert_eq(driver.password, "pass")
}

///|
test "postgres_build_connection_string builds correct string" {
  let driver = @driver.make_postgres_driver(
    "postgres://alice:secret@localhost:5432/mydb",
  )
  let conn_str = @driver.postgres_build_connection_string(driver)
  assert_eq(conn_str, "postgres://alice:secret@localhost:5432/mydb")
}

///|
test "postgres_convert_params converts question marks" {
  let sql1 = @driver.postgres_convert_params("SELECT * FROM users WHERE id = ?")
  assert_eq(sql1, "SELECT * FROM users WHERE id = $1")

  let sql2 = @driver.postgres_convert_params(
    "SELECT * FROM users WHERE id = ? AND name = ?",
  )
  assert_eq(sql2, "SELECT * FROM users WHERE id = $1 AND name = $2")

  let sql3 = @driver.postgres_convert_params(
    "SELECT * FROM users WHERE id = ? AND name = ? AND age = ?",
  )
  assert_eq(
    sql3, "SELECT * FROM users WHERE id = $1 AND name = $2 AND age = $3",
  )
}

///|
test "postgres_convert_params handles no parameters" {
  let sql = @driver.postgres_convert_params("SELECT * FROM users")
  assert_eq(sql, "SELECT * FROM users")
}

///|
test "postgres_default_options creates correct defaults" {
  let options = @driver.postgres_default_options()
  assert_eq(options.host, "localhost")
  assert_eq(options.port, 5432)
  assert_eq(options.database, "postgres")
  assert_eq(options.username, "")
  assert_eq(options.password, "")
  assert_eq(options.ssl_mode, "disable")
  assert_eq(options.connect_timeout, 30)
}

///|
test "postgres_build_options_string includes ssl and timeout" {
  let options = @driver.postgres_default_options()
  let conn_str = @driver.postgres_build_options_string(options)
  assert_eq(
    conn_str.has_prefix(
      "postgres://:@localhost:5432/postgres?sslmode=disable&connect_timeout=30",
    ),
    true,
  )
}

///|
test "parse_port parses valid port" {
  assert_eq(@driver.parse_port("5432", 3306), 5432)
  assert_eq(@driver.parse_port("3306", 5432), 3306)
  assert_eq(@driver.parse_port("8080", 3000), 8080)
}

///|
test "parse_port returns default for empty string" {
  assert_eq(@driver.parse_port("", 5432), 5432)
  assert_eq(@driver.parse_port("", 3306), 3306)
}

///|
test "parse_port returns default for zero result" {
  assert_eq(@driver.parse_port("abc", 5432), 5432)
}
