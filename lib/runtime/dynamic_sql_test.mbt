// Dynamic SQL - Unit Tests

///|
test "make_sql_builder creates builder with base query" {
  let builder = make_sql_builder("SELECT * FROM users")
  assert_eq(builder.base_query, "SELECT * FROM users")
}

///|
test "where_clause adds condition" {
  let builder = make_sql_builder("SELECT * FROM users")
  let updated = where_clause(builder, equal("status", "'active'"))
  assert_eq(Array::length(updated.conditions), 1)
}

///|
test "build creates simple query" {
  let builder = make_sql_builder("SELECT * FROM users")
  let sql = build(builder)
  assert_eq(sql, "SELECT * FROM users")
}

///|
test "build creates query with WHERE" {
  let builder = make_sql_builder("SELECT * FROM users")
  let with_where = where_clause(builder, equal("status", "'active'"))
  let sql = build(with_where)
  assert_eq(sql, "SELECT * FROM users WHERE status = 'active'")
}

///|
test "build creates query with ORDER BY" {
  let builder = make_sql_builder("SELECT * FROM users")
  let with_order = order_by(builder, make_order("name", true))
  let sql = build(with_order)
  assert_eq(sql, "SELECT * FROM users ORDER BY name ASC")
}

///|
test "build creates query with LIMIT" {
  let builder = make_sql_builder("SELECT * FROM users")
  let with_limit = limit(builder, 10)
  let sql = build(with_limit)
  assert_eq(sql, "SELECT * FROM users LIMIT 10")
}

///|
test "build creates query with OFFSET" {
  let builder = make_sql_builder("SELECT * FROM users")
  let with_offset = offset(builder, 5)
  let sql = build(with_offset)
  assert_eq(sql, "SELECT * FROM users OFFSET 5")
}

///|
test "build creates query with WHERE and ORDER BY" {
  let builder = make_sql_builder("SELECT * FROM users")
  let with_where = where_clause(builder, equal("status", "'active'"))
  let with_order = order_by(with_where, make_order("name", true))
  let sql = build(with_order)
  assert_eq(
    sql.has_prefix("SELECT * FROM users WHERE status = 'active' ORDER BY"),
    true,
  )
}

///|
test "equal creates Equal condition" {
  let condition = equal("status", "'active'")
  match condition {
    SqlCondition::Equal(col, val) => {
      assert_eq(col, "status")
      assert_eq(val, "'active'")
    }
    _ => println("should be Equal")
  }
}

///|
test "not_equal creates NotEqual condition" {
  let condition = not_equal("status", "'inactive'")
  match condition {
    SqlCondition::NotEqual(col, val) => {
      assert_eq(col, "status")
      assert_eq(val, "'inactive'")
    }
    _ => println("should be NotEqual")
  }
}

///|
test "greater_than creates GreaterThan condition" {
  let condition = greater_than("age", "18")
  match condition {
    SqlCondition::GreaterThan(col, val) => {
      assert_eq(col, "age")
      assert_eq(val, "18")
    }
    _ => println("should be GreaterThan")
  }
}

///|
test "less_than creates LessThan condition" {
  let condition = less_than("age", "65")
  match condition {
    SqlCondition::LessThan(col, val) => {
      assert_eq(col, "age")
      assert_eq(val, "65")
    }
    _ => println("should be LessThan")
  }
}

///|
test "like creates Like condition" {
  let condition = like("name", "'John%'")
  match condition {
    SqlCondition::Like(col, val) => {
      assert_eq(col, "name")
      assert_eq(val, "'John%'")
    }
    _ => println("should be Like")
  }
}

///|
test "in_list creates In condition" {
  let values = ["'A'", "'B'", "'C'"]
  let condition = in_list("status", values)
  match condition {
    SqlCondition::In(col, vals) => {
      assert_eq(col, "status")
      assert_eq(Array::length(vals), 3)
    }
    _ => println("should be In")
  }
}

///|
test "is_null creates IsNull condition" {
  let condition = is_null("deleted_at")
  match condition {
    SqlCondition::IsNull(col) => assert_eq(col, "deleted_at")
    _ => println("should be IsNull")
  }
}

///|
test "is_not_null creates IsNotNull condition" {
  let condition = is_not_null("email")
  match condition {
    SqlCondition::IsNotNull(col) => assert_eq(col, "email")
    _ => println("should be IsNotNull")
  }
}

///|
test "raw_sql creates Raw condition" {
  let condition = raw_sql("price > 100")
  match condition {
    SqlCondition::Raw(sql) => assert_eq(sql, "price > 100")
    _ => println("should be Raw")
  }
}

///|
test "build with multiple conditions" {
  let builder = make_sql_builder("SELECT * FROM users")
  let with_cond1 = where_clause(builder, equal("status", "'active'"))
  let with_cond2 = where_clause(with_cond1, greater_than("age", "18"))
  let sql = build(with_cond2)
  assert_eq(sql.contains("status = 'active'"), true)
  assert_eq(sql.contains("age > 18"), true)
}

///|
test "build with DESC order" {
  let builder = make_sql_builder("SELECT * FROM users")
  let with_order = order_by(builder, make_order("created_at", false))
  let sql = build(with_order)
  assert_eq(sql, "SELECT * FROM users ORDER BY created_at DESC")
}

///|
test "build with LIMIT and OFFSET" {
  let builder = make_sql_builder("SELECT * FROM users")
  let with_limit = limit(builder, 10)
  let with_offset = offset(with_limit, 5)
  let sql = build(with_offset)
  assert_eq(sql.contains("LIMIT 10"), true)
  assert_eq(sql.contains("OFFSET 5"), true)
}

///|
test "make_order creates order" {
  let order = make_order("name", true)
  assert_eq(order.column, "name")
  assert_eq(order.ascending, true)
}
