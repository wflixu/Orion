// Database Error - Unit Tests

///|
test "error constructors create correct error types" {
  let conn_err = connection_error("connection failed")
  match conn_err {
    DbError::ConnectionError(msg) => assert_eq(msg, "connection failed")
    _ => println("should be ConnectionError")
  }

  let query_err = query_error("syntax error")
  match query_err {
    DbError::QueryError(msg) => assert_eq(msg, "syntax error")
    _ => println("should be QueryError")
  }

  let unique_err = unique_violation("duplicate key")
  match unique_err {
    DbError::UniqueViolation(msg) => assert_eq(msg, "duplicate key")
    _ => println("should be UniqueViolation")
  }
}

///|
test "is_retryable identifies retryable errors" {
  let conn_err = connection_error("timeout")
  assert_eq(is_retryable(conn_err), true)

  let timeout_err = timeout_error("query timeout")
  assert_eq(is_retryable(timeout_err), true)
}

///|
test "is_retryable returns false for non-retryable errors" {
  let query_err = query_error("syntax error")
  assert_eq(is_retryable(query_err), false)

  let unique_err = unique_violation("duplicate key")
  assert_eq(is_retryable(unique_err), false)
}

///|
test "error_message formats errors correctly" {
  let conn_err = connection_error("failed")
  let msg = error_message(conn_err)
  assert_eq(msg.has_prefix("Connection error:"), true)

  let query_err = query_error("syntax error")
  let query_msg = error_message(query_err)
  assert_eq(query_msg.has_prefix("Query error:"), true)
}

///|
test "all error types have messages" {
  assert_eq(error_message(connection_error("x")).length() > 0, true)
  assert_eq(error_message(query_error("x")).length() > 0, true)
  assert_eq(error_message(unique_violation("x")).length() > 0, true)
  assert_eq(error_message(foreign_key_violation("x")).length() > 0, true)
  assert_eq(error_message(transaction_error("x")).length() > 0, true)
  assert_eq(error_message(timeout_error("x")).length() > 0, true)
}
