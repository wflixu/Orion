/// 运行时核心
/// 数据库连接管理、连接池、事务支持

///|
/// 数据库错误类型
pub enum DbError {
  ConnectionError(String)
  QueryError(String)
  PoolExhausted
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
