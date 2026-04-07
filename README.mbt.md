# Orion

**SQL-first、类型安全的数据访问层 for MoonBit**

Orion 是一个采用 Mapper 模式的数据库访问层，灵感来自 MyBatis、sqlx 和 Prisma。它通过 SQL 文件生成类型安全的 MoonBit 代码，提供工程化的数据访问解决方案。

```
Orion = SQL-first + 类型安全 + Mapper 模式 + 工程化
```

## 特性

- 📝 **SQL-first** - SQL 是权威来源，代码从 SQL 生成
- 🔒 **类型安全** - 编译时类型检查，运行时类型转换
- 🗺️ **Mapper 模式** - 一个 SQL 语句对应一个函数
- 🛠️ **CLI 工具链** - 代码生成、迁移管理、开发体验优化
- 🚀 **MoonBit 原生** - 编译为 native，使用 C runtime

## 快速开始

### 安装

```bash
moon add wflixu/Orion
```

### 创建 SQL 文件

在项目目录创建 `queries/user.sql`：

```sql
-- name: getUserById
-- description: Get user by ID
-- result: single
SELECT id, name, age FROM users WHERE id = ?;

-- name: createUser
-- description: Create a new user
-- result: last_insert_id
INSERT INTO users (name, age) VALUES (?, ?);

-- name: listUsers
-- description: List all users
-- result: many
SELECT id, name, age FROM users ORDER BY id;
```

### 生成代码

```bash
orion gen --input queries --output generated
```

生成的代码：

```moonbit
// generated/user.mbt

struct User {
  id: Int
  name: String
  age: Int
}

struct UserMapper {
  db: Orion.Db
}

fn get_user_by_id(self: UserMapper, id: Int) -> Result[Option[User], DbError]
fn create_user(self: UserMapper, name: String, age: Int) -> Result[Int, DbError]
fn list_users(self: UserMapper) -> Result[List[User], DbError]
```

### 使用示例

```moonbit
import wflixu/Orion

fn main {
  // 连接数据库
  let db = Orion.connect({
    url: "sqlite://app.db",
    pool_size: 10
  })
  
  // 创建 Mapper
  let user_mapper = UserMapper::new(db)
  
  // 查询用户
  match user_mapper.get_user_by_id(1) {
    Some(user) => println("User: \(user.name)")
    None => println("User not found")
  }
  
  // 创建用户
  let user_id = user_mapper.create_user("Alice", 25)?
  
  // 启用日志
  Orion.enable_log(db, Debug)
}
```

## 项目结构

```
my-project/
├── queries/           # SQL 文件目录
│   ├── user.sql
│   └── order.sql
├── generated/         # 生成的代码
│   ├── user.mbt
│   └── order.mbt
├── main.mbt           # 你的代码
└── moon.mod.json
```

## CLI 命令

### 代码生成

```bash
# 生成代码
orion gen

# 指定输入输出目录
orion gen --input ./queries --output ./generated

# 监听模式（文件变化自动重新生成）
orion gen --watch
```

### 数据库迁移（v0.2.0+）

```bash
# 创建新迁移
orion migrate create add_users_table

# 应用迁移
orion migrate up

# 回滚迁移
orion migrate down

# 查看迁移状态
orion migrate status
```

## SQL 语法

### 基本语法

```sql
-- name: 函数名（必填）
-- description: 描述（可选）
-- result: single | many | last_insert_id | affected_rows
YOUR_SQL_HERE;
```

### 参数

支持两种参数风格：

```sql
-- SQLite / MySQL 风格 (?)
SELECT * FROM users WHERE id = ?;

-- PostgreSQL 风格 ($1, $2...)
SELECT * FROM users WHERE id = $1 AND name = $2;
```

### 动态 SQL（v0.3.0+）

```sql
-- name: findUsers
-- description: Find users with optional filters
SELECT * FROM users
WHERE 1=1
[@if name]
AND name = ?
[@endif]
[@if min_age]
AND age >= ?
[@endif]
;
```

## 运行时 API

### 连接管理

```moonbit
// 基本连接
let db = Orion.connect({
  url: "sqlite://app.db"
})

// 连接池配置
let db = Orion.connect({
  url: "sqlite://app.db",
  pool_size: 10,
  query_timeout: 5000  // 毫秒
})

// 启用日志
Orion.enable_log(db, level: Debug)

// 关闭连接
Orion.close(db)
```

### 事务（v0.2.0+）

```moonbit
Orion.transaction(db, fn(tx) {
  let user_id = UserMapper.create(tx, "Alice", 25)?
  OrderMapper.create(tx, user_id, 100)?
  Ok(unit)
})
```

### 错误处理

```moonbit
enum DbError {
  NotFound           // 未找到记录
  UniqueViolation    // 唯一约束违反
  ConnectionError    // 连接错误
  QueryError         // 查询错误
  Timeout            // 超时
}
```

## 数据库支持

| 数据库 | 状态 | 版本 |
|--------|------|------|
| SQLite | ✅ 已支持 | v0.1.0 |
| PostgreSQL | 🔄 开发中 | v0.2.0 |
| MySQL | 📅 计划中 | v0.3.0 |

## 版本规划

- **v0.1.x** - MVP（SQL Parser + Codegen + SQLite + Runtime）
- **v0.2.x** - 生产就绪（事务 + Migration + PostgreSQL）
- **v0.3.x** - 高级特性（动态 SQL + MySQL）
- **v0.4.x** - 未来规划（反向生成 + 多数据源）

详见 [specs/prd.md](specs/prd.md) 和 [specs/design.md](specs/design.md)。

## 架构

```
┌─────────────────────┐
│    Orion CLI        │
│  (generate/migrate) │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   SQL / Mapper      │
│   (*.sql files)     │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   Code Generator    │
│  (types + functions)│
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   Orion Runtime     │
│   (pool/tx/log)     │
└──────────┬──────────┘
           │
     ┌─────▼─────┐
     │ Database  │
     └───────────┘
```

## 开发

```bash
# 克隆项目
git clone https://github.com/wflixu/Orion.git
cd Orion

# 格式化代码
moon fmt

# 运行检查
moon check

# 运行测试
moon test

# 更新快照
moon test --update

# 更新包接口并格式化
moon info && moon fmt

# 覆盖率分析
moon coverage analyze > uncovered.log
```

### Git Hooks

```bash
# 配置 pre-commit hook
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
```

## 对比

| 特性 | Orion | MyBatis | Prisma | Drizzle |
|------|-------|---------|--------|---------|
| SQL-first | ✅ | ✅ | ❌ | ✅ |
| 类型安全 | ✅ | ⚠️ | ✅ | ✅ |
| 代码生成 | ✅ | ⚠️ | ✅ | ❌ |
| CLI 工具链 | ✅ | ❌ | ✅ | ⚠️ |
| 无 DSL | ✅ | ✅ | ❌ | ✅ |
| MoonBit 原生 | ✅ | ❌ | ❌ | ❌ |

## 许可证

Apache-2.0

## 相关链接

- [PRD 文档](specs/prd.md)
- [架构设计](specs/design.md)
- [MoonBit 官方文档](https://docs.moonbitlang.com/)
- [mooncakes.io](https://mooncakes.io/)

## 致谢

感谢以下社区项目：

- [moonbit-community/sqlparser](https://mooncakes.io/docs/moonbit-community/sqlparser)
- [myfreess/sqlite3](https://mooncakes.io/docs/myfreess/sqlite3)
- [mattn/postgres](https://mooncakes.io/docs/mattn/postgres)
