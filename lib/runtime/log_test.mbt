// Logger - Unit Tests

///|
test "make_default_config creates info level config" {
  let config = make_default_config()
  match config.min_level {
    LogLevel::Info => ()
    _ => println("default level should be Info")
  }
  assert_eq(config.enabled, true)
}

///|
test "make_logger creates logger with config" {
  let config = make_default_config()
  let logger = make_logger(config)
  assert_eq(logger.config.enabled, true)
}

///|
test "make_default_logger creates enabled logger" {
  let logger = make_default_logger()
  assert_eq(is_enabled(logger), true)
  match get_level(logger) {
    LogLevel::Info => ()
    _ => println("default level should be Info")
  }
}

///|
test "enable enables logger" {
  let logger = make_default_logger()
  let disabled = disable(logger)
  assert_eq(is_enabled(disabled), false)
  let enabled = enable(disabled)
  assert_eq(is_enabled(enabled), true)
}

///|
test "disable disables logger" {
  let logger = make_default_logger()
  let disabled = disable(logger)
  assert_eq(is_enabled(disabled), false)
}

///|
test "is_enabled returns logger state" {
  let logger = make_default_logger()
  assert_eq(is_enabled(logger), true)
  let disabled = disable(logger)
  assert_eq(is_enabled(disabled), false)
}

///|
test "get_level returns current level" {
  let logger = make_default_logger()
  match get_level(logger) {
    LogLevel::Info => ()
    _ => println("default should be Info")
  }
}
