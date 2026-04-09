/// 预编译语句缓存
/// 缓存已编译的 SQL 语句以提高重复查询性能

///|
/// 预编译语句标识
pub struct StmtId {
  sql : String
}

///|
/// 预编译语句
pub struct PreparedStmt {
  id : StmtId
  sql : String
  prepared : Bool
}

///|
/// 语句缓存
pub struct StmtCache {
  capacity : Int
  entries : Array[(String, PreparedStmt)]
  hit_count : Int
  miss_count : Int
}

///|
/// 创建语句缓存
pub fn make_stmt_cache(capacity : Int) -> StmtCache {
  { capacity, entries: [], hit_count: 0, miss_count: 0 }
}

///|
/// 生成语句 ID
pub fn make_stmt_id(sql : String) -> StmtId {
  { sql, }
}

///|
/// 创建预编译语句
pub fn make_prepared_stmt(sql : String) -> PreparedStmt {
  let id = make_stmt_id(sql)
  { id, sql, prepared: false }
}

///|
/// 从缓存获取预编译语句
pub fn get(
  cache : StmtCache,
  sql : String,
) -> Result[(PreparedStmt, StmtCache), DbError] {
  let mut i = 0
  while i < Array::length(cache.entries) {
    let (key, stmt) = cache.entries[i]
    if key == sql {
      let new_cache = {
        capacity: cache.capacity,
        entries: cache.entries,
        hit_count: cache.hit_count + 1,
        miss_count: cache.miss_count,
      }
      return Ok((stmt, new_cache))
    }
    i += 1
  }
  Err(DbError::QueryError("Statement not found in cache"))
}

///|
/// 将预编译语句放入缓存
pub fn put(cache : StmtCache, stmt : PreparedStmt) -> StmtCache {
  let new_entries = cache.entries
  new_entries.push((stmt.sql, stmt))
  {
    capacity: cache.capacity,
    entries: new_entries,
    hit_count: cache.hit_count,
    miss_count: cache.miss_count,
  }
}

///|
/// 获取或创建预编译语句
pub fn get_or_create(
  cache : StmtCache,
  sql : String,
) -> (PreparedStmt, StmtCache) {
  match get(cache, sql) {
    Ok((stmt, new_cache)) => (stmt, new_cache)
    Err(_) => {
      let stmt = make_prepared_stmt(sql)
      let new_cache = put(cache, stmt)
      (stmt, new_cache)
    }
  }
}

///|
/// 获取缓存命中率
pub fn hit_rate(cache : StmtCache) -> Double {
  let total = cache.hit_count + cache.miss_count
  if total == 0 {
    0.0
  } else {
    // Simple division as Double - in real implementation use proper float division
    let hit_ratio = cache.hit_count * 100 / total
    double_from_int(hit_ratio)
  }
}

///|
/// 清空缓存
pub fn clear(cache : StmtCache) -> StmtCache {
  { capacity: cache.capacity, entries: [], hit_count: 0, miss_count: 0 }
}

///|
/// 获取缓存大小
pub fn size(cache : StmtCache) -> Int {
  Array::length(cache.entries)
}

///|
/// 检查语句是否已预编译
pub fn is_prepared(stmt : PreparedStmt) -> Bool {
  stmt.prepared
}

///|
/// 标记语句为已预编译
pub fn mark_prepared(stmt : PreparedStmt) -> PreparedStmt {
  { id: stmt.id, sql: stmt.sql, prepared: true }
}

///|
/// 辅助函数：整数转浮点数（简化实现）
fn double_from_int(i : Int) -> Double {
  // TODO: 使用实际的浮点转换
  if i == 0 {
    0.0
  } else if i == 100 {
    100.0
  } else {
    // 简化实现，返回百分比估算
    let int_part = i / 100
    double_from_int(int_part) + double_from_int(i - int_part * 100) / 100.0
  }
}
