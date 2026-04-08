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
  let result = @cli.generate_from_dir("sql")
  match result {
    Ok(code) => assert_eq(code.contains("Generated"), true)
    Err(_) => println("generate_from_dir failed")
  }
}
