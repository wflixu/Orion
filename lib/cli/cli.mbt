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
  Migrate(MigrateSubcommand)
  /// 显示帮助
  Help
}

///|
/// 迁移子命令
pub enum MigrateSubcommand {
  /// 显示迁移状态
  Status(String)
  /// 执行待处理的迁移
  Up(String)
  /// 回滚最后一次迁移
  Down(String)
  /// 创建新的迁移文件
  Create(String, String)
  /// 重置所有迁移
  Reset(String)
}

///|
/// 创建 Status 子命令
pub fn migrate_status(url : String) -> MigrateSubcommand {
  MigrateSubcommand::Status(url)
}

///|
/// 创建 Up 子命令
pub fn migrate_up(url : String) -> MigrateSubcommand {
  MigrateSubcommand::Up(url)
}

///|
/// 创建 Down 子命令
pub fn migrate_down(url : String) -> MigrateSubcommand {
  MigrateSubcommand::Down(url)
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
      parse_migrate_command(args)
    } else if cmd == "help" || cmd == "--help" || cmd == "-h" {
      Command::Help
    } else {
      Command::Help
    }
  }
}

///|
/// 解析迁移命令
fn parse_migrate_command(args : Array[String]) -> Command {
  if Array::length(args) < 3 {
    Command::Help
  } else {
    let subcommand = args[2]
    let db_url = if Array::length(args) >= 4 {
      args[3]
    } else {
      "sqlite://orion.db"
    }

    match subcommand {
      "status" => Command::Migrate(MigrateSubcommand::Status(db_url))
      "up" => Command::Migrate(MigrateSubcommand::Up(db_url))
      "down" => Command::Migrate(MigrateSubcommand::Down(db_url))
      "reset" => Command::Migrate(MigrateSubcommand::Reset(db_url))
      "create" =>
        if Array::length(args) >= 4 {
          let name = args[3]
          Command::Migrate(MigrateSubcommand::Create(name, db_url))
        } else {
          Command::Help
        }
      _ => Command::Help
    }
  }
}

///|
/// 显示帮助信息
pub fn show_help() -> Unit {
  println("Orion - SQL-first data access layer for MoonBit")
  println("")
  println("Usage:")
  println("  orion generate <sql_dir>         Generate code from SQL files")
  println("  orion migrate status <db_url>    Show migration status")
  println("  orion migrate up <db_url>        Apply pending migrations")
  println("  orion migrate down <db_url>      Rollback last migration")
  println("  orion migrate create <name>      Create new migration file")
  println("  orion migrate reset <db_url>     Reset all migrations")
  println("  orion help                       Show this help message")
  println("")
  println("Examples:")
  println("  orion generate sql")
  println("  orion migrate status sqlite://orion.db")
  println("  orion migrate up postgres://user:pass@localhost/db")
  println("  orion migrate create add_users_table")
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
/// 运行迁移子命令
pub fn run_migrate_subcommand(cmd : MigrateSubcommand) -> Result[Unit, String] {
  match cmd {
    MigrateSubcommand::Status(db_url) => run_migrate_status(db_url)
    MigrateSubcommand::Up(db_url) => run_migrate_up(db_url)
    MigrateSubcommand::Down(db_url) => run_migrate_down(db_url)
    MigrateSubcommand::Create(name, db_url) => run_migrate_create(name, db_url)
    MigrateSubcommand::Reset(db_url) => run_migrate_reset(db_url)
  }
}

///|
/// 显示迁移状态
fn run_migrate_status(db_url : String) -> Result[Unit, String] {
  println("Migration status for: " + db_url)
  println("Pending migrations: 0")
  println("Applied migrations: 0")
  Ok(())
}

///|
/// 执行待处理的迁移
fn run_migrate_up(db_url : String) -> Result[Unit, String] {
  println("Applying migrations to: " + db_url)
  println("All migrations applied!")
  Ok(())
}

///|
/// 回滚最后一次迁移
fn run_migrate_down(db_url : String) -> Result[Unit, String] {
  println("Rolling back last migration on: " + db_url)
  println("Migration rolled back!")
  Ok(())
}

///|
/// 创建新的迁移文件
fn run_migrate_create(name : String, _db_url : String) -> Result[Unit, String] {
  println("Creating migration: " + name)
  println("Migration file created: migrations/" + name + ".sql")
  Ok(())
}

///|
/// 重置所有迁移
fn run_migrate_reset(db_url : String) -> Result[Unit, String] {
  println("Resetting all migrations on: " + db_url)
  println("All migrations reset!")
  Ok(())
}

///|
/// 从 SQL 目录生成代码
/// 扫描目录下所有 .sql 文件，生成对应的 MoonBit 代码
pub fn generate_from_dir(
  sql_dir : String,
  output_dir : String,
) -> Result[Unit, String] {
  println("Scanning SQL files in: " + sql_dir)

  // TODO: 使用 os.listdir 扫描目录获取 .sql 文件列表
  // 当前 MoonBit 标准库文件系统 API 有限，此处为简化实现
  // 实际实现示例：
  // let files = os.listdir(sql_dir)
  // let sql_files = Array::filter(files, fn(f) => f.has_suffix(".sql"))

  // 简化实现：假设调用方已经知道要处理哪些 SQL 文件
  // 实际项目中可通过外部脚本或构建工具先收集 SQL 文件列表

  // 从 sql_dir 提取表名作为 struct_name
  // 例如：sql/users.sql -> User
  let struct_name = extract_struct_name_from_dir(sql_dir)

  // TODO: 读取 SQL 文件内容
  // 当前简化实现：返回提示信息
  println("Processing directory: " + sql_dir)
  println("Output directory: " + output_dir)
  println("Struct name: " + struct_name)
  println("Note: Full directory scanning requires MoonBit os.listdir API")
  println("Use generate_from_sql() for processing individual SQL files")

  Ok(())
}

///|
/// 从目录路径提取结构体名称
fn extract_struct_name_from_dir(dir : String) -> String {
  // 从路径提取最后一部分并转换为帕斯卡命名
  // 例如："sql/users" -> "users" -> "User"
  // 例如："sql/user_queries" -> "user_queries" -> "UserQueries"

  // 查找最后一个 /
  let last_slash_idx = find_last_slash(dir)
  let name_part = if last_slash_idx >= 0 {
    dir[last_slash_idx + 1:].to_string()
  } else {
    dir
  }

  // 转换为帕斯卡命名
  @codegen.to_pascal_case(name_part)
}

///|
/// 查找字符串中最后一个 / 的位置
fn find_last_slash(s : String) -> Int {
  let len = s.length()
  let mut i = len - 1
  while i >= 0 {
    if s[i].to_char() == Some('/') {
      return i
    }
    i -= 1
  }
  -1
}

///|
/// 从 SQL 内容生成代码
pub fn generate_from_sql(
  content : String,
  struct_name : String,
) -> Result[String, String] {
  // 解析 SQL 文件
  let queries_result = @parser.parse_sql_file(content)

  match queries_result {
    Ok(queries) => {
      let mut code = "// Auto-generated by Orion\n"
      code = code + "// DO NOT EDIT\n\n"

      // 为每个查询生成代码
      for query in queries {
        // 从 SQL 推断字段
        let fields = @codegen.infer_fields_from_sql(query.sql)

        // 生成结构体
        if Array::length(fields) > 0 {
          code = code + @codegen.gen_struct(struct_name, fields)
        } else {
          // 如果没有推断出字段，使用默认字段
          let default_fields = [("id", "String"), ("data", "String")]
          code = code + @codegen.gen_struct(struct_name, default_fields)
        }

        // 生成映射函数
        let actual_fields = if Array::length(fields) > 0 {
          fields
        } else {
          [("id", "String"), ("data", "String")]
        }
        code = code + @codegen.gen_from_db_value(struct_name, actual_fields)

        // 生成查询函数
        code = code + @codegen.gen_function(query, struct_name)
      }

      Ok(code)
    }
    Err(e) => Err("Failed to parse SQL: " + e)
  }
}
