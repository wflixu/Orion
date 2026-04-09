/// 运行时核心
/// 数据库连接管理、连接池、事务支持

///|
/// 数据库错误类型
pub enum DbError {
  // 连接相关错误
  ConnectionError(String)
  PoolExhausted

  // 查询相关错误
  QueryError(String)
  NotFound

  // 约束违反错误
  UniqueViolation(String)
  ForeignKeyViolation(String)
  CheckViolation(String)

  // 事务相关错误
  TransactionError(String)

  // 超时错误
  Timeout(String)

  // 类型转换错误
  TypeConversionError(String)

  // 其他错误
  UnknownError(String)
}

///|
/// 创建连接错误
pub fn connection_error(msg : String) -> DbError {
  DbError::ConnectionError(msg)
}

///|
/// 创建查询错误
pub fn query_error(msg : String) -> DbError {
  DbError::QueryError(msg)
}

///|
/// 创建唯一约束违反错误
pub fn unique_violation(msg : String) -> DbError {
  DbError::UniqueViolation(msg)
}

///|
/// 创建外键约束违反错误
pub fn foreign_key_violation(msg : String) -> DbError {
  DbError::ForeignKeyViolation(msg)
}

///|
/// 创建事务错误
pub fn transaction_error(msg : String) -> DbError {
  DbError::TransactionError(msg)
}

///|
/// 创建超时错误
pub fn timeout_error(msg : String) -> DbError {
  DbError::Timeout(msg)
}

///|
/// 检查错误是否为可重试错误
pub fn is_retryable(err : DbError) -> Bool {
  match err {
    DbError::ConnectionError(_) => true
    DbError::Timeout(_) => true
    DbError::PoolExhausted => true
    _ => false
  }
}

///|
/// 获取错误消息
pub fn error_message(err : DbError) -> String {
  match err {
    DbError::ConnectionError(msg) => "Connection error: " + msg
    DbError::QueryError(msg) => "Query error: " + msg
    DbError::PoolExhausted => "Connection pool exhausted"
    DbError::NotFound => "Record not found"
    DbError::UniqueViolation(msg) => "Unique constraint violation: " + msg
    DbError::ForeignKeyViolation(msg) =>
      "Foreign key constraint violation: " + msg
    DbError::CheckViolation(msg) => "Check constraint violation: " + msg
    DbError::TransactionError(msg) => "Transaction error: " + msg
    DbError::Timeout(msg) => "Operation timeout: " + msg
    DbError::TypeConversionError(msg) => "Type conversion error: " + msg
    DbError::UnknownError(msg) => "Unknown error: " + msg
  }
}

///|
/// 数据库值类型
pub enum DbValue {
  Null
  Int(Int)
  String(String)
  Bool(Bool)
}

///|
/// 数据库配置
pub struct DbConfig {
  url : String
  pool_size : Int
}

///|
/// 数据库连接
pub struct Db {
  config : DbConfig
  connected : Bool
}

///|
/// 创建数据库配置
pub fn make_db_config(url : String, pool_size : Int) -> DbConfig {
  { url, pool_size }
}

///|
/// 连接数据库
pub fn connect(config : DbConfig) -> Db {
  { config, connected: true }
}

///|
/// 关闭数据库连接
pub fn close(db : Db) -> Result[Unit, DbError] {
  if db.connected {
    Ok(())
  } else {
    Err(DbError::ConnectionError("Already closed"))
  }
}

///|
/// 执行查询
pub fn query(
  db : Db,
  _sql : String,
  _params : Array[DbValue],
) -> Result[Array[DbValue], DbError] {
  if !db.connected {
    return Err(DbError::ConnectionError("Not connected"))
  }
  // TODO: 实际实现
  Ok([])
}

///|
/// 执行命令（返回影响行数）
pub fn execute(
  db : Db,
  _sql : String,
  _params : Array[DbValue],
) -> Result[Int, DbError] {
  if !db.connected {
    return Err(DbError::ConnectionError("Not connected"))
  }
  // TODO: 实际实现
  Ok(0)
}

///|
/// DbValue 辅助构造函数
pub fn make_db_value_int(v : Int) -> DbValue {
  DbValue::Int(v)
}

///|
pub fn make_db_value_string(v : String) -> DbValue {
  DbValue::String(v)
}

///|
pub fn make_db_value_bool(v : Bool) -> DbValue {
  DbValue::Bool(v)
}

///|
pub fn make_db_value_null() -> DbValue {
  DbValue::Null
}
