/// 数据库驱动适配层
/// SQLite 驱动实现

///|
/// SQLite 驱动
pub struct SQLiteDriver {
  url : String
}

///|
/// 创建 SQLite 驱动
pub fn make_sqlite_driver(url : String) -> SQLiteDriver {
  { url, }
}

///|
/// SQLite 驱动连接
pub fn sqlite_connect(
  driver : SQLiteDriver,
) -> Result[@runtime.Db, @runtime.DbError] {
  // TODO: 实际 SQLite 连接
  let config = @runtime.make_db_config(driver.url, 10)
  Ok(@runtime.connect(config))
}

///|
/// SQLite 驱动断开连接
pub fn sqlite_disconnect(
  driver : SQLiteDriver,
  db : @runtime.Db,
) -> Result[Unit, @runtime.DbError] {
  @runtime.close(db)
}

///|
/// SQLite 驱动查询
pub fn sqlite_query(
  driver : SQLiteDriver,
  db : @runtime.Db,
  sql : String,
  params : Array[@runtime.DbValue],
) -> Result[Array[@runtime.DbValue], @runtime.DbError] {
  // TODO: 实际 SQLite 查询
  @runtime.query(db, sql, params)
}

///|
/// SQLite 驱动执行
pub fn sqlite_execute(
  driver : SQLiteDriver,
  db : @runtime.Db,
  sql : String,
  params : Array[@runtime.DbValue],
) -> Result[Int, @runtime.DbError] {
  // TODO: 实际 SQLite 执行
  @runtime.execute(db, sql, params)
}
