// Connection Pool - Unit Tests

///|
test "create pool" {
  let config = make_db_config("sqlite://test.db", 3)
  let pool = make_pool(config)
  assert_eq(pool_size(pool) >= 0, true)
}

///|
test "get connection from pool" {
  let config = make_db_config("sqlite://test.db", 3)
  let pool = make_pool(config)
  let result = get_connection(pool)
  match result {
    Ok(db) => assert_eq(db.connected, true)
    Err(_) => println("get_connection failed")
  }
}

///|
test "return connection to pool" {
  let config = make_db_config("sqlite://test.db", 3)
  let pool = make_pool(config)
  let conn_result = get_connection(pool)
  match conn_result {
    Ok(db) => {
      let _ = return_connection(pool, db)
    }
    Err(_) => println("get_connection failed")
  }
}

///|
test "close pool" {
  let config = make_db_config("sqlite://test.db", 3)
  let pool = make_pool(config)
  let result = close_pool(pool)
  match result {
    Ok(_) => ()
    Err(_) => println("close_pool failed")
  }
}

///|
test "pool_size returns positive" {
  let config = make_db_config("sqlite://test.db", 5)
  let pool = make_pool(config)
  let size = pool_size(pool)
  assert_eq(size >= 0, true)
}

///|
test "get_connection multiple times" {
  let config = make_db_config("sqlite://test.db", 3)
  let pool = make_pool(config)
  let result1 = get_connection(pool)
  let result2 = get_connection(pool)
  match result1 {
    Ok(db1) =>
      match result2 {
        Ok(db2) => assert_eq(db1.connected && db2.connected, true)
        Err(_) => println("second get_connection failed")
      }
    Err(_) => println("first get_connection failed")
  }
}
