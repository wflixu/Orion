# Orion PRD - Derive + Codegen ORM for MoonBit

## 一、项目定位

**Orion = Derive + Codegen ORM + 类型安全 + 工程化数据访问层**

对标产品：
- **Prisma**（工程化体验 + Schema DSL）
- **Drizzle ORM**（类型安全）
- **SeaORM**（Rust derive 模式）
- **MyBatis**（Mapper 模式）

### 1.1 核心设计

| 维度 | 说明 |
|------|------|
| 定义方式 | Schema DSL (MoonBit 代码) |
| 代码生成 | 从 Schema 生成 Struct + CRUD + Query Builder |
| 类型安全 | 编译时验证 + derive(Eq, Hash, FromJson, ToJson, Show) |
| 适用场景 | 快速 CRUD、原型开发 |

### 1.2 MoonBit 语言限制与应对

| 限制 | 影响 | 应对方案 |
|------|------|----------|
| ❌ 不支持用户自定义 derive | 无法 `derive(Entity)` | 外部代码生成器 |
| ❌ 不支持字段级注解 | 无法标注 `@Id`, `@AutoInc` | Schema DSL 中定义 |
| ❌ 不支持运行时反射 | 无法动态读取 schema | 编译时生成代码 |
| ✅ 支持内置 derive | `derive(Eq, Hash, FromJson, ToJson)` | 为生成的 struct 自动添加 |

### 1.3 使用示例

```moonbit
// 1. 用户定义 schema
let user_schema = @schema.schema("users")
  |> @schema.add_int_field("id", @schema.pk_auto_inc())
  |> @schema.add_string_field("name", @schema.required())
  |> @schema.add_string_field("email", @schema.unique_required())
  |> @schema.build_schema()

// 2. 生成代码
let struct_code = @codegen.gen_full_struct(user_schema)
let crud_code = @codegen.gen_full_crud(user_schema)
let query_code = @codegen.gen_full_query_builder(user_schema)

// 3. 生成的代码
// pub struct User { id: Int, name: String, email: String }
// pub struct UsersMapper { db: @runtime.Db }
// pub fn create_user(mapper: UsersMapper, name: String, email: String) -> Result[Int, DbError]
// pub fn find_user_by_id(mapper: UsersMapper, id: Int) -> Result[Option[User], DbError]
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
        │ (schema/migrate)   │
        └────────┬───────────┘
                 │
        ┌────────▼───────────┐
        │   Schema DSL       │
        │   (*.mbt files)    │
        └────────┬───────────┘
                 │
        ┌────────▼───────────┐
        │   Codegen 2.0     │
        │ (Struct+CRUD+QB)  │
        └────────┬───────────┘
                 │
        ┌────────▼───────────┐
        │   Orion Runtime   │
        │  (pool/tx/log)    │
        └────────┬───────────┘
                 │
           ┌─────▼─────┐
           │ Database  │
           └───────────┘
```

### 4.2 核心设计决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| **Schema 定义** | MoonBit 代码 (Schema DSL) | 原生语法，无需学习新 DSL |
| **代码生成** | Schema → Struct + CRUD + Query Builder | 编译时生成类型安全代码 |
| **derive 支持** | 内置 derive (Eq, Hash, FromJson, ToJson, Show) | MoonBit 原生支持 |
| **数据库支持** | SQLite (v0.2) / PostgreSQL (v0.2.1) / MySQL (v0.2.2) | 用户需求驱动 |
| **参数风格** | `?` 风格 (SQLite) | 简化实现 |

---

## 五、详细设计

### 5.1 Schema DSL 语法

```moonbit
let user_schema = @schema.schema("users")
  |> @schema.add_int_field("id", @schema.pk_auto_inc())
  |> @schema.add_string_field("name", @schema.required())
  |> @schema.add_string_field("email", @schema.unique_required())
  |> @schema.add_int_field("age", [])
  |> @schema.add_bool_field("active", @schema.with_default("true"))
  |> @schema.add_normal_index("idx_name", ["name"])
  |> @schema.add_unique_index("uniq_email", ["email"])
  |> @schema.build_schema()
```

### 5.2 约束类型

| 约束 | 说明 | 示例 |
|------|------|------|
| `pk_auto_inc()` | 主键 + 自增 | id |
| `required()` | 非空 | name |
| `unique_required()` | 唯一 + 非空 | email |
| `unique()` | 唯一 | code |
| `not_null()` | 非空 | description |
| `with_default(val)` | 默认值 | active |
| `max_length(n)` | 最大长度 | name |
| `normal_index(name, cols)` | 普通索引 | - |
| `unique_index(name, cols)` | 唯一索引 | - |

### 5.3 代码生成输出

**生成的 Struct + CRUD:**

```moonbit
pub struct User {
  id: Int
  name: String
  email: String
  age: Int
  active: Bool
} derive(Eq, Hash, FromJson, ToJson, Show)

pub struct UsersMapper {
  db: @runtime.Db
}

pub fn create_user(self: UsersMapper, name: String, email: String, age: Int, active: Bool) -> Result[Int, @runtime.DbError]
pub fn find_user_by_id(self: UsersMapper, id: Int) -> Result[Option[User], @runtime.DbError]
pub fn find_all_users(self: UsersMapper) -> Result[List[User], @runtime.DbError]
pub fn update_user(self: UsersMapper, id: Int, name: String, email: String, age: Int, active: Bool) -> Result[Int, @runtime.DbError]
pub fn delete_user_by_id(self: UsersMapper, id: Int) -> Result[Int, @runtime.DbError]
```

**生成的 Query Builder:**

```moonbit
pub struct UsersQuery {
  db: @runtime.Db
  where_clauses: Array[String]
  params: Array[@runtime.DbValue]
  order_by: Option[String]
  limit: Option[Int]
  offset: Option[Int]
}

pub fn UsersQuery::where_name(self, value: String) -> Self
pub fn UsersQuery::where_name_contains(self, pattern: String) -> Self
pub fn UsersQuery::where_name_starts_with(self, prefix: String) -> Self
pub fn UsersQuery::order_by_id(self, desc: Bool) -> Self
pub fn UsersQuery::limit(self, n: Int) -> Self
pub fn UsersQuery::execute(self) -> Result[List[User], @runtime.DbError]
```

### 5.4 运行时设计

```moonbit
// 连接池
let db = @runtime.connect({
  url: "sqlite://app.db",
  pool_size: 10
})

// 事务 (v0.2.1)
@runtime.transaction(db, fn(tx) {
  create_user(mapper, "A", "a@test.com", 18)
  create_user(mapper, "B", "b@test.com", 20)
})

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

### v0.2.1 - 生产就绪

| 功能 | 描述 |
|------|------|
| 事务支持 | `Orion.transaction(fn(tx) {...})` |
| Migration CLI | `orion migrate up/down/create` |
| PostgreSQL 支持 | 完整的 PG 驱动 |

### v0.2.2 - 增强特性

| 功能 | 描述 |
|------|------|
| 高级查询构建器 | 链式查询增强 |
| 连接池增强 | 配置化 poolSize、timeout |
| MySQL 支持 | MySQL 驱动 |
| 批量操作 | 批量 insert/update |

### v0.2.3+ - 未来规划

| 功能 | 描述 |
|------|------|
| 关系定义 | hasOne, hasMany |
| `orion pull` | 从数据库反向生成 schema |
| 只读查询优化 | 读写分离支持 |
| 多数据源 | 多数据库连接 |

---

## 七、CLI 设计

```bash
# Schema 代码生成（核心）
orion schema <dir>          # 从 schema 目录生成代码

# 数据库迁移（v0.2.1）
orion migrate dev           # 开发环境迁移
orion migrate up            # 应用迁移
orion migrate down          # 回滚迁移
orion migrate create <name> # 创建新迁移

# 数据库 introspection（未来）
orion pull                  # 从数据库生成 schema
```

---

## 八、核心功能（v0.2.0 完成）

| 功能 | 描述 | 文件 |
|------|------|------|
| **Schema DSL** | 声明式表定义 | `lib/schema/` |
| **Codegen 2.0** | 生成 Struct + CRUD + Query Builder | `lib/codegen/` |
| **SQLite Driver** | 基础查询执行 | `lib/runtime/` |
| **Runtime** | `query()` / `execute()` API | `lib/runtime/` |

---

## 九、差异化优势

| 对比 | Orion 优势 |
|------|-----------|
| **vs MyBatis** | 类型安全 + Codegen + 现代 CLI |
| **vs Prisma** | MoonBit 原生语法 + 轻量级 |
| **vs Drizzle** | Schema DSL + Query Builder + MoonBit 原生 |

---

## 十、技术栈

### 10.1 全 MoonBit 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| **CLI / Codegen** | MoonBit | 编译为 native，使用 C runtime |
| **Schema DSL** | MoonBit 代码 | 原生语法定义表结构 |
| **Runtime** | MoonBit | 连接池/事务/日志 |
| **Database Driver** | 复用现有包 + 封装 | myfreess/sqlite3, mattn/postgres |

### 10.2 核心模块

```
lib/schema/               - Schema DSL 定义
  constraints.mbt         - 约束类型
  schema.mbt             - TableSchema, FieldDef, TableSchemaBuilder
  type_mapping.mbt       - MoonBit → SQL 类型映射

lib/codegen/             - 代码生成器
  gen_schema.mbt         - 生成 Struct + derive
  gen_crud.mbt           - 生成 CRUD 函数
  gen_query_builder.mbt  - 生成 Query Builder

lib/runtime/             - 运行时
  db.mbt                 - 数据库连接管理
  pool.mbt               - 连接池
  error.mbt              - 错误处理

lib/cli/                 - CLI 命令
  cli.mbt                - 命令行解析
```

### 10.3 数据库驱动

| 驱动 | 状态 | 说明 |
|------|------|------|
| SQLite | ✅ 完成 | myfreess/sqlite3 |
| PostgreSQL | v0.2.1 | mattn/postgres |
| MySQL | v0.2.2 | 未来支持 |

---

## 附录：参考链接

- [Prisma ORM](https://www.prisma.io/)
- [Drizzle ORM](https://orm.drizzle.team/)
- [MyBatis](https://mybatis.org/)
- [MoonBit 官方](https://www.moonbitlang.com/)
- [MoonBit Updates](https://www.moonbitlang.com/updates/)
- [myfreess/sqlite3](https://mooncakes.io/docs/myfreess/sqlite3)
- [mattn/postgres](https://mooncakes.io/docs/mattn/postgres)
