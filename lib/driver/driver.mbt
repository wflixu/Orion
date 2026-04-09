/// 数据库驱动适配层
/// SQLite 和 PostgreSQL 驱动实现

///|
/// 数据库类型枚举
pub enum DbType {
  SQLite
  PostgreSQL
  MySQL
}

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
  _driver : SQLiteDriver,
  db : @runtime.Db,
) -> Result[Unit, @runtime.DbError] {
  @runtime.close(db)
}

///|
/// SQLite 驱动查询
pub fn sqlite_query(
  _driver : SQLiteDriver,
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
  _driver : SQLiteDriver,
  db : @runtime.Db,
  sql : String,
  params : Array[@runtime.DbValue],
) -> Result[Int, @runtime.DbError] {
  // TODO: 实际 SQLite 执行
  @runtime.execute(db, sql, params)
}

///|
/// 获取 SQLite 驱动类型
pub fn sqlite_db_type(_driver : SQLiteDriver) -> DbType {
  DbType::SQLite
}

///|
/// 测试 SQLite 连接
pub fn sqlite_test_connection(
  driver : SQLiteDriver,
) -> Result[Bool, @runtime.DbError] {
  match sqlite_connect(driver) {
    Ok(db) => {
      let result = @runtime.execute(db, "SELECT 1", [])
      match result {
        Ok(_) => {
          let _ = @runtime.close(db)
          Ok(true)
        }
        Err(e) => {
          let _ = @runtime.close(db)
          Err(e)
        }
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// PostgreSQL 驱动
pub struct PostgresDriver {
  url : String
  host : String
  port : Int
  database : String
  username : String
  password : String
}

///|
/// 解析 PostgreSQL URL
/// 格式：postgres://user:pass@host:port/dbname
fn parse_postgres_url(
  url : String,
) -> (String, String, Int, String, String, String) {
  // 默认值
  let default_port = 5432
  let default_database = "postgres"
  let default_username = ""
  let default_password = ""

  // 移除协议前缀
  let url_without_scheme = if url.has_prefix("postgres://") {
    url[11:].to_string()
  } else if url.has_prefix("postgresql://") {
    url[13:].to_string()
  } else {
    url
  }

  // 查找 @ 分隔 credentials 和 host
  let at_idx = url_without_scheme.find("@")

  let (credentials_part, host_port_db_part) = match at_idx {
    Some(idx) => {
      let creds = url_without_scheme[0:idx].to_string()
      let rest = url_without_scheme[idx + 1:].to_string()
      (Some(creds), rest)
    }
    None => (None, url_without_scheme)
  }

  // 解析 credentials (user:pass)
  let (username, password) = match credentials_part {
    Some(creds) => {
      let colon_idx = creds.find(":")
      match colon_idx {
        Some(idx) => (creds[0:idx].to_string(), creds[idx + 1:].to_string())
        None => (creds, "")
      }
    }
    None => (default_username, default_password)
  }

  // 解析 host:port/dbname
  // 先找 / 分隔 host:port 和 dbname
  let (host_port_part, database) = match host_port_db_part.find("/") {
    Some(idx) => {
      let hp = host_port_db_part[0:idx].to_string()
      let db = host_port_db_part[idx + 1:].to_string()
      (hp, db)
    }
    None => (host_port_db_part, default_database)
  }

  // 解析 host:port
  let (host, port) = match host_port_part.find(":") {
    Some(idx) => {
      let h = host_port_part[0:idx].to_string()
      let p_str = host_port_part[idx + 1:].to_string()
      (h, parse_port(p_str, default_port))
    }
    None => (host_port_part, default_port)
  }

  ("postgres", host, port, database, username, password)
}

///|
/// 解析端口字符串为 Int
pub fn parse_port(s : String, default : Int) -> Int {
  let len = s.length()
  if len == 0 {
    default
  } else {
    let mut result = 0
    let mut i = 0
    while i < len {
      let c = s[i]
      let digit = c.to_int() - '0'.to_int()
      if digit >= 0 && digit <= 9 {
        result = result * 10 + digit
      }
      i += 1
    }
    if result == 0 {
      default
    } else {
      result
    }
  }
}

///|
/// 创建 PostgreSQL 驱动
pub fn make_postgres_driver(url : String) -> PostgresDriver {
  let (_scheme, host, port, database, username, password) = parse_postgres_url(
    url,
  )
  { url, host, port, database, username, password }
}

///|
/// PostgreSQL 驱动连接
pub fn postgres_connect(
  driver : PostgresDriver,
) -> Result[@runtime.Db, @runtime.DbError] {
  // TODO: 实际 PostgreSQL 连接
  let config = @runtime.make_db_config(driver.url, 10)
  Ok(@runtime.connect(config))
}

///|
/// PostgreSQL 驱动断开连接
pub fn postgres_disconnect(
  _driver : PostgresDriver,
  db : @runtime.Db,
) -> Result[Unit, @runtime.DbError] {
  @runtime.close(db)
}

///|
/// PostgreSQL 驱动查询
pub fn postgres_query(
  _driver : PostgresDriver,
  db : @runtime.Db,
  sql : String,
  params : Array[@runtime.DbValue],
) -> Result[Array[@runtime.DbValue], @runtime.DbError] {
  // TODO: 实际 PostgreSQL 查询
  @runtime.query(db, sql, params)
}

///|
/// PostgreSQL 驱动执行
pub fn postgres_execute(
  _driver : PostgresDriver,
  db : @runtime.Db,
  sql : String,
  params : Array[@runtime.DbValue],
) -> Result[Int, @runtime.DbError] {
  // TODO: 实际 PostgreSQL 执行
  @runtime.execute(db, sql, params)
}

///|
/// 获取 PostgreSQL 驱动类型
pub fn postgres_db_type(_driver : PostgresDriver) -> DbType {
  DbType::PostgreSQL
}

///|
/// 测试 PostgreSQL 连接
pub fn postgres_test_connection(
  driver : PostgresDriver,
) -> Result[Bool, @runtime.DbError] {
  match postgres_connect(driver) {
    Ok(db) => {
      let result = @runtime.execute(db, "SELECT 1", [])
      match result {
        Ok(_) => {
          let _ = @runtime.close(db)
          Ok(true)
        }
        Err(e) => {
          let _ = @runtime.close(db)
          Err(e)
        }
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// 构建 PostgreSQL 连接字符串
pub fn postgres_build_connection_string(driver : PostgresDriver) -> String {
  "postgres://" +
  driver.username +
  ":" +
  driver.password +
  "@" +
  driver.host +
  ":" +
  driver.port.to_string() +
  "/" +
  driver.database
}

///|
/// 将 SQLite 风格参数占位符 (?) 转换为 PostgreSQL 风格 ($1, $2, ...)
pub fn postgres_convert_params(sql : String) -> String {
  convert_params_iter(sql, 1)
}

///|
/// 迭代转换参数占位符
fn convert_params_iter(sql : String, param_index : Int) -> String {
  let q_index = sql.find("?")
  match q_index {
    Some(idx) => {
      let before = sql[0:idx].to_string()
      let after = sql[idx + 1:].to_string()
      before +
      "$" +
      param_index.to_string() +
      convert_params_iter(after, param_index + 1)
    }
    None => sql
  }
}

///|
/// PostgreSQL 连接选项
pub struct PostgresConnectOptions {
  host : String
  port : Int
  database : String
  username : String
  password : String
  ssl_mode : String
  connect_timeout : Int
}

///|
/// 创建默认 PostgreSQL 连接选项
pub fn postgres_default_options() -> PostgresConnectOptions {
  {
    host: "localhost",
    port: 5432,
    database: "postgres",
    username: "",
    password: "",
    ssl_mode: "disable",
    connect_timeout: 30,
  }
}

///|
/// 从选项构建连接字符串
pub fn postgres_build_options_string(
  options : PostgresConnectOptions,
) -> String {
  let base = "postgres://" +
    options.username +
    ":" +
    options.password +
    "@" +
    options.host +
    ":" +
    options.port.to_string() +
    "/" +
    options.database
  let params = "?sslmode=" +
    options.ssl_mode +
    "&connect_timeout=" +
    options.connect_timeout.to_string()
  base + params
}
