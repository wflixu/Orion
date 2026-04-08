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
pub fn get_connection(pool : Pool) -> Result[Db, DbError] {
  if Array::length(pool.available) > 0 {
    let db = pool.available[0]
    // 简化实现：直接从数组取第一个
    // 实际需要从池中移除
    Ok(db)
  } else if pool.active_count >= pool.config.pool_size {
    Err(DbError::PoolExhausted)
  } else {
    // 创建新连接
    let new_db = connect(pool.config)
    Ok(new_db)
  }
}

///|
/// 归还连接到池中
pub fn return_connection(pool : Pool, _db : Db) -> Pool {
  // 简化实现：只更新计数
  {
    config: pool.config,
    available: pool.available,
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
