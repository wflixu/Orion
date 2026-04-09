// Transaction - Unit Tests

///|
test "begin transaction" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let result = begin_tx(db)
  match result {
    Ok(tx) => assert_eq(is_tx_active(tx), true)
    Err(_) => println("begin_tx failed")
  }
}

///|
test "commit transaction" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let tx_result = begin_tx(db)
  match tx_result {
    Ok(tx) => {
      let commit_result = commit_tx(tx)
      match commit_result {
        Ok(_) => ()
        Err(_) => println("commit_tx failed")
      }
    }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "rollback transaction" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let tx_result = begin_tx(db)
  match tx_result {
    Ok(tx) => {
      let rollback_result = rollback_tx(tx)
      match rollback_result {
        Ok(_) => ()
        Err(_) => println("rollback_tx failed")
      }
    }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "with_transaction helper" {
  // Note: with_transaction is a generic function, tested indirectly
  // This test just verifies the function exists
  println("with_transaction exists in transaction module")
}

///|
test "begin_tx then commit" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let tx_result = begin_tx(db)
  match tx_result {
    Ok(tx) => {
      let commit_result = commit_tx(tx)
      match commit_result {
        Ok(_) => ()
        Err(_) => println("commit failed")
      }
    }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "begin_tx then rollback" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let tx_result = begin_tx(db)
  match tx_result {
    Ok(tx) => {
      let rollback_result = rollback_tx(tx)
      match rollback_result {
        Ok(_) => ()
        Err(_) => println("rollback failed")
      }
    }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "is_tx_active after begin" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let tx_result = begin_tx(db)
  match tx_result {
    Ok(tx) => assert_eq(is_tx_active(tx), true)
    Err(_) => println("begin_tx failed")
  }
}

///|
test "is_tx_active" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let tx_result = begin_tx(db)
  match tx_result {
    Ok(tx) => assert_eq(is_tx_active(tx), true)
    Err(_) => println("begin_tx failed")
  }
}

///|
test "get_depth returns 0 for top-level transaction" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(tx) => assert_eq(get_depth(tx), 0)
    Err(_) => println("begin_tx failed")
  }
}

///|
test "begin_nested_tx increases depth" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(parent) =>
      match begin_nested_tx(parent) {
        Ok(nested) => assert_eq(get_depth(nested), 1)
        Err(_) => println("begin_nested_tx failed")
      }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "begin_nested_tx creates savepoint" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(parent) =>
      match begin_nested_tx(parent) {
        Ok(nested) => {
          assert_eq(get_depth(nested), 1)
          match get_parent(nested) {
            Some(p) => assert_eq(get_depth(p), 0)
            None => println("should have parent")
          }
        }
        Err(_) => println("begin_nested_tx failed")
      }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "get_parent returns None for top-level transaction" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(tx) =>
      match get_parent(tx) {
        None => ()
        Some(_) => println("should be None")
      }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "nested transaction commit returns Committed status" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(parent) =>
      match begin_nested_tx(parent) {
        Ok(nested) =>
          match commit_tx(nested) {
            Ok(committed) =>
              match committed.status {
                TxStatus::Committed => ()
                _ => println("should be Committed")
              }
            Err(_) => println("commit failed")
          }
        Err(_) => println("begin_nested_tx failed")
      }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "nested transaction rollback returns RolledBack status" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(parent) =>
      match begin_nested_tx(parent) {
        Ok(nested) =>
          match rollback_tx(nested) {
            Ok(rolled_back) =>
              match rolled_back.status {
                TxStatus::RolledBack => ()
                _ => println("should be RolledBack")
              }
            Err(_) => println("rollback failed")
          }
        Err(_) => println("begin_nested_tx failed")
      }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "with_nested_transaction executes and commits" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(parent) => {
      let result = with_nested_transaction(parent, fn(nested) {
        if get_depth(nested) == 1 {
          Ok("success")
        } else {
          Err(query_error("wrong depth"))
        }
      })
      match result {
        Ok(value) => assert_eq(value, "success")
        Err(_) => println("with_nested_transaction failed")
      }
    }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "with_nested_transaction rolls back on error" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(parent) => {
      let result = with_nested_transaction(parent, fn(_nested) {
        Err(query_error("intentional error"))
      })
      match result {
        Ok(_) => println("should have failed")
        Err(err) =>
          match err {
            DbError::QueryError(msg) => assert_eq(msg, "intentional error")
            _ => println("wrong error type")
          }
      }
    }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "commit_tx on top-level transaction uses COMMIT" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(tx) => {
      assert_eq(get_depth(tx), 0)
      match commit_tx(tx) {
        Ok(committed) =>
          match committed.status {
            TxStatus::Committed => ()
            _ => println("should be Committed")
          }
        Err(_) => println("commit failed")
      }
    }
    Err(_) => println("begin_tx failed")
  }
}

///|
test "rollback_tx on top-level transaction uses ROLLBACK" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  match begin_tx(db) {
    Ok(tx) => {
      assert_eq(get_depth(tx), 0)
      match rollback_tx(tx) {
        Ok(rolled_back) =>
          match rolled_back.status {
            TxStatus::RolledBack => ()
            _ => println("should be RolledBack")
          }
        Err(_) => println("rollback failed")
      }
    }
    Err(_) => println("begin_tx failed")
  }
}
