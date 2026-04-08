/// Orion CLI 入口
/// 支持 generate 和 migrate 命令

///|
/// 获取命令行参数
pub fn get_args() -> Array[String] {
  // TODO: 使用 moonbitlang/core/os 获取实际参数
  // 临时返回空数组
  []
}

///|
/// CLI 命令
pub enum Command {
  /// 生成代码
  Generate(String)
  /// 运行迁移
  Migrate(String)
  /// 显示帮助
  Help
}

///|
/// 解析命令行参数
pub fn parse_args(args : Array[String]) -> Command {
  if Array::length(args) < 2 {
    Command::Help
  } else {
    let cmd = args[1]
    if cmd == "generate" || cmd == "gen" {
      if Array::length(args) >= 3 {
        Command::Generate(args[2])
      } else {
        Command::Help
      }
    } else if cmd == "migrate" || cmd == "mig" {
      if Array::length(args) >= 3 {
        Command::Migrate(args[2])
      } else {
        Command::Help
      }
    } else if cmd == "help" || cmd == "--help" || cmd == "-h" {
      Command::Help
    } else {
      Command::Help
    }
  }
}

///|
/// 显示帮助信息
pub fn show_help() -> Unit {
  println("Orion - SQL-first data access layer for MoonBit")
  println("")
  println("Usage:")
  println("  orion generate <sql_dir>   Generate code from SQL files")
  println("  orion migrate <db_url>     Run database migrations")
  println("  orion help                 Show this help message")
}

///|
/// 生成代码
pub fn run_generate(sql_dir : String) -> Result[Unit, String] {
  println("Generating code from SQL files in: " + sql_dir)

  // TODO: 读取 SQL 文件
  // TODO: 解析 SQL 获取 QueryMeta
  // TODO: 生成 MoonBit 代码

  println("Code generation complete!")
  Ok(())
}

///|
/// 运行迁移
pub fn run_migrate(db_url : String) -> Result[Unit, String] {
  println("Running migrations on: " + db_url)

  // TODO: 连接数据库
  // TODO: 执行迁移脚本

  println("Migrations complete!")
  Ok(())
}

///|
/// 从 SQL 目录生成代码
pub fn generate_from_dir(sql_dir : String) -> Result[String, String] {
  println("Scanning SQL files in: " + sql_dir)
  // TODO: 实现目录扫描和代码生成
  Ok("// Generated code from: " + sql_dir)
}
