/// 数据库事务支持
/// 提供事务的开始、提交、回滚功能

///|
/// 事务状态
pub enum TxStatus {
  /// 事务进行中
  Active
  /// 已提交
  Committed
  /// 已回滚
  RolledBack
  /// 失败
  Failed
}

///|
/// 检查事务状态是否为 Active
fn is_status_active(status : TxStatus) -> Bool {
  match status {
    TxStatus::Active => true
    _ => false
  }
}

///|
/// 事务上下文
pub struct Tx {
  /// 关联的数据库连接
  db : Db
  /// 事务状态
  status : TxStatus
  /// 嵌套深度（0 = 顶层事务）
  depth : Int
  /// 父事务（用于嵌套）
  parent : Tx?
}

///|
/// 创建事务上下文（内部）
fn make_tx(db : Db, depth : Int, parent : Tx?) -> Tx {
  { db, status: TxStatus::Active, depth, parent }
}

///|
/// 生成保存点名称
fn make_savepoint_name(depth : Int) -> String {
  "sp_" + depth.to_string()
}

///|
/// 开始事务
pub fn begin_tx(db : Db) -> Result[Tx, DbError] {
  // 执行 BEGIN 语句
  let result = execute(db, "BEGIN", [])
  match result {
    Ok(_) => Ok(make_tx(db, 0, None))
    Err(e) => Err(e)
  }
}

///|
/// 提交事务
pub fn commit_tx(tx : Tx) -> Result[Tx, DbError] {
  if !is_status_active(tx.status) {
    return Err(DbError::QueryError("Transaction is not active"))
  }

  let result = if tx.depth == 0 {
    // 顶层事务：使用 COMMIT
    execute(tx.db, "COMMIT", [])
  } else {
    // 嵌套事务：使用 RELEASE SAVEPOINT
    let sp_name = make_savepoint_name(tx.depth)
    execute(tx.db, "RELEASE SAVEPOINT " + sp_name, [])
  }

  match result {
    Ok(_) => {
      let committed_tx = make_tx(tx.db, tx.depth, tx.parent)
      let final_tx = {
        db: committed_tx.db,
        status: TxStatus::Committed,
        depth: committed_tx.depth,
        parent: committed_tx.parent,
      }
      Ok(final_tx)
    }
    Err(e) => Err(e)
  }
}

///|
/// 回滚事务
pub fn rollback_tx(tx : Tx) -> Result[Tx, DbError] {
  if !is_status_active(tx.status) {
    return Err(DbError::QueryError("Transaction is not active"))
  }

  let result = if tx.depth == 0 {
    // 顶层事务：使用 ROLLBACK
    execute(tx.db, "ROLLBACK", [])
  } else {
    // 嵌套事务：使用 ROLLBACK TO SAVEPOINT
    let sp_name = make_savepoint_name(tx.depth)
    execute(tx.db, "ROLLBACK TO SAVEPOINT " + sp_name, [])
  }

  match result {
    Ok(_) => {
      let rolled_back_tx = make_tx(tx.db, tx.depth, tx.parent)
      let final_tx = {
        db: rolled_back_tx.db,
        status: TxStatus::RolledBack,
        depth: rolled_back_tx.depth,
        parent: rolled_back_tx.parent,
      }
      Ok(final_tx)
    }
    Err(e) => Err(e)
  }
}

///|
/// 开始嵌套事务（使用 SAVEPOINT）
pub fn begin_nested_tx(parent : Tx) -> Result[Tx, DbError] {
  if !is_status_active(parent.status) {
    return Err(DbError::TransactionError("Parent transaction is not active"))
  }

  let new_depth = parent.depth + 1
  let sp_name = make_savepoint_name(new_depth)

  // 创建保存点
  let result = execute(parent.db, "SAVEPOINT " + sp_name, [])
  match result {
    Ok(_) => Ok(make_tx(parent.db, new_depth, Some(parent)))
    Err(e) => Err(e)
  }
}

///|
/// 在嵌套事务中执行操作
pub fn[T] with_nested_transaction(
  parent : Tx,
  f : (Tx) -> Result[T, DbError],
) -> Result[T, DbError] {
  let tx_result = begin_nested_tx(parent)
  match tx_result {
    Ok(tx) => {
      let result = f(tx)
      match result {
        Ok(value) =>
          match commit_tx(tx) {
            Ok(_) => Ok(value)
            Err(e) => Err(e)
          }
        Err(e) => {
          let _ = rollback_tx(tx)
          Err(e)
        }
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// 获取事务深度
pub fn get_depth(tx : Tx) -> Int {
  tx.depth
}

///|
/// 获取父事务
pub fn get_parent(tx : Tx) -> Tx? {
  tx.parent
}

///|
/// 在事务中执行操作
pub fn[T] with_transaction(
  db : Db,
  f : (Tx) -> Result[T, DbError],
) -> Result[T, DbError] {
  let tx_result = begin_tx(db)
  match tx_result {
    Ok(tx) => {
      let result = f(tx)
      match result {
        Ok(value) =>
          match commit_tx(tx) {
            Ok(_) => Ok(value)
            Err(e) => Err(e)
          }
        Err(e) => {
          let _ = rollback_tx(tx)
          Err(e)
        }
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// 检查事务是否活跃
pub fn is_tx_active(tx : Tx) -> Bool {
  is_status_active(tx.status)
}
