/// 数据库事务支持
/// 提供事务的开始、提交、回滚功能

///|
/// 事务状态
pub enum TxStatus {
  /// 事务进行中
  Active
}

///|
/// 检查事务状态是否为 Active
fn is_status_active(_status : TxStatus) -> Bool {
  true
}

///|
/// 事务上下文
pub struct Tx {
  /// 关联的数据库连接
  db : Db
  /// 事务状态
  status : TxStatus
}

///|
/// 开始事务
pub fn begin_tx(db : Db) -> Result[Tx, DbError] {
  // 执行 BEGIN 语句
  let result = execute(db, "BEGIN", [])
  match result {
    Ok(_) => Ok({ db, status: TxStatus::Active })
    Err(e) => Err(e)
  }
}

///|
/// 提交事务
pub fn commit_tx(tx : Tx) -> Result[Unit, DbError] {
  if !is_status_active(tx.status) {
    return Err(DbError::QueryError("Transaction is not active"))
  }
  let result = execute(tx.db, "COMMIT", [])
  match result {
    Ok(_) =>
      // 更新状态
      Ok(())
    Err(e) => Err(e)
  }
}

///|
/// 回滚事务
pub fn rollback_tx(tx : Tx) -> Result[Unit, DbError] {
  if !is_status_active(tx.status) {
    return Err(DbError::QueryError("Transaction is not active"))
  }
  let result = execute(tx.db, "ROLLBACK", [])
  match result {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
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
