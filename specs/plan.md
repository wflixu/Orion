# Orion MVP 实现计划

**版本**: v0.1.0  
**目标**: 2 周内完成 MVP  
**创建日期**: 2026-04-07

---

## 一、实现概述

### 1.1 MVP 范围

| 功能 | 描述 | 优先级 |
|------|------|--------|
| SQL Parser | 解析 `.sql` 文件，提取 `-- name:` 和参数 | P0 |
| Codegen | 生成函数签名 + struct（可选） | P0 |
| SQLite Driver | 基础查询执行（复用 myfreess/sqlite3） | P0 |
| Runtime | `query()` / `execute()` 基础 API | P0 |
| CLI | `orion gen` 代码生成命令 | P0 |

### 1.2 不包含在 MVP

| 功能 | 版本 |
|------|------|
| 事务支持 | v0.2.0 |
| Migration CLI | v0.2.0 |
| PostgreSQL 支持 | v0.2.0 |
| 动态 SQL | v0.3.0 |
| 连接池增强（健康检查、超时） | v0.1.1 |

---

## 二、任务分解

### 阶段 1: 基础类型定义（1 天）

#### Task 1.1: `lib/driver/driver_iface.mbt`

**内容**:
- `DbValue` 枚举（参数和结果值类型）
- `Connection` 枚举（多驱动封装）
- `DbError` 枚举（错误类型）
- `ResultSet` / `Row` / `ColumnInfo` 结构
- `DbDriver` trait 接口

**依赖**: 无

**验收标准**:
- [ ] 所有类型定义完成
- [ ] 通过 `moon check`
- [ ] 单元测试通过

**预计工作量**: 1 天

---

### 阶段 2: SQL 解析与类型推导（2-3 天）

#### Task 2.1: `lib/parser/sql_file.mbt`

**内容**:
- 解析 `.sql` 文件格式
- 提取元数据：`name`, `description`, `result_type`
- 识别参数占位符（`?` 和 `$1`）
- 识别动态 SQL 标签（`[@if]` 等）
- 构建 `QueryMeta` 结构

**依赖**: 无

**验收标准**:
- [ ] 能解析基本 SQL 文件
- [ ] 正确提取所有元数据
- [ ] 参数计数正确
- [ ] 单元测试覆盖

**预计工作量**: 1-2 天

#### Task 2.2: `lib/analyzer/type_infer.mbt`

**内容**:
- 从 SQL 推导参数类型
- 从 SELECT 列推导返回类型
- 简单模式匹配（`WHERE id = ?` → `Int`）
- 构建 `ParamInfo` 和 `ColumnInfo`

**依赖**: `lib/parser`

**验收标准**:
- [ ] 能推导简单查询的类型
- [ ] 单元测试覆盖

**预计工作量**: 1 天

---

### 阶段 3: 代码生成（2-3 天）

#### Task 3.1: `lib/codegen/gen_mapper.mbt`

**内容**:
- 从 `QueryMeta` 生成 MoonBit 代码
- 生成 `struct` 定义（可选）
- 生成 `Mapper` 模块
- 生成查询函数
- 代码格式化

**依赖**: `lib/parser`, `lib/analyzer`

**验收标准**:
- [ ] 生成的代码通过 `moon check`
- [ ] 快照测试通过
- [ ] 生成的代码可编译

**预计工作量**: 2-3 天

---

### 阶段 4: 运行时核心（3-4 天）

#### Task 4.1: `lib/runtime/pool.mbt`

**内容**:
- `ConnectionPool` 结构（并发安全）
- `acquire()` / `release()` 实现
- `PooledConnection` RAII 模式
- `with_connection` 包装函数
- Mutex 锁保护（ADR-001）

**依赖**: `lib/driver`

**验收标准**:
- [ ] 并发测试通过
- [ ] 连接正确归还
- [ ] 池耗尽行为正确

**预计工作量**: 2-3 天

#### Task 4.2: `lib/runtime/transaction.mbt`

**内容**:
- `Tx` 结构
- `transaction()` 函数
- `finally` 块确保连接归还（ADR-003）
- `TxContext` enum（Db/Tx 模式）

**依赖**: `lib/runtime/pool`, `lib/driver`

**验收标准**:
- [ ] 事务提交/回滚正确
- [ ] 连接始终归还
- [ ] 单元测试通过

**预计工作量**: 1-2 天

**注**: MVP 阶段事务支持可以简化，完整事务支持放在 v0.2.0

---

### 阶段 5: SQLite 驱动（1-2 天）

#### Task 5.1: `lib/driver/sqlite_adapter.mbt`

**内容**:
- 封装 `myfreess/sqlite3` 包
- 实现 `DbDriver` trait
- `DbValue` ↔ `Sqlite3.Value` 转换
- `ResultSet` 转换

**依赖**: `lib/driver/driver_iface`, `myfreess/sqlite3`

**验收标准**:
- [ ] 能执行基本查询
- [ ] 参数绑定正确
- [ ] 结果转换正确
- [ ] 集成测试通过

**预计工作量**: 1-2 天

---

### 阶段 6: CLI 入口（1 天）

#### Task 6.1: `cmd/orion/main.mbt`

**内容**:
- 命令行参数解析
- `orion gen` 命令实现
- 扫描 `.sql` 文件
- 调用代码生成器
- 错误处理和日志

**依赖**: `lib/parser`, `lib/codegen`

**验收标准**:
- [ ] `orion gen` 能生成代码
- [ ] 错误提示友好
- [ ] 端到端测试通过

**预计工作量**: 1 天

---

## 三、依赖关系图

```
Task 1.1 (driver_iface)
    │
    ├─────────────────────────────────┐
    │                                 │
    ▼                                 ▼
Task 2.1 (sql_file)           Task 4.1 (pool)
    │                                 │
    ▼                                 ▼
Task 2.2 (type_infer)         Task 4.2 (transaction)
    │                                 │
    ▼                                 │
Task 3.1 (gen_mapper)               │
    │                                 │
    └──────────────┬──────────────────┘
                   │
                   ▼
           Task 5.1 (sqlite_adapter)
                   │
                   ▼
           Task 6.1 (main)
```

---

## 四、实现顺序建议

### 顺序 A: 自底向上（推荐）

```
Week 1:
  Day 1-2: Task 1.1 (driver_iface)
  Day 3-4: Task 2.1 (sql_file)
  Day 5:   Task 2.2 (type_infer)

Week 2:
  Day 6-8: Task 3.1 (gen_mapper)
  Day 9:   Task 5.1 (sqlite_adapter)
  Day 10:  Task 6.1 (main) + 端到端测试
```

**优点**:
- 基础稳固，后续开发顺利
- 每阶段都有可交付成果
- 便于测试和调试

### 顺序 B: 快速原型（备选）

```
Week 1:
  Day 1-2: Task 2.1 (sql_file) + Task 3.1 (gen_mapper) 简化版
  Day 3-4: Task 6.1 (main) + 硬编码 SQLite 驱动
  Day 5:   端到端演示（无连接池）

Week 2:
  Day 6-8: Task 4.1 (pool) + Task 4.2 (transaction)
  Day 9-10: Task 5.1 (sqlite_adapter) + 完善
```

**优点**:
- 快速看到成果
- 早期验证核心假设
- 风险：后期返工

---

## 五、每日站会模板

```markdown
## YYYY-MM-DD

### 昨日完成
- [任务]

### 今日计划
- [任务]

### 阻塞问题
- [问题]

### 备注
- [笔记]
```

---

## 六、测试策略

### 6.1 单元测试

| 模块 | 测试文件 | 覆盖率目标 |
|------|----------|------------|
| parser | `sql_file_wbtest.mbt` | 80% |
| analyzer | `type_infer_wbtest.mbt` | 70% |
| codegen | `gen_mapper_wbtest.mbt` | 80%（快照测试） |
| pool | `pool_wbtest.mbt` | 70%（含并发测试） |
| transaction | `transaction_wbtest.mbt` | 70% |
| sqlite_adapter | `sqlite_adapter_wbtest.mbt` | 70% |

### 6.2 集成测试

| 测试 | 描述 |
|------|------|
| `test_gen_and_run` | 生成代码 → 编译 → 执行 → 验证结果 |
| `test_concurrent_query` | 并发查询测试 |
| `test_transaction` | 事务提交/回滚测试 |

### 6.3 端到端测试

```bash
# 创建测试项目
mkdir -p /tmp/orion_test
cd /tmp/orion_test

# 创建 SQL 文件
cat > queries/user.sql << 'EOF'
-- name: getUserById
-- result: single
SELECT id, name FROM users WHERE id = ?
EOF

# 运行代码生成
orion gen --input queries --output generated

# 验证生成的代码
moon check
moon test
```

---

## 七、风险与缓解

### 风险 1: MoonBit Mutex 支持

**风险**: MoonBit 标准库可能不提供 `Mutex`

**缓解**:
1. 调研 `moonbitlang/core` 是否有 Mutex/Channel
2. 如无，使用社区包
3. 再无，简化 MVP 为单线程连接池（v0.1.1 补上）

---

### 风险 2: 社区包兼容性

**风险**: `myfreess/sqlite3` 或 `mattn/postgres` API 不稳定

**缓解**:
1. 锁定版本号（如 `@0.1.5`）
2. 封装适配层，隔离变化
3. 准备 fallback 方案（直接 FFI 调用）

---

### 风险 3: 类型推导复杂度

**风险**: JOIN、聚合函数等复杂查询类型推导困难

**缓解**:
1. MVP 只支持简单查询
2. 复杂查询使用用户注解
3. v0.2.0 引入 schema 感知推导

---

### 风险 4: 代码生成冲突

**风险**: 生成的代码与用户手写代码冲突

**缓解**:
1. 生成到独立目录（`generated/`）
2. 添加 `@generated` 标记
3. 文档说明扩展方式

---

## 八、验收标准（MVP）

### 功能验收

- [ ] 能解析 `.sql` 文件并提取元数据
- [ ] 能生成 MoonBit Mapper 代码
- [ ] 生成的代码能编译通过
- [ ] 能执行 SQLite 查询
- [ ] CLI `orion gen` 命令可用

### 质量验收

- [ ] 所有单元测试通过
- [ ] 集成测试通过
- [ ] 端到端测试通过
- [ ] 无 Critical/Major bug
- [ ] 代码覆盖率达到目标

### 文档验收

- [ ] README.md 包含快速开始
- [ ] 示例项目可用
- [ ] API 文档完整

---

## 九、里程碑

| 里程碑 | 日期 | 交付物 |
|--------|------|--------|
| **M1: 基础完成** | Day 2 | `driver_iface.mbt`, `sql_file.mbt` |
| **M2: Codegen 完成** | Day 5 | `gen_mapper.mbt`, 能生成可编译代码 |
| **M3: Runtime 完成** | Day 8 | `pool.mbt`, `transaction.mbt`, `sqlite_adapter.mbt` |
| **M4: CLI 完成** | Day 10 | `main.mbt`, `orion gen` 可用 |
| **M5: 测试完成** | Day 12 | 所有测试通过 |
| **M6: 发布 v0.1.0** | Day 14 | 文档完善，发布到 mooncakes.io |

---

## 十、发布检查清单

### 代码检查

- [ ] `moon check` 无警告
- [ ] `moon fmt` 格式化
- [ ] `moon test` 全部通过
- [ ] `.mbti` 接口文件正确

### 文档检查

- [ ] README.md 完整
- [ ] specs/prd.md 最新
- [ ] specs/design.md 最新
- [ ] 示例项目可用

### 发布准备

- [ ] 更新 `moon.mod.json` 版本号
- [ ] 更新 CHANGELOG
- [ ] 打 git tag
- [ ] 发布到 mooncakes.io

---

## 附录：任务跟踪表

| 任务 ID | 任务名 | 状态 | 负责人 | 开始日期 | 结束日期 | 备注 |
|---------|--------|------|--------|----------|----------|------|
| #79 | 实现基础类型定义 | pending | - | - | - | - |
| #77 | 实现 SQL 文件解析器 | pending | - | - | - | - |
| #73 | 实现类型推导器 | pending | - | - | - | - |
| #78 | 实现代码生成器 | pending | - | - | - | - |
| #76 | 实现连接池 | pending | - | - | - | - |
| #75 | 实现事务管理 | pending | - | - | - | - |
| #80 | 实现 SQLite 驱动 | pending | - | - | - | - |
| #74 | 实现 CLI 入口 | pending | - | - | - | - |

---

**最后更新**: 2026-04-07
