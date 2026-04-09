///|
/// Orion CLI 主程序
fn main {
  let args = @cli.get_args()
  let cmd = @cli.parse_args(args)

  match cmd {
    @cli.Command::Help => @cli.show_help()
    @cli.Command::Generate(dir) => {
      let result = @cli.run_generate(dir)
      match result {
        Ok(_) => ()
        Err(e) => println("Error: " + e)
      }
    }
    @cli.Command::Migrate(subcmd) => {
      let result = @cli.run_migrate_subcommand(subcmd)
      match result {
        Ok(_) => ()
        Err(e) => println("Error: " + e)
      }
    }
  }
}
