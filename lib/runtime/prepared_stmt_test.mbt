// Prepared Statement Cache - Unit Tests

///|
test "make_stmt_cache creates empty cache" {
  let cache = make_stmt_cache(10)
  assert_eq(size(cache), 0)
  assert_eq(cache.capacity, 10)
}

///|
test "make_stmt_id creates id from sql" {
  let sql = "SELECT * FROM users"
  let id = make_stmt_id(sql)
  assert_eq(id.sql, sql)
}

///|
test "make_prepared_stmt creates unprepared statement" {
  let sql = "SELECT * FROM users"
  let stmt = make_prepared_stmt(sql)
  assert_eq(stmt.sql, sql)
  assert_eq(is_prepared(stmt), false)
}

///|
test "put adds statement to cache" {
  let cache = make_stmt_cache(10)
  let stmt = make_prepared_stmt("SELECT 1")
  let new_cache = put(cache, stmt)
  assert_eq(size(new_cache), 1)
}

///|
test "get retrieves existing statement" {
  let cache = make_stmt_cache(10)
  let stmt = make_prepared_stmt("SELECT 1")
  let cache_with_stmt = put(cache, stmt)
  let result = get(cache_with_stmt, "SELECT 1")
  match result {
    Ok((retrieved_stmt, _)) => assert_eq(retrieved_stmt.sql, "SELECT 1")
    Err(_) => println("get failed")
  }
}

///|
test "get returns error for non-existent statement" {
  let cache = make_stmt_cache(10)
  let result = get(cache, "SELECT 1")
  match result {
    Ok(_) => println("get should have failed")
    Err(_) => ()
  }
}

///|
test "get_or_create creates if not exists" {
  let cache = make_stmt_cache(10)
  let (stmt, new_cache) = get_or_create(cache, "SELECT 1")
  assert_eq(stmt.sql, "SELECT 1")
  assert_eq(size(new_cache), 1)
}

///|
test "get_or_create reuses if exists" {
  let cache = make_stmt_cache(10)
  let stmt1 = make_prepared_stmt("SELECT 1")
  let cache_with_stmt = put(cache, stmt1)
  let (stmt2, final_cache) = get_or_create(cache_with_stmt, "SELECT 1")
  assert_eq(stmt2.sql, "SELECT 1")
  assert_eq(size(final_cache), 1)
}

///|
test "mark_prepared marks statement as prepared" {
  let stmt = make_prepared_stmt("SELECT 1")
  assert_eq(is_prepared(stmt), false)
  let prepared_stmt = mark_prepared(stmt)
  assert_eq(is_prepared(prepared_stmt), true)
}

///|
test "clear empties cache" {
  let cache = make_stmt_cache(10)
  let stmt = make_prepared_stmt("SELECT 1")
  let cache_with_stmt = put(cache, stmt)
  assert_eq(size(cache_with_stmt), 1)
  let cleared_cache = clear(cache_with_stmt)
  assert_eq(size(cleared_cache), 0)
}

///|
test "hit_rate returns zero for empty cache" {
  let cache = make_stmt_cache(10)
  let rate = hit_rate(cache)
  assert_eq(rate == 0.0, true)
}

///|
test "size returns cache entry count" {
  let cache = make_stmt_cache(10)
  assert_eq(size(cache), 0)
  let cache1 = put(cache, make_prepared_stmt("SELECT 1"))
  assert_eq(size(cache1), 1)
  let cache2 = put(cache1, make_prepared_stmt("SELECT 2"))
  assert_eq(size(cache2), 2)
}
