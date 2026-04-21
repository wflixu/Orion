# Orion Examples

## Schema DSL Demo

本目录展示如何使用 Orion v0.2.0 的 Schema DSL + Codegen 2.0 模式。

### 快速开始

1. 定义 Schema（创建 `schema/user.mbt`）：

```moonbit
import wflixu/Orion.{schema, pk_auto_inc, required, unique_required, with_default}

let user_schema = schema("users")
  |> add_int_field("id", pk_auto_inc())
  |> add_string_field("name", required())
  |> add_string_field("email", unique_required())
  |> add_int_field("age", [])
  |> add_bool_field("active", with_default("true"))
  |> build_schema()
```

2. 生成代码：

```bash
moon run cmd/main schema ./examples/schema
```

3. 使用生成的代码：

```moonbit
// 创建 Mapper
let mapper = new_users_mapper(db)

// 创建用户
let id = create_users(mapper, "Alice", "alice@example.com", 30, true)

// 查询用户
let user = find_users_by_id(mapper, id)

// 使用 Query Builder
let users = new_users_query(db)
  |> .where_name("Alice")
  |> .order_by_id(false)
  |> .limit(10)
  |> .execute()
```

### 生成的文件

```
schema/
  user.mbt              # Schema 定义

generated/
  users.mbt             # 生成的 Struct + CRUD
  users_mapper.mbt      # 生成的 Mapper
  users_query.mbt       # 生成的 Query Builder
```

### 运行示例

```bash
# 生成代码
moon run cmd/main schema ./examples/schema

# 运行测试
moon test
```

### CLI 帮助

```bash
# 显示帮助
moon run cmd/main help

# Schema 代码生成
moon run cmd/main schema <dir> [--output <output_dir>]

# 数据库迁移（v0.2.1）
moon run cmd/main migrate dev
moon run cmd/main migrate up
moon run cmd/main migrate down
```
