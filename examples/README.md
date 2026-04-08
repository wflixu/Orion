# Orion Examples

## Code Generation Demo

Run the code generation demo:

```bash
moon run examples
```

This will:
1. Parse a sample SQL query
2. Infer fields from SELECT columns
3. Generate MoonBit code including:
   - Struct definition
   - From DbValue mapping function
   - Query execution function

## Sample SQL File

See `examples/sql/users.sql` for a complete example with:
- `getUserById` - Single result query
- `listUsers` - Multiple results query
- `createUser` - Insert with last_insert_id
- `updateUser` - Update with affected_rows
- `deleteUser` - Delete with affected_rows

## Using Orion CLI

```bash
# Show help
moon run cmd/main help

# Generate code from SQL files
moon run cmd/main generate ./examples/sql

# Run migrations (not yet implemented)
moon run cmd/main migrate sqlite://test.db
```

## Generated Code Example

Input SQL:
```sql
-- name: getUserById
-- result: single
SELECT id, name, age FROM users WHERE id = ?;
```

Generated output:
```moonbit
struct User {
  id : Int
  name : String
  age : Int
}

fn user_from_db_value(row : Array[@runtime.DbValue]) -> User {
  {
    id: match row[0] { @runtime.DbValue::Int(v) => v _ => 0 },
    name: match row[1] { @runtime.DbValue::String(v) => v _ => "" },
    age: match row[2] { @runtime.DbValue::Int(v) => v _ => 0 }
  }
}

pub fn get_user_by_id(db : @runtime.Db, param_0 : DbValue) -> Result[Option[User], @runtime.DbError] {
  // ... implementation
}
```
