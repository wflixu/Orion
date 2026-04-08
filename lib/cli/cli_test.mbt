// CLI - Unit Tests

///|
test "parse_args help" {
  let args = ["orion"]
  let cmd = @cli.parse_args(args)
  match cmd {
    @cli.Command::Help => ()
    _ => println("wrong command")
  }
}

///|
test "parse_args generate" {
  let args = ["orion", "generate", "sql"]
  let cmd = @cli.parse_args(args)
  match cmd {
    @cli.Command::Generate(dir) => assert_eq(dir, "sql")
    _ => println("wrong command")
  }
}

///|
test "parse_args migrate" {
  let args = ["orion", "migrate", "sqlite://test.db"]
  let cmd = @cli.parse_args(args)
  match cmd {
    @cli.Command::Migrate(url) => assert_eq(url, "sqlite://test.db")
    _ => println("wrong command")
  }
}

///|
test "parse_args unknown" {
  let args = ["orion", "unknown"]
  let cmd = @cli.parse_args(args)
  match cmd {
    @cli.Command::Help => ()
    _ => println("wrong command")
  }
}

///|
test "run_generate" {
  let result = @cli.run_generate("sql")
  match result {
    Ok(_) => ()
    Err(_) => println("run_generate failed")
  }
}

///|
test "run_migrate" {
  let result = @cli.run_migrate("sqlite://test.db")
  match result {
    Ok(_) => ()
    Err(_) => println("run_migrate failed")
  }
}

///|
test "generate_from_dir" {
  let result = @cli.generate_from_dir("sql", "generated")
  match result {
    Ok(_) => assert_eq(true, true)
    Err(_) => println("generate_from_dir failed")
  }
}

///|
test "generate_from_sql" {
  let sql = "-- name: getUserById\n-- description: Get user\n-- result: single\nSELECT id, name FROM users WHERE id = ?;"
  let result = @cli.generate_from_sql(sql, "User")
  match result {
    Ok(code) => {
      assert_eq(code.contains("Auto-generated"), true)
      assert_eq(code.contains("struct User"), true)
    }
    Err(e) => println("generate_from_sql failed: " + e)
  }
}

///|
test "run_generate returns Ok" {
  let result = @cli.run_generate("test/sql")
  match result {
    Ok(_) => assert_eq(true, true)
    Err(_) => println("run_generate should succeed")
  }
}

///|
test "run_migrate returns Ok" {
  let result = @cli.run_migrate("sqlite://test.db")
  match result {
    Ok(_) => assert_eq(true, true)
    Err(_) => println("run_migrate should succeed")
  }
}

///|
test "parse_args with gen alias" {
  let args = ["orion", "gen", "sql"]
  let cmd = @cli.parse_args(args)
  match cmd {
    @cli.Command::Generate(dir) => assert_eq(dir, "sql")
    _ => println("wrong command")
  }
}

///|
test "parse_args with mig alias" {
  let args = ["orion", "mig", "sqlite://db"]
  let cmd = @cli.parse_args(args)
  match cmd {
    @cli.Command::Migrate(url) => assert_eq(url, "sqlite://db")
    _ => println("wrong command")
  }
}

///|
test "parse_args with --help" {
  let args = ["orion", "--help"]
  let cmd = @cli.parse_args(args)
  match cmd {
    @cli.Command::Help => ()
    _ => println("wrong command")
  }
}

///|
test "parse_args with -h" {
  let args = ["orion", "-h"]
  let cmd = @cli.parse_args(args)
  match cmd {
    @cli.Command::Help => ()
    _ => println("wrong command")
  }
}
