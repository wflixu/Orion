/// 数据库连接池
/// 管理多个数据库连接的复用

///|
/// 连接池状态
pub struct Pool {
  /// 池配置
  config : DbConfig
  /// 可用连接列表
  available : Array[Db]
  /// 当前活跃连接数
  active_count : Int
}

///|
/// 创建连接池
pub fn make_pool(config : DbConfig) -> Pool {
  let initial_size = config.pool_size
  let connections : Array[Db] = []
  let mut i = 0
  while i < initial_size {
    let db = connect(config)
    connections.push(db)
    i += 1
  }
  { config, available: connections, active_count: 0 }
}

///|
/// 从池中获取连接
pub fn get_connection(pool : Pool) -> Result[(Db, Pool), DbError] {
  if Array::length(pool.available) > 0 {
    // 从池中取出第一个连接
    let db = pool.available[0]
    // 创建新的 available 数组，移除第一个元素
    let new_available : Array[Db] = []
    let mut i = 1
    while i < Array::length(pool.available) {
      new_available.push(pool.available[i])
      i += 1
    }
    let new_pool = {
      config: pool.config,
      available: new_available,
      active_count: pool.active_count + 1,
    }
    Ok((db, new_pool))
  } else if pool.active_count >= pool.config.pool_size {
    Err(DbError::PoolExhausted)
  } else {
    // 创建新连接
    let new_db = connect(pool.config)
    let new_pool = {
      config: pool.config,
      available: pool.available,
      active_count: pool.active_count + 1,
    }
    Ok((new_db, new_pool))
  }
}

///|
/// 归还连接到池中
pub fn return_connection(pool : Pool, db : Db) -> Pool {
  // 将连接添加回可用列表
  let new_available = pool.available
  new_available.push(db)
  {
    config: pool.config,
    available: new_available,
    active_count: pool.active_count - 1,
  }
}

///|
/// 关闭连接池
pub fn close_pool(pool : Pool) -> Result[Unit, DbError] {
  let mut i = 0
  while i < Array::length(pool.available) {
    let _ = close(pool.available[i])
    i += 1
  }
  Ok(())
}

///|
/// 获取池中可用连接数
pub fn pool_size(pool : Pool) -> Int {
  Array::length(pool.available)
}
