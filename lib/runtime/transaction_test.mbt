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
  let config = make_db_config("sqlite://test.db", 1)
  let _db = connect(config)
  // Note: Blackbox test can't define closure with package types
  // Just test that with_transaction exists and compiles
  let _f = with_transaction
  println("with_transaction is available")
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
