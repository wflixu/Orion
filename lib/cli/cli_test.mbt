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
