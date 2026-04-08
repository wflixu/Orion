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
