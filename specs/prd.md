# Orion PRD - SQL-first 类型安全数据访问层

## 一、项目定位

**Orion = SQL-first + 类型安全 + Mapper 模式 + 工程化数据访问层**

对标产品：
- **MyBatis**（Mapper 模式）
- **Drizzle ORM**（类型安全）
- **Prisma**（工程化体验）
- **SeaORM**（Rust derive 模式）

---

## 一、项目定位（增强版 v0.2.0）

**Orion v0.2.0 = Derive + Codegen ORM**

在 v0.1 SQL-first 基础上，增加声明式 schema 定义，通过外部代码生成实现类型安全的 CRUD 操作。

### 1.1 核心变更

| 维度 | v0.1 SQL-first | v0.2 Derive + Codegen |
|------|----------------|-----------------------|
| 定义方式 | SQL 文件 | Schema DSL + derive |
| 代码生成 | 从 SQL 生成 Mapper | 从 Schema 生成 Struct + CRUD |
| 适用场景 | 复杂查询、SQL 可控 | 快速 CRUD、原型开发 |
| 类型安全 | 编译时验证 | 编译时验证 |
| 学习曲线 | 需要 SQL 知识 | MoonBit 原生语法 |

### 1.2 MoonBit 语言限制与应对

| 限制 | 影响 | 应对方案 |
|------|------|----------|
| ❌ 不支持用户自定义 derive | 无法 `derive(Entity)` | 外部代码生成器 |
| ❌ 不支持字段级注解 | 无法标注 `@Id`, `@AutoInc` | Schema DSL 中定义 |
| ❌ 不支持运行时反射 | 无法动态读取 schema | 编译时生成代码 |
| ✅ 支持内置 derive | `derive(Eq, Hash, FromJson, ToJson)` | 为生成的 struct 自动添加 |

### 1.3 技术选型

**方案：Derive + 外部代码生成**

```moonbit
// 1. 用户定义 schema
let user_schema = schema("user")
  |> field("id", Int, [PrimaryKey, AutoInc])
  |> field("name", String, [NotNull, MaxLength(100)])

// 2. 运行代码生成器
// orion gen schema/user.schema

// 3. 生成的代码
pub struct User {
  id: Int,
  name: String
} derive(Eq, Hash, FromJson, ToJson, Show)

// 生成的 CRUD 函数
pub fn create_user(db: Db, name: String) -> Result[Int, DbError]
pub fn find_user_by_id(db: Db, id: Int) -> Result[Option[User], DbError]
```

---

## 二、三大 ORM 对比分析

### 2.1 Prisma ORM

**核心特点：**
- **Schema DSL**：使用 `schema.prisma` 定义数据模型
- **Code Generation**：基于 schema 生成类型安全的客户端代码
- **Type Safety**：TypeScript 类型从 schema 自动推导
- **Prisma 7.0 (2025)**：Rust-free 架构，3x 性能提升

**优势：**
- 开发者体验优秀，自动补全
- 类型安全无需手动定义
- 完整的迁移工具链

**劣势：**
- 需要学习 DSL
- 抽象层较厚，复杂 SQL 需要 raw query
- 代码生成步骤增加构建时间

**参考链接：**
- [Prisma 7 架构](https://www.infoq.com/news/2026/01/prisma-7-performance/)
- [Prisma Roadmap 2025](https://github.com/prisma/prisma/issues/27503)

---

### 2.2 Drizzle ORM

**核心特点：**
- **SQL-first**：使用 TypeScript 对象定义 schema
- **Type Inference**：类型即时推导，无需代码生成步骤
- **Zero Runtime Overhead**：编译时类型检查
- **多数据库支持**：PostgreSQL, MySQL, SQLite, Turso

**优势：**
- 更接近原生 SQL
- 类型推导快速，无需生成步骤
- 轻量级，学习曲线低

**劣势：**
- 复杂查询类型推导可能变复杂
- 迁移工具相对年轻

**参考链接：**
- [Drizzle ORM v1.0](https://orm.drizzle.team/docs/latest-releases/drizzle-orm-v1beta2)
- [Drizzle Guide 2025](https://dev.to/sameer_saleem/the-ultimate-guide-to-drizzle-orm-postgresql-2025-edition-22b)

---

### 2.3 MyBatis

**核心特点：**
- **Mapper XML**：SQL 与代码分离
- **动态 SQL**：`<if>`, `<choose>`, `<foreach>` 等标签
- **Result Mapping**：灵活的 ORM 映射

**优势：**
- SQL 完全可控，适合复杂查询
- 动态 SQL 强大
- 成熟稳定，生态完善

**劣势：**
- XML 配置繁琐
- 类型安全依赖额外配置
- 缺乏现代化工程工具

**参考链接：**
- [MyBatis Dynamic SQL](https://mybatis.org/mybatis-3/dynamic-sql.html)
- [MyBatis XML Mapping](https://mybatis.org/mybatis-3/sqlmap-xml.html)

---

## 三、MoonBit 语言特点分析

基于 MoonBit 官方更新 (v0.8.0, 2026 年 3 月)：

### 3.1 类型系统

```moonbit
// 泛型支持
fn[X] Array::filter(self : Array[X], f : (T) -> Bool) : Array[X]

// Struct 类型参数
struct Container[T] {
  value: T
}

// Trait / Type Bounds
trait Comparable[T] {
  compare : (T, T) -> Int
}
```

**关键特性：**
- 强静态类型系统
- 泛型支持（类似 Rust）
- Trait 系统用于类型约束
- 枚举类型（enum）

### 3.2 代码生成能力

```moonbit
// declare 关键字 - AI 原生的规范驱动开发
declare fn getUserById(id: Int) -> Result<User>

// 元编程属性
#alias("oldName")
#deprecated("use newName instead")
#warnings

// 模块互操作
#module("...") extern "js"
```

**关键特性：**
- `declare` 关键字用于声明式开发
- 属性系统支持代码转换
- 跨模块别名统一
- 后端支持：wasm-gc / native / LLVM / JS

### 3.3 构建系统

```bash
moon pkg DSL  # 替代 JSON 配置
moon work init  # 工作空间支持
moon test -j  # 并行测试
```

---

## 四、Orion 架构设计

### 4.1 整体架构

```
        ┌────────────────────┐
        │     Orion CLI      │
        │ (generate/migrate) │
        └────────┬───────────┘
                 │
        ┌────────▼───────────┐
        │   SQL / Mapper     │
        │    (*.sql files)   │
        └────────┬───────────┘
                 │
        ┌────────▼───────────┐
        │   Code Generator   │
        │ (types + functions)│
        └────────┬───────────┘
                 │
        ┌────────▼───────────┐
        │   Orion Runtime    │
        │  (pool/tx/log)     │
        └────────┬───────────┘
                 │
           ┌─────▼─────┐
           │ Database  │
           └───────────┘
```

### 4.2 核心设计决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| **MVP 范围** | 最小版本（2 周） | 快速验证核心假设 |
| **SQL 参数风格** | 两者都支持 (`?` 和 `$1`) | 兼容多数据库 |
| **动态 SQL** | 自定义语法 | 更适合 MoonBit，避免 XML 繁琐 |
| **代码生成** | Mapper 模式 | 平衡简洁性和组织性 |
| **数据库支持** | 同时支持 SQLite/Postgres/MySQL | 用户需求驱动 |
| **DSL (v0.2.0)** | ✅ Schema DSL | MoonBit 原生语法，无需学习新 DSL |
| **Query Builder** | ❌ 初期不做 | 聚焦核心 |

---

## 五、详细设计

### 5.1 SQL 文件规范

```sql
-- name: getUserById
-- description: Get user by ID
-- result: single
SELECT id, name, age FROM users WHERE id = ?;

-- name: createUser
-- description: Create a new user
-- result: last_insert_id
INSERT INTO users (name, age) VALUES (?, ?);

-- name: findUsers (动态 SQL 示例)
-- description: Find users with optional filters
SELECT * FROM users
WHERE 1=1
[@if name]
AND name = ?
[@endif]
[@if minAge]
AND age >= ?
[@endif]
;
```

**语法说明：**
- `-- name:` 必填，函数名
- `-- description:` 可选，描述
- `-- result:` 返回类型（`single`/`many`/`last_insert_id`/`affected_rows`）
- `[@if xxx]...[@endif]` 动态 SQL 块
- 参数使用 `?` 或 `$1` 风格

### 5.2 代码生成输出

**生成的 MoonBit 代码：**

```moonbit
// 自动生成的 struct（可选）
struct User {
  id: Int
  name: String
  age: Int
}

// Mapper 模块
struct UserMapper {
  db: Orion.Db
}

// 生成的函数
fn getUserById(self : UserMapper, id: Int) -> Result[Option[User]]

fn createUser(self: UserMapper, name: String, age: Int) -> Result[Int]

fn findUsers(self: UserMapper, name: Option[String], minAge: Option[Int]) -> Result[List[User]]
```

### 5.3 动态 SQL 实现

**自定义语法设计：**

```
[@if condition]
SQL fragment
[@endif]

[@if condition]
SQL fragment
[@else]
alternative fragment
[@endif]

[@for item in list]
SQL fragment with @item
[@endfor]
```

**优势：**
- 简洁，类似注释
- 不依赖 XML
- 易于 parser 实现
- 与 SQL 注释风格一致

### 5.4 运行时设计

```moonbit
// 连接池
let db = Orion.connect({
  url: "sqlite://app.db",
  poolSize: 10
})

// 事务
Orion.transaction(db, fn(tx) {
  UserMapper.create(tx, "A", 18)
  UserMapper.create(tx, "B", 20)
})

// 日志
Orion.enableLog(db, level: Debug)

// 错误处理
enum DbError {
  NotFound
  UniqueViolation(String)
  ConnectionError(String)
  QueryError(String)
}
```

---

## 六、版本规划

采用语义化版本，基于 0.1.x 迭代，MVP 完成后升级 0.2.x

### v0.1.0 - MVP (2 周) ✅

| 功能 | 描述 | 状态 |
|------|------|------|
| SQL Parser | 解析 `.sql` 文件，提取 `-- name:` 和参数 | ✅ |
| Codegen | 生成函数签名 + struct | ✅ |
| SQLite Driver | 基础查询执行 | ✅ |
| Runtime | `query()` / `execute()` 基础 API | ✅ |

### v0.1.1 - v0.1.x 迭代 ✅

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 连接池 | 基础连接管理 | ✅ P0 |
| 错误处理 | `DbError` 枚举 + 错误转换 | ✅ P0 |
| 日志系统 | Debug 日志输出 | ✅ P1 |
| 参数风格 | 支持 `?` 和 `$1` 两种风格 | ✅ P1 |

### v0.2.0 - Derive + Codegen ORM ✅

在 v0.1.x 基础上添加：

| 功能 | 描述 | 优先级 | 状态 |
|------|------|--------|------|
| Schema DSL | 声明式表定义语法 | P0 | ✅ 完成 |
| Codegen 2.0 | 从 Schema 生成 Struct + CRUD | P0 | ✅ 完成 |
| Query Builder | 链式查询构建器 | P0 | ✅ 完成 |
| derive 支持 | 为生成的 struct 自动添加 derive | P0 | ✅ 完成 |
| CLI 增强 | `orion schema <dir>` 命令 | P0 | ✅ 完成 |

### v0.3.0 - 生产就绪

| 功能 | 描述 |
|------|------|
| 事务支持 | `Orion.transaction(fn(tx) {...})` |
| Migration CLI | `orion migrate up/down/create` |
| PostgreSQL 支持 | 完整的 PG 驱动 |
| 连接池增强 | 配置化 poolSize、timeout |

### v0.4.0 - 高级特性

| 功能 | 描述 |
|------|------|
| 动态 SQL | `[@if]...[@endif]` 语法支持 |
| MySQL 支持 | MySQL 驱动 |
| 批量操作 | 批量 insert/update |
| 关系定义 | hasOne, hasMany |

### v0.5.0+ - 未来规划

| 功能 | 描述 |
|------|------|
| `orion pull` | 从数据库反向生成 schema |
| 只读查询优化 | 读写分离支持 |
| 多数据源 | 多数据库连接 |

---

## 七、CLI 设计

```bash
# 代码生成（核心）
orion gen           # 从 *.sql 生成 MoonBit 代码
orion gen --watch   # 监听模式

# 数据库迁移（v0.2.0+）
orion migrate dev           # 开发环境迁移
orion migrate up            # 应用迁移
orion migrate down          # 回滚迁移
orion migrate create name   # 创建新迁移

# 数据库 introspection（v0.4.0+）
orion pull                  # 从数据库生成 schema
orion introspect            # 查看数据库结构
```

---

## 八、MVP 范围（v0.1.0 - 2 周）

### 必须实现

| 功能 | 描述 |
|------|------|
| **SQL Parser** | 解析 `.sql` 文件，提取 `-- name:` 和参数 |
| **Codegen** | 生成函数签名 + struct（可选） |
| **SQLite Driver** | 基础查询执行（复用 myfreess/sqlite3） |
| **Runtime** | `query()` / `execute()` 基础 API |

---

## 九、差异化优势

| 对比 | Orion 优势 |
|------|-----------|
| **vs MyBatis** | 类型安全 + Codegen + 现代 CLI |
| **vs Prisma** | 无 DSL + SQL 可控 + 轻量级 |
| **vs Drizzle** | Mapper 模式 + CLI 工具链 + MoonBit 原生 |

---

## 十、技术栈

### 10.1 全 MoonBit 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| **CLI / Codegen** | MoonBit | 编译为 native，使用 C runtime |
| **SQL Parser** | 复用 [moonbit-community/sqlparser](https://mooncakes.io/docs/moonbit-community/sqlparser) | 已有成熟的 SQL parser 包 |
| **Runtime** | MoonBit | 连接池/事务/日志 |
| **Database Driver** | 复用现有包 + 封装 | myfreess/sqlite3, mattn/postgres |

### 10.2 现有生态包调研

#### SQL Parser
- **moonbit-community/sqlparser** - 通用 SQL 解析器
- **Milky2018/sqlparser** - 可扩展 SQL Lexer 和 Parser
  - 包含 `ast.mbt`, `lexer.mbt`, `parser.mbt`, `tokens.mbt`
  - 支持 PostgreSQL, Snowflake 等 dialect
  - GitHub: https://github.com/Milky2018/sqlparser-mbt

#### 数据库驱动
- **myfreess/sqlite3** (v0.1.5) - SQLite3 C FFI binding
  - 轻量级 SQLite3 绑定
  - GitHub: https://github.com/myfreess/sqlite3.mbt
  - 使用 `@ffi.Sqlite3` 实现 native C FFI

- **mizchi/sqlite** (v0.2.3) - SQLite 驱动
  - 支持 native (C FFI) 和 JavaScript (Node.js) 目标

- **mattn/postgres** - PostgreSQL 客户端
  - 使用 libpq C API
  - 支持连接管理、简单查询和参数化查询

#### 代码生成相关
- **mizchi/sqlc_gen_moonbit** - SQLC MoonBit 代码生成器
  - 支持 postgres, mysql_js, d1 等后端
  - 可参考其代码生成策略

### 10.3 为什么复用现有包？

**优势：**
- ✅ 避免重复造轮子，专注核心差异化
- ✅ 社区包已验证可用性
- ✅ 降低 MVP 开发时间（从 2 周缩短到 1 周）
- ✅ 社区包维护者可能是潜在合作者

**Orion 核心价值：**
- SQL 文件规范和代码生成
- Mapper 模式封装
- CLI 工具链
- 工程化体验

### 10.4 数据库驱动实现策略

Orion 不直接调用 C API，而是封装现有驱动：

```moonbit
// 基于 myfreess/sqlite3 或 mizchi/sqlite 封装
struct SQLiteDriver {
  conn: Sqlite3.Connection
}

impl Driver for SQLiteDriver {
  fn query(sql: String, params: List[Value]) -> Result[ResultSet]
  fn execute(sql: String, params: List[Value]) -> Result[Int]
}
```

PostgreSQL 和 MySQL 同理，通过统一接口封装。

---

## 十一、待决策问题

1. **struct 生成策略**：自动生成还是用户定义？
   - 推荐：用户定义优先，自动生成作为可选功能

2. **参数风格统一**：parser 层统一还是运行时转换？
   - 推荐：parser 层统一为内部 AST，运行时按目标数据库转换

3. **动态 SQL parser**：正则还是 AST？
   - 推荐：轻量级 AST，正则解析 `[@if]` 标签

4. **SQL parser 复杂度**：完整 SQL parser 还是只解析参数？
   - 推荐：MVP 只解析 `-- name:` 和参数占位符，不解析完整 SQL

---

## 附录：参考链接

- [Prisma ORM](https://www.prisma.io/)
- [Drizzle ORM](https://orm.drizzle.team/)
- [MyBatis](https://mybatis.org/)
- [MoonBit 官方](https://www.moonbitlang.com/)
- [MoonBit Updates](https://www.moonbitlang.com/updates/)
- [moonbit-community/sqlparser](https://mooncakes.io/docs/moonbit-community/sqlparser)
- [Milky2018/sqlparser-mbt](https://github.com/Milky2018/sqlparser-mbt)
- [myfreess/sqlite3](https://mooncakes.io/docs/myfreess/sqlite3)
- [mattn/postgres](https://mooncakes.io/docs/mattn/postgres)
- [mizchi/sqlc_gen_moonbit](https://mooncakes.io/docs/mizchi/sqlc_gen_moonbit)
