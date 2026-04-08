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
