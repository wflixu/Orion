/// 数据库迁移系统
/// 管理数据库版本和迁移脚本执行

///|
/// 迁移方向
pub enum MigrationDirection {
  Up
  Down
}

///|
/// 迁移状态
pub enum MigrationStatus {
  Pending
  Applied
  Failed
}

///|
/// 创建 Pending 状态
pub fn migration_status_pending() -> MigrationStatus {
  MigrationStatus::Pending
}

///|
/// 创建 Applied 状态
pub fn migration_status_applied() -> MigrationStatus {
  MigrationStatus::Applied
}

///|
/// 创建 Failed 状态
pub fn migration_status_failed() -> MigrationStatus {
  MigrationStatus::Failed
}

///|
/// 迁移记录
pub struct Migration {
  /// 迁移版本号（通常是时间戳）
  version : String
  /// 迁移名称
  name : String
  /// Up SQL（升级）
  up_sql : String
  /// Down SQL（降级）
  down_sql : String
  /// 应用状态
  status : MigrationStatus
  /// 应用时间
  applied_at : String?
}

///|
/// 迁移配置
pub struct MigrationConfig {
  /// 迁移文件目录
  migrations_dir : String
  /// 迁移表名
  migrations_table : String
}

///|
/// 创建默认迁移配置
pub fn make_default_migration_config() -> MigrationConfig {
  { migrations_dir: "migrations", migrations_table: "schema_migrations" }
}

///|
/// 创建迁移配置
pub fn make_migration_config(
  migrations_dir : String,
  migrations_table : String,
) -> MigrationConfig {
  { migrations_dir, migrations_table }
}

///|
/// 创建迁移记录
pub fn make_migration(
  version : String,
  name : String,
  up_sql : String,
  down_sql : String,
) -> Migration {
  {
    version,
    name,
    up_sql,
    down_sql,
    status: MigrationStatus::Pending,
    applied_at: None,
  }
}

///|
/// 设置迁移状态
pub fn set_status(migration : Migration, status : MigrationStatus) -> Migration {
  let new_migration = {
    version: migration.version,
    name: migration.name,
    up_sql: migration.up_sql,
    down_sql: migration.down_sql,
    status,
    applied_at: migration.applied_at,
  }
  new_migration
}

///|
/// 设置应用时间
pub fn set_applied_at(migration : Migration, timestamp : String) -> Migration {
  let new_migration = {
    version: migration.version,
    name: migration.name,
    up_sql: migration.up_sql,
    down_sql: migration.down_sql,
    status: migration.status,
    applied_at: Some(timestamp),
  }
  new_migration
}

///|
/// 获取迁移状态
pub fn get_status(migration : Migration) -> MigrationStatus {
  migration.status
}

///|
/// 获取迁移版本
pub fn get_version(migration : Migration) -> String {
  migration.version
}

///|
/// 检查迁移是否已应用
pub fn is_applied(migration : Migration) -> Bool {
  match migration.status {
    MigrationStatus::Applied => true
    _ => false
  }
}

///|
/// 执行迁移
pub fn apply_migration(
  db : Db,
  migration : Migration,
) -> Result[Migration, DbError] {
  // 执行 Up SQL
  let result = execute(db, migration.up_sql, [])
  match result {
    Ok(_) => {
      // 记录到迁移表
      let record_result = record_migration(
        db,
        migration.version,
        migration.name,
      )
      match record_result {
        Ok(_) => {
          let timestamp = get_current_timestamp()
          Ok(
            set_applied_at(
              set_status(migration, MigrationStatus::Applied),
              timestamp,
            ),
          )
        }
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// 回滚迁移
pub fn rollback_migration(
  db : Db,
  migration : Migration,
) -> Result[Migration, DbError] {
  // 执行 Down SQL
  let result = execute(db, migration.down_sql, [])
  match result {
    Ok(_) => {
      // 从迁移表删除记录
      let remove_result = remove_migration(db, migration.version)
      match remove_result {
        Ok(_) => Ok(set_status(migration, MigrationStatus::Pending))
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// 初始化迁移表
pub fn init_migrations(db : Db, table_name : String) -> Result[Unit, DbError] {
  let create_table_sql = "CREATE TABLE IF NOT EXISTS " +
    table_name +
    " (version TEXT PRIMARY KEY, name TEXT, applied_at TEXT)"
  let result = execute(db, create_table_sql, [])
  match result {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

///|
/// 记录已应用的迁移
fn record_migration(
  db : Db,
  version : String,
  name : String,
) -> Result[Unit, DbError] {
  let timestamp = get_current_timestamp()
  let insert_sql = "INSERT INTO schema_migrations (version, name, applied_at) VALUES (?, ?, ?)"
  let params = [
    make_db_value_string(version),
    make_db_value_string(name),
    make_db_value_string(timestamp),
  ]
  let result = execute(db, insert_sql, params)
  match result {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

///|
/// 移除迁移记录
fn remove_migration(db : Db, version : String) -> Result[Unit, DbError] {
  let delete_sql = "DELETE FROM schema_migrations WHERE version = ?"
  let params = [make_db_value_string(version)]
  let result = execute(db, delete_sql, params)
  match result {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

///|
/// 获取当前时间戳（ISO 8601 格式）
pub fn get_current_timestamp() -> String {
  // TODO: 使用实际时间获取
  // 当前 MoonBit 标准库可能没有时间 API，临时返回固定格式
  "2024-01-01T00:00:00Z"
}

///|
/// 获取已应用的迁移版本列表
pub fn get_applied_migrations(db : Db) -> Result[Array[String], DbError] {
  let select_sql = "SELECT version FROM schema_migrations ORDER BY version"
  let result = query(db, select_sql, [])
  match result {
    Ok(rows) =>
      // TODO: 解析结果集提取版本
      // 当前简化实现
      Ok([])
    Err(e) => Err(e)
  }
}

///|
/// 比较版本号
pub fn compare_versions(v1 : String, v2 : String) -> Int {
  // 简单字符串比较
  // 对于时间戳格式，字符串比较即可
  if v1 == v2 {
    0
  } else if v1 > v2 {
    1
  } else {
    -1
  }
}

///|
/// 迁移错误类型
pub enum MigrationError {
  MigrationNotFound(String)
  MigrationAlreadyApplied(String)
  InvalidMigrationFormat(String)
  DatabaseError(String)
}

///|
/// 创建迁移未找到错误
pub fn migration_not_found(version : String) -> MigrationError {
  MigrationError::MigrationNotFound(version)
}

///|
/// 创建迁移已应用错误
pub fn migration_already_applied(version : String) -> MigrationError {
  MigrationError::MigrationAlreadyApplied(version)
}

///|
/// 获取迁移错误消息
pub fn get_migration_error(err : MigrationError) -> String {
  match err {
    MigrationError::MigrationNotFound(v) => "Migration not found: " + v
    MigrationError::MigrationAlreadyApplied(v) =>
      "Migration already applied: " + v
    MigrationError::InvalidMigrationFormat(msg) =>
      "Invalid migration format: " + msg
    MigrationError::DatabaseError(msg) => "Database error: " + msg
  }
}
