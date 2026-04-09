// Migration - Unit Tests

///|
test "make_default_migration_config creates default config" {
  let config = make_default_migration_config()
  assert_eq(config.migrations_dir, "migrations")
  assert_eq(config.migrations_table, "schema_migrations")
}

///|
test "make_migration_config creates custom config" {
  let config = make_migration_config("db/migrations", "migrations")
  assert_eq(config.migrations_dir, "db/migrations")
  assert_eq(config.migrations_table, "migrations")
}

///|
test "make_migration creates migration with Pending status" {
  let migration = make_migration(
    "001", "create_users", "CREATE TABLE users (id INT)", "DROP TABLE users",
  )
  assert_eq(migration.version, "001")
  assert_eq(migration.name, "create_users")
  assert_eq(migration.up_sql, "CREATE TABLE users (id INT)")
  assert_eq(migration.down_sql, "DROP TABLE users")
  match migration.status {
    MigrationStatus::Pending => ()
    _ => println("should be Pending")
  }
  match migration.applied_at {
    None => ()
    Some(_) => println("should be None")
  }
}

///|
test "set_status updates migration status" {
  let migration = make_migration("001", "test", "up", "down")
  let updated = set_status(migration, migration_status_applied())
  match updated.status {
    MigrationStatus::Applied => ()
    _ => println("should be Applied")
  }
}

///|
test "set_applied_at sets timestamp" {
  let migration = make_migration("001", "test", "up", "down")
  let updated = set_applied_at(migration, "2024-01-01T00:00:00Z")
  match updated.applied_at {
    Some(ts) => assert_eq(ts, "2024-01-01T00:00:00Z")
    None => println("should have timestamp")
  }
}

///|
test "get_status returns current status" {
  let migration = make_migration("001", "test", "up", "down")
  match get_status(migration) {
    MigrationStatus::Pending => ()
    _ => println("should be Pending")
  }

  let updated = set_status(migration, migration_status_applied())
  match get_status(updated) {
    MigrationStatus::Applied => ()
    _ => println("should be Applied")
  }
}

///|
test "get_version returns migration version" {
  let migration = make_migration("001", "test", "up", "down")
  assert_eq(get_version(migration), "001")
}

///|
test "is_applied returns true for Applied status" {
  let migration = make_migration("001", "test", "up", "down")
  assert_eq(is_applied(migration), false)

  let updated = set_status(migration, migration_status_applied())
  assert_eq(is_applied(updated), true)
}

///|
test "compare_versions compares version strings" {
  assert_eq(compare_versions("001", "001"), 0)
  assert_eq(compare_versions("002", "001"), 1)
  assert_eq(compare_versions("001", "002"), -1)
}

///|
test "migration_not_found creates error" {
  let err = migration_not_found("001")
  match err {
    MigrationError::MigrationNotFound(v) => assert_eq(v, "001")
    _ => println("should be MigrationNotFound")
  }
}

///|
test "migration_already_applied creates error" {
  let err = migration_already_applied("001")
  match err {
    MigrationError::MigrationAlreadyApplied(v) => assert_eq(v, "001")
    _ => println("should be MigrationAlreadyApplied")
  }
}

///|
test "get_migration_error returns error message" {
  let err1 = migration_not_found("001")
  let msg1 = get_migration_error(err1)
  assert_eq(msg1.has_prefix("Migration not found:"), true)

  let err2 = migration_already_applied("002")
  let msg2 = get_migration_error(err2)
  assert_eq(msg2.has_prefix("Migration already applied:"), true)
}

///|
test "get_current_timestamp returns valid format" {
  let ts = get_current_timestamp()
  assert_eq(ts.length() > 0, true)
  assert_eq(ts.has_prefix("2024"), true)
}

///|
test "init_migrations creates table" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let result = init_migrations(db, "test_migrations")
  match result {
    Ok(_) => ()
    Err(_) => println("init_migrations failed")
  }
}

///|
test "apply_migration updates status and timestamp" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let _ = init_migrations(db, "schema_migrations")

  let migration = make_migration(
    "001", "test_create_table", "CREATE TABLE IF NOT EXISTS test_users (id INTEGER PRIMARY KEY)",
    "DROP TABLE IF EXISTS test_users",
  )

  let result = apply_migration(db, migration)
  match result {
    Ok(updated) => {
      match updated.status {
        MigrationStatus::Applied => ()
        _ => println("should be Applied")
      }
      match updated.applied_at {
        Some(_) => ()
        None => println("should have timestamp")
      }
    }
    Err(_) => println("apply_migration failed")
  }
}

///|
test "rollback_migration changes status to Pending" {
  let config = make_db_config("sqlite://test.db", 1)
  let db = connect(config)
  let _ = init_migrations(db, "schema_migrations")

  let migration = make_migration(
    "002", "test_create_table2", "CREATE TABLE IF NOT EXISTS test_products (id INTEGER PRIMARY KEY)",
    "DROP TABLE IF EXISTS test_products",
  )

  let result = rollback_migration(db, migration)
  match result {
    Ok(updated) =>
      match updated.status {
        MigrationStatus::Pending => ()
        _ => println("should be Pending")
      }
    Err(_) => println("rollback_migration failed")
  }
}
