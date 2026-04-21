# Orion 实现计划

**版本**: v0.3.0
**目标**: 生产就绪 - 动态 SQL、事务、迁移、PostgreSQL
**创建日期**: 2026-04-21
**更新日期**: 2026-04-21

---

## 一、v0.2.0 实现概述

### 1.1 范围

| 功能 | 描述 | 优先级 | 状态 |
|------|------|--------|------|
| Schema DSL | 声明式表定义语法 | P0 | ✅ 完成 |
| Codegen 2.0 | 从 Schema 生成 Struct + CRUD | P0 | ✅ 完成 |
| Query Builder | 链式查询构建器 | P0 | ✅ 完成 |
| derive 支持 | 为生成的 struct 自动添加 derive | P0 | ✅ 完成 |
| CLI 增强 | `orion schema <dir>` 命令 | P0 | ✅ 完成 |

### 1.2 与 v0.1 的关系

| 维度 | v0.1 SQL-first | v0.2 Derive + Codegen |
|------|----------------|-----------------------|
| 定义方式 | SQL 文件 | Schema DSL (MoonBit 代码) |
| 代码生成 | 从 SQL 生成 Mapper | 从 Schema 生成 Struct + CRUD + Query Builder |
| 适用场景 | 复杂查询、SQL 可控 | 快速 CRUD、原型开发 |

### 1.3 MoonBit 语言限制

| 限制 | 影响 | 应对方案 |
|------|------|----------|
| ❌ 不支持用户自定义 derive | 无法 `derive(Entity)` | 外部代码生成器 |
| ❌ 不支持字段级注解 | 无法标注 `@Id`, `@AutoInc` | Schema DSL 中定义 |
| ❌ 不支持运行时反射 | 无法动态读取 schema | 编译时生成代码 |
| ✅ 支持内置 derive | `derive(Eq, Hash, FromJson, ToJson)` | 为生成的 struct 自动添加 |

---

## 二、v0.2.0 任务分解

### 阶段 1: Schema DSL 定义（已完成 ✅）

| 任务 | 文件 | 状态 |
|------|------|------|
| 约束类型定义 | `lib/schema/constraints.mbt` | ✅ 完成 |
| Schema 核心 | `lib/schema/schema.mbt` | ✅ 完成 |
| 类型映射 | `lib/schema/type_mapping.mbt` | ✅ 完成 |

### 阶段 2: Codegen 2.0（已完成 ✅）

| 任务 | 文件 | 状态 |
|------|------|------|
| Struct 代码生成 | `lib/codegen/gen_schema.mbt` | ✅ 完成 |
| CRUD 代码生成 | `lib/codegen/gen_crud.mbt` | ✅ 完成 |
| Query Builder 生成 | `lib/codegen/gen_query_builder.mbt` | ✅ 完成 |

### 阶段 3: CLI 增强（已完成 ✅）

| 任务 | 文件 | 状态 |
|------|------|------|
| Schema 命令 | `lib/cli/cli.mbt` | ✅ 完成 |

### 阶段 4: 集成与测试（已完成 ✅）

| 任务 | 描述 | 状态 |
|------|------|------|
| E2E 测试 | 190 tests passed | ✅ 完成 |

---

## 三、技术架构

### 3.1 核心模块

```
lib/schema/          - Schema DSL 定义
  constraints.mbt   - 约束类型 (PrimaryKey, AutoInc, NotNull, etc.)
  schema.mbt        - TableSchema, FieldDef, TableSchemaBuilder
  type_mapping.mbt  - MoonBit → SQL 类型映射

lib/codegen/        - 代码生成器
  gen_schema.mbt     - 生成 Struct + derive
  gen_crud.mbt       - 生成 CRUD 函数
  gen_query_builder.mbt - 生成 Query Builder

lib/cli/             - CLI 命令
  cli.mbt            - 命令行解析和执行
```

### 3.2 代码生成流程

```
用户定义 Schema (MoonBit 代码)
         │
         ▼
┌─────────────────────┐
│   Schema DSL        │
│   TableSchema       │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│   Codegen 2.0      │
│   gen_full_struct  │
│   gen_full_crud    │
│   gen_full_query_builder │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│   Generated Code    │
│   - Struct         │
│   - CRUD Mapper    │
│   - Query Builder  │
└─────────────────────┘
```

---

## 四、使用示例

### 4.1 定义 Schema

```moonbit
let user_schema = @schema.schema("users")
  |> @schema.add_int_field("id", @schema.pk_auto_inc())
  |> @schema.add_string_field("name", @schema.required())
  |> @schema.add_string_field("email", @schema.unique_required())
  |> @schema.add_int_field("age", [])
  |> @schema.add_bool_field("active", @schema.with_default("true"))
  |> @schema.build_schema()
```

### 4.2 生成代码

```moonbit
// 生成完整代码
let full_code =
  @codegen.gen_full_struct(user_schema) +
  @codegen.gen_full_crud(user_schema) +
  @codegen.gen_full_query_builder(user_schema)
```

### 4.3 使用生成的代码

```moonbit
// CRUD 操作
let mapper = new_users_mapper(db)
let id = create_users(mapper, "Alice", "alice@example.com", 30, true)
let user = find_users_by_id(mapper, id)

// Query Builder
let users = new_users_query(db)
  |> .where_active(true)
  |> .order_by_name(false)
  |> .limit(10)
  |> .execute()
```

---

## 五、测试覆盖

| 模块 | 测试数 | 状态 |
|------|--------|------|
| codegen | 190 | ✅ 全部通过 |
| schema | - | ✅ 集成测试通过 |
| parser | - | ✅ 原有测试通过 |
| runtime | - | ✅ 原有测试通过 |

---

## 六、下一步计划

### v0.3.0

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 事务支持 | `Orion.transaction(fn(tx) {...})` | P0 |
| Migration CLI | `orion migrate up/down/create` | P0 |
| PostgreSQL 驱动完善 | 完整 PG 驱动支持 | P0 |
| 高级查询构建器 | 链式查询增强 | P1 |
| 连接池增强 | 配置化 poolSize、timeout | P1 |

### v0.4.0

| 功能 | 描述 | 优先级 |
|------|------|--------|
| MySQL 驱动 | MySQL 数据库支持 | P2 |
| 批量操作 | 批量 insert/update | P1 |
| 关系定义 | hasOne, hasMany | P2 |

---

**最后更新**: 2026-04-21

---

## 七、v0.3.0 任务详情

### 动态 SQL 支持

| 任务 | 描述 |
|------|------|
| 语法设计 | `[@if condition]...[@endif]`, `[@for item in list]...[@endfor]` |
| Parser 实现 | 解析动态 SQL 标签 |
| Codegen 实现 | 为动态 SQL 生成条件代码 |
| 测试覆盖 | 单元测试 + 集成测试 |

### 事务支持

| 任务 | 描述 |
|------|------|
| API 设计 | `Orion.transaction(db, fn(tx) {...})` |
| TxContext | 事务上下文传递 |
| 连接管理 | 事务内连接复用 |
| 错误处理 | 自动回滚 |

### Migration CLI

| 任务 | 描述 |
|------|------|
| `migrate create` | 创建迁移文件 |
| `migrate up` | 应用迁移 |
| `migrate down` | 回滚迁移 |
| `migrate dev` | 开发环境快速迁移 |

### PostgreSQL 驱动

| 任务 | 描述 |
|------|------|
| 连接管理 | libpq 连接池 |
| 类型映射 | PostgreSQL 类型 → MoonBit 类型 |
| SQL 生成 | PostgreSQL dialect DDL |
| 查询执行 | 参数化查询支持 |
