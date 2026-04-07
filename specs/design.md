# Orion 系统与架构设计

## 1. 系统概述

Orion 是一个 SQL-first、类型安全的数据访问层，采用 Mapper 模式，为 MoonBit 语言提供工程化的数据库访问解决方案。

### 1.1 设计目标

- **SQL-first**: SQL 是权威来源，代码从 SQL 生成
- **类型安全**: 编译时类型检查，运行时类型转换
- **Mapper 模式**: 一个 SQL 语句对应一个函数
- **工程化**: CLI 工具链支持开发、构建、迁移全流程

### 1.2 约束条件

- 全 MoonBit 技术栈（CLI、Runtime、Driver 封装）
- 复用现有社区包（sqlparser、sqlite3、postgres）
- 支持 native 编译（C runtime）
- MVP 范围最小化（2 周内完成）

---

## 2. 系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      Developer Experience                      │
├─────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │  *.sql files │    │  User Code   │    │  Generated   │    │
│  │  (SQL Mappers)│    │  (business)  │    │  Code        │    │
│  └──────┬───────┘    └──────┬───────┘    └──────▲───────┘    │
│         │                   │                    │            │
│         │  ┌────────────────┼────────────────┐  │            │
│         │  │     Orion CLI (orion gen)       │  │            │
│         │  │  1. Parse SQL files             │  │            │
│         │  │  2. Analyze types               │  │            │
│         │  │  3. Generate MoonBit code       │  │            │
│         │  └────────────────┼────────────────┘  │            │
│         │                   │                    │            │
│         ▼                   ▼                    │            │
│  ┌─────────────────────────────────────────────┐│            │
│  │          Orion Runtime Library              ││            │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────┴┴──────────┐ │ │
│  │  │ Connection  │ │  Tx/Pool    │ │  Driver Interface   │ │ │
│  │  │    Mgmt     │ │  Mgmt       │ │  (SQLite/PG/MySQL)  │ │ │
│  │  └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                    │
└──────────────────────────────┼────────────────────────────────────┘
                               │
                               ▼
                ┌──────────────────────────────┐
                │      Database Drivers        │
                │  (community packages)        │
                ├──────────────────────────────┤
                │  myfreess/sqlite3 (C FFI)    │
                │  mattn/postgres (libpq)      │
                │  mysql (future)              │
                └──────────────┬───────────────┘
                               │
                               ▼
                ┌──────────────────────────────┐
                │         Database             │
                │   SQLite / PostgreSQL / MySQL│
                └──────────────────────────────┘
```

### 2.2 核心组件

| 组件 | 职责 | 实现方式 |
|------|------|----------|
| **SQL Parser** | 解析 `.sql` 文件，提取查询元数据 | 复用 moonbit-community/sqlparser |
| **Type Analyzer** | 从 SQL 推导输入/输出类型 | Orion 自研 |
| **Code Generator** | 生成 MoonBit Mapper 代码 | Orion 自研 |
| **Runtime** | 连接池、事务、日志、错误处理 | Orion 自研 |
| **Driver Adapter** | 统一数据库驱动接口 | 封装社区包 |
| **CLI** | 代码生成、迁移管理 | Orion 自研 |

---

## 3. 项目结构设计

### 3.1 目录结构

```
Orion/
├── cmd/
│   └── orion/              # CLI 入口
│       ├── main.mbt        # main 函数，参数解析
│       └── moon.pkg
├── lib/
│   ├── parser/             # SQL 文件解析
│   │   ├── sql_file.mbt    # 解析 .sql 文件（name, description, result）
│   │   ├── query_meta.mbt  # Query 元数据结构
│   │   └── moon.pkg
│   ├── analyzer/           # 类型推导
│   │   ├── type_infer.mbt  # 从 SQL 推导类型
│   │   ├── column_map.mbt  # 列到字段映射
│   │   └── moon.pkg
│   ├── codegen/            # 代码生成
│   │   ├── gen_mapper.mbt  # 生成 Mapper 模块
│   │   ├── gen_struct.mbt  # 生成 Struct（可选）
│   │   └── moon.pkg
│   ├── runtime/            # 运行时
│   │   ├── db.mbt          # 数据库连接管理
│   │   ├── pool.mbt        # 连接池（并发安全）
│   │   ├── transaction.mbt # 事务支持
│   │   ├── log.mbt         # 日志系统
│   │   ├── error.mbt       # 错误类型定义
│   │   └── moon.pkg
│   ├── driver/             # 驱动适配层
│   │   ├── driver_iface.mbt # Driver 接口定义
│   │   ├── sqlite_adapter.mbt
│   │   ├── postgres_adapter.mbt
│   │   └── moon.pkg
│   └── orion.mbt           # 主模块导出
├── examples/
│   └── basic/              # 示例项目
│       ├── queries/        # SQL 文件
│       ├── generated/      # 生成的代码
│       └── main.mbt
├── specs/
│   ├── prd.md
│   └── design.md
├── moon.mod.json
└── moon.pkg
```

### 3.2 包依赖关系

```
cmd/orion
    ├── lib/parser
    ├── lib/analyzer
    ├── lib/codegen
    └── lib/runtime

lib/codegen
    ├── lib/parser
    └── lib/analyzer

lib/analyzer
    └── lib/parser

lib/runtime
    └── lib/driver

lib/driver
    ├── myfreess/sqlite3 (external)
    └── mattn/postgres (external)
```

---

## 4. 核心抽象设计

### 4.1 SQL 文件元数据

```moonbit
// lib/parser/query_meta.mbt

/// SQL 查询的元数据
struct QueryMeta {
  /// 查询名称（用于生成函数名）
  name: String
  /// 查询描述
  description: Option[String]
  /// 返回类型
  result_type: ResultType
  /// SQL 语句内容
  sql: String
  /// 参数数量
  param_count: Int
  /// 动态 SQL 标记
  is_dynamic: Bool
}

/// 返回类型枚举
enum ResultType {
  /// 单行结果
  Single
  /// 多行结果
  Many
  /// 最后插入 ID
  LastInsertId
  /// 影响行数
  AffectedRows
}

/// 参数信息
struct ParamInfo {
  /// 参数位置（0-based）
  index: Int
  /// 推断的类型
  inferred_type: Option[String]
  /// 参数名（从注释或 $1 风格提取）
  name: Option[String]
}

/// 列信息
struct ColumnInfo {
  /// 列名
  name: String
  /// 推断的类型
  inferred_type: Option[String]
  /// 是否可为空
  nullable: Bool
}
```

### 4.2 运行时核心接口

```moonbit
// lib/runtime/db.mbt

/// 数据库配置
struct DbConfig {
  /// 数据库 URL
  url: String
  /// 连接池大小
  pool_size: Int
  /// 连接超时（毫秒）- 获取连接的最大等待时间
  connection_timeout: Int
  /// 查询超时（毫秒）
  query_timeout: Int
  /// 空闲超时（毫秒）- 连接在池中的最大空闲时间
  idle_timeout: Int
  /// 是否启用日志
  enable_log: Bool
}

/// 数据库连接
struct Db {
  config: DbConfig
  pool: ConnectionPool
  logger: Logger
}

/// 事务上下文（显式传递模式）
struct Tx {
  conn: Connection
  committed: Bool
  rolled_back: Bool
}

/// 事务模式：支持 Db 和 Tx 两种上下文
enum TxContext {
  Standalone(Db)      // 独立模式：从池获取连接
  InTransaction(Tx)   // 事务模式：使用事务连接
}
```

### 4.3 连接池（并发安全设计）

**架构决策 ADR-001**: 使用 Mutex 锁保护并发访问

```moonbit
// lib/runtime/pool.mbt

/// 连接池实现（并发安全）
struct ConnectionPool {
  /// 工厂函数（创建新连接）
  factory: () -> Result[Connection, DbError]
  /// 空闲连接队列
  idle: List[Connection]
  /// 当前活跃连接数
  active_count: Int
  /// 最大连接数
  max_size: Int
  /// 互斥锁（并发安全）
  mutex: Mutex
  /// 条件变量（池满时等待）
  condition: Condition
  /// 连接超时（毫秒）
  connection_timeout: Int
}

/// 池化连接（RAII 模式）
struct PooledConnection {
  conn: Option[Connection]
  pool: ConnectionPool
}

impl ConnectionPool {
  /// 创建新连接池
  fn new(
    factory: () -> Result[Connection, DbError],
    max_size: Int,
    connection_timeout: Int
  ) -> ConnectionPool {
    ConnectionPool {
      factory: factory,
      idle: [],
      active_count: 0,
      max_size: max_size,
      mutex: Mutex.new(),
      condition: Condition.new(),
      connection_timeout: connection_timeout
    }
  }
  
  /// 获取连接（线程安全）
  fn acquire(self) -> Result[PooledConnection, DbError> {
    self.mutex.lock()
    
    // 有空闲连接：复用
    if !self.idle.is_empty() {
      let conn = self.idle.pop()
      self.active_count += 1
      self.mutex.unlock()
      return Ok(PooledConnection::new(conn, self))
    }
    
    // 未达上限：创建新连接
    if self.active_count < self.max_size {
      match self.factory() {
        Ok(conn) => {
          self.active_count += 1
          self.mutex.unlock()
          return Ok(PooledConnection::new(conn, self))
        }
        Err(e) => {
          self.mutex.unlock()
          return Err(e)
        }
      }
    }
    
    // 已达上限：等待或报错
    self.mutex.unlock()
    Err(DbError::PoolExhausted)
  }
  
  /// 归还连接（线程安全）
  fn release(self, conn: Connection) {
    self.mutex.lock()
    self.active_count -= 1
    self.idle.push(conn)
    self.mutex.unlock()
  }
}

impl PooledConnection {
  /// 创建新实例
  fn new(conn: Connection, pool: ConnectionPool) -> PooledConnection {
    PooledConnection {
      conn: Some(conn),
      pool: pool
    }
  }
  
  /// 获取内部连接
  fn get(&self) -> Connection {
    self.conn.unwrap()
  }
  
  /// 归还连接到池
  fn close(mut self) {
    match self.conn.take() {
      Some(c) => self.pool.release(c)
      None => ()
    }
  }
}

/// 安全使用连接的包装函数（推荐模式）
fn with_connection[T](
  pool: ConnectionPool,
  f: (Connection) -> Result[T, DbError>
) -> Result[T, DbError> {
  let pooled = pool.acquire()?
  try {
    f(pooled.get())
  } finally {
    pooled.close()
  }
}
```

### 4.4 Driver 接口

```moonbit
// lib/driver/driver_iface.mbt

/// 值类型（参数和结果）
enum DbValue {
  Null
  Int(Int)
  Int64(Int64)       // 新增：支持大整数
  Float(Float)
  String(String)
  Bool(Bool)
  Bytes(List[Int])
  DateTime(Int64)    // 新增：时间戳（毫秒）
}

/// 数据库连接（Enum 方案 - ADR-004）
enum Connection {
  Sqlite(myfreess/sqlite3.Connection)
  Postgres(mattn/postgres.Connection)
  // MySQL (future)
}

/// 数据库驱动接口
trait DbDriver {
  /// 打开连接
  fn open(url: String) -> Result[Connection, DbError]
  
  /// 关闭连接
  fn close(conn: Connection) -> Result[Unit, DbError]
  
  /// 执行查询（返回结果集）
  fn query(
    conn: Connection,
    sql: String,
    params: List[DbValue]
  ) -> Result[ResultSet, DbError]
  
  /// 执行命令（返回影响行数）
  fn execute(
    conn: Connection,
    sql: String,
    params: List[DbValue]
  ) -> Result[Int, DbError]
  
  /// 开始事务
  fn begin_tx(conn: Connection) -> Result[Unit, DbError]
  
  /// 提交事务
  fn commit(conn: Connection) -> Result[Unit, DbError]
  
  /// 回滚事务
  fn rollback(conn: Connection) -> Result[Unit, DbError]
}

/// 结果集（支持按列名访问）
struct ResultSet {
  columns: List[ColumnInfo]
  rows: List<Row>
}

/// 行封装（支持按列名和索引访问）
struct Row {
  columns: List[ColumnInfo]
  values: List[DbValue]
}

impl Row {
  /// 按索引获取值
  fn get(self, index: Int) -> Option[DbValue] {
    self.values.get(index)
  }
  
  /// 按列名获取值
  fn get_by_name(self, name: String) -> Option[DbValue] {
    let idx = self.columns.find_index(fn(c) => c.name == name)
    match idx {
      Some(i) => self.values.get(i)
      None => None
    }
  }
  
  /// 类型安全的获取方法
  fn get_int(self, index: Int) -> Result[Int, DbError]
  fn get_string(self, index: Int) -> Result[String, DbError]
  fn get_bool(self, index: Int) -> Result[Bool, DbError]
  fn get_string(self, index: Int) -> Result[String, DbError]
}

/// 数据库错误
enum DbError {
  /// 连接失败
  ConnectionError {
    message: String
    cause: Option[String]
  }
  /// 查询错误
  QueryError {
    message: String
    sql: Option[String]
    cause: Option[String]
  }
  /// 约束违反
  ConstraintViolation {
    constraint: String
    message: String
  }
  /// 未找到记录
  NotFound
  /// 连接池耗尽
  PoolExhausted
  /// 超时
  Timeout {
    operation: String
    timeout_ms: Int
  }
  /// 驱动内部错误
  DriverError {
    message: String
    driver: String
  }
}
```

### 4.5 事务管理（ADR-002, ADR-003）

```moonbit
// lib/runtime/transaction.mbt

/// 事务执行函数（显式传递模式）
fn transaction<T>(
  db: Db,
  f: (Tx) -> Result[T, DbError>
) -> Result[T, DbError> {
  // 获取连接
  let conn = db.pool.acquire()?
  
  // 创建事务上下文
  let mut tx = Tx {
    conn: conn,
    committed: false,
    rolled_back: false
  }
  
  // 开始事务
  db.driver.begin_tx(tx.conn)?
  
  try {
    // 执行用户函数
    let result = f(tx)
    
    match result {
      Ok(value) => {
        // 成功：提交
        if !tx.committed {
          db.driver.commit(tx.conn)?
          tx.committed = true
        }
        Ok(value)
      }
      Err(e) => {
        // 失败：回滚
        if !tx.rolled_back {
          db.driver.rollback(tx.conn)?
          tx.rolled_back = true
        }
        Err(e)
      }
    }
  } finally {
    // 始终归还连接（ADR-003）
    db.pool.release(tx.conn)
  }
}

/// Mapper 同时支持 Db 和 Tx 模式
struct UserMapper {
  ctx: TxContext
}

impl UserMapper {
  /// 创建独立模式 Mapper
  fn new(db: Db) -> UserMapper {
    UserMapper { ctx: TxContext::Standalone(db) }
  }
  
  /// 创建事务模式 Mapper
  fn with_tx(tx: Tx) -> UserMapper {
    UserMapper { ctx: TxContext::InTransaction(tx) }
  }
  
  /// 获取连接（内部方法）
  fn get_conn(&self) -> Result<ConnectionHandle, DbError> {
    match self.ctx {
      TxContext::Standalone(db) => {
        // 独立模式：从池获取
        Ok(ConnectionHandle::Pooled(db.pool.acquire()?))
      }
      TxContext::InTransaction(tx) => {
        // 事务模式：直接使用事务连接
        Ok(ConnectionHandle::Borrowed(tx.conn))
      }
    }
  }
  
  /// 查询示例
  fn get_user_by_id(self, id: Int) -> Result[Option[User], DbError] {
    let conn = self.get_conn()?
    let sql = "SELECT id, name, age FROM users WHERE id = ?"
    conn.query(sql, [DbValue::Int(id)])
  }
}

/// 连接句柄（统一处理）
enum ConnectionHandle {
  Pooled(PooledConnection)    // 需要归还
  Borrowed(Connection)         // 不需要归还
}
```

### 4.6 错误处理

```moonbit
// lib/runtime/error.mbt

/// Orion 统一错误类型
enum OrionError {
  /// SQL 解析错误
  ParseError {
    file: String
    line: Int
    message: String
  }
  /// 类型推导错误
  TypeInferenceError {
    query_name: String
    message: String
  }
  /// 代码生成错误
  GenerationError {
    target: String
    message: String
  }
  /// 数据库错误
  Db(DbError)
  /// CLI 配置错误
  ConfigError {
    option: String
    message: String
  }
}

/// 错误转换：DbError -> OrionError
impl From[DbError] for OrionError {
  fn from(e: DbError) -> OrionError {
    OrionError::Db(e)
  }
}

/// 错误转换：sqlite3.Error -> OrionError
impl From[myfreess/sqlite3.Error] for OrionError {
  fn from(e: myfreess/sqlite3.Error) -> OrionError {
    OrionError::Db(DbError::QueryError {
      message: e.message,
      sql: None,
      cause: None
    })
  }
}

/// 错误上下文扩展
trait WithContext[T] {
  fn with_context(self, msg: String) -> Result[T, OrionError>
  fn context(self, msg: String) -> Result[T, OrionError>
}

impl[A, B] WithContext[A] for Result[A, OrionError> {
  fn with_context(self, msg: String) -> Result[A, OrionError> {
    match self {
      Ok(v) => Ok(v)
      Err(e) => Err(OrionError::Db(DbError::QueryError {
        message: msg + ": " + e.message,
        sql: None,
        cause: Some(e.message)
      }))
    }
  }
}
```

---

## 5. SQL 解析与类型推导

### 5.1 SQL 文件解析流程

```
┌─────────────────┐
│  user.sql file  │
│  ─────────────  │
│  -- name: getUserById
│  -- description: Get user by ID
│  -- result: single
│  SELECT id, name, age FROM users WHERE id = ?
│  ───────────────────────────────────────────
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  1. Lexical Analysis (Scanner)      │
│     - Tokenize SQL content          │
│     - Identify comments (-- name:)  │
│     - Identify SQL statement        │
│     - Identify dynamic SQL tags     │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  2. Parse Metadata                  │
│     - Extract name                  │
│     - Extract description           │
│     - Extract result_type           │
│     - Count parameters (?)          │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  3. Parse SQL Statement (optional)  │
│     - Use sqlparser for full AST    │
│     - Extract SELECT columns        │
│     - Analyze WHERE clause          │
│     - Infer parameter types         │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  4. Build QueryMeta                 │
│     - name: "getUserById"           │
│     - result_type: Single           │
│     - param_count: 1                │
│     - columns: [(id,Int), (name,String), (age,Int)]
└─────────────────────────────────────┘
```

### 5.2 类型推导策略

#### MVP 阶段（v0.1.0）
- **简单推导**: 基于常见模式推断类型
  - `WHERE id = ?` → 第一个参数为 `Int`
  - `SELECT ... FROM users` → 结果类型为 `User` struct
  - `INSERT INTO users ...` → 返回 `Int` (last insert id)

#### 增强阶段（v0.2.0+）
- **Schema 感知**: 读取数据库 schema 进行精确推导
- **sqlparser 集成**: 解析完整 SQL AST 进行语义分析
- **用户注解**: 支持类型注解注释
  ```sql
  -- name: getUserById
  -- @param id: Int
  -- @returns User
  SELECT * FROM users WHERE id = ?
  ```

---

## 6. 代码生成

### 6.1 生成的代码结构

对于以下 SQL 文件：

```sql
-- name: getUserById
-- description: Get user by ID
-- result: single
SELECT id, name, age FROM users WHERE id = ?;
```

生成的 MoonBit 代码：

```moonbit
// generated/user_mapper.mbt

/// User 数据模型
struct User {
  id: Int
  name: String
  age: Int
}

/// UserMapper 模块
struct UserMapper {
  ctx: TxContext
}

/// 创建独立模式 Mapper
fn new_user_mapper(db: Db) -> UserMapper {
  UserMapper { ctx: TxContext::Standalone(db) }
}

/// 创建事务模式 Mapper
fn with_user_mapper(tx: Tx) -> UserMapper {
  UserMapper { ctx: TxContext::InTransaction(tx) }
}

/// getUserById - Get user by ID
/// @param id: Int
/// @returns: Option[User]
fn get_user_by_id(self: UserMapper, id: Int) -> Result[Option[User], DbError] {
  let sql = "SELECT id, name, age FROM users WHERE id = ?"
  let conn = self.get_conn()?
  let result = conn.query(sql, [DbValue::Int(id)])
  
  match result {
    Ok(Some(row)) => {
      Ok(Some(User {
        id: row.get_int(0)?,
        name: row.get_string(1)?,
        age: row.get_int(2)?
      }))
    }
    Ok(None) => Ok(None)
    Err(e) => Err(e)
  }
}
```

### 6.2 代码生成器接口

```moonbit
// lib/codegen/gen_mapper.mbt

/// 代码生成器
struct CodeGenerator {
  /// 输出目录
  output_dir: String
  /// 是否生成 struct
  gen_struct: Bool
  /// 是否格式化输出
  format_output: Bool
}

impl CodeGenerator {
  /// 从 QueryMeta 生成代码
  fn generate(
    self,
    queries: List[QueryMeta],
    target_file: String
  ) -> Result[Unit, String] {
    // 1. 分组 queries 按表名
    let grouped = self.group_by_table(queries)
    
    // 2. 为每个表生成 Mapper
    for (table_name, table_queries) in grouped {
      let mapper_code = self.gen_mapper_module(table_name, table_queries)
      self.write_file(mapper_code, target_file)
    }
  }
  
  /// 生成 Mapper 模块
  fn gen_mapper_module(
    self,
    table_name: String,
    queries: List[QueryMeta]
  ) -> String {
    let struct_name = self.to_pascal_case(table_name)
    
    // 生成 struct 定义
    let struct_block = if self.gen_struct {
      self.gen_struct_def(struct_name, queries[0].columns)
    } else { "" }
    
    // 生成 Mapper struct
    let mapper_struct = self.gen_mapper_struct(struct_name)
    
    // 生成函数
    let func_blocks = queries.map(fn(q) => self.gen_query_fn(q))
    
    // 组装所有块
    self.join_blocks([struct_block, mapper_struct, ...func_blocks])
  }
}
```

---

## 7. 运行时实现

### 7.1 连接池设计（并发安全）

详见 4.3 节。

### 7.2 事务支持

详见 4.5 节。

### 7.3 日志系统

```moonbit
// lib/runtime/log.mbt

/// 日志级别
enum LogLevel {
  Debug
  Info
  Warn
  Error
}

/// 日志记录器
struct Logger {
  level: LogLevel
  output: LogOutput
}

/// 日志输出目标
enum LogOutput {
  Stdout
  File(String)
  Callback((String) -> Unit)
}

impl Logger {
  fn debug(self, msg: String, ctx: Map[String, String]) {
    if self.level <= LogLevel::Debug {
      self.log("DEBUG", msg, ctx)
    }
  }
  
  fn info(self, msg: String, ctx: Map[String, String]) {
    if self.level <= LogLevel::Info {
      self.log("INFO ", msg, ctx)
    }
  }
  
  fn warn(self, msg: String, ctx: Map[String, String]) {
    if self.level <= LogLevel::Warn {
      self.log("WARN ", msg, ctx)
    }
  }
  
  fn error(self, msg: String, ctx: Map[String, String]) {
    if self.level <= LogLevel::Error {
      self.log("ERROR", msg, ctx)
    }
  }
  
  fn log(self, level: String, msg: String, ctx: Map[String, String]) {
    let timestamp = get_timestamp()
    let formatted = format_log(timestamp, level, msg, ctx)
    
    match self.output {
      LogOutput::Stdout => println(formatted)
      LogOutput::File(path) => append_file(path, formatted + "\n")
      LogOutput::Callback(cb) => cb(formatted)
    }
  }
}

/// SQL 日志中间件（带性能监控）
fn logged_query(
  db: Db,
  query_name: String,
  sql: String,
  params: List[DbValue]
) -> Result<ResultSet, DbError> {
  let start = now_ms()
  
  match db.query(sql, params) {
    Ok(result) => {
      let duration = now_ms() - start
      db.logger.debug("Query executed", {
        query: query_name,
        duration_ms: Int.to_string(duration)
      })
      Ok(result)
    }
    Err(e) => {
      db.logger.error("Query failed", {
        query: query_name,
        sql: sql,
        error: e.message
      })
      Err(e)
    }
  }
}
```

---

## 8. CLI 设计

### 8.1 命令结构

```moonbit
// cmd/orion/main.mbt

/// CLI 命令枚举
enum Command {
  /// 代码生成
  Gen {
    /// 输入目录（默认：./queries）
    input: String,
    /// 输出目录（默认：./generated）
    output: String,
    /// 监听模式
    watch: Bool
  }
  /// 数据库迁移（v0.2.0+）
  Migrate {
    /// 迁移文件目录
    dir: String,
    /// 操作类型
    action: MigrateAction
  }
}

/// 迁移操作
enum MigrateAction {
  /// 创建新迁移
  Create { name: String }
  /// 应用所有待处理迁移
  Up
  /// 回滚最后一个迁移
  Down
  /// 查看迁移状态
  Status
}

fn main {
  let args = os.get_args()
  
  match parse_args(args) {
    Some(Command::Gen { input, output, watch }) => {
      cmd_gen(input, output, watch)
    }
    Some(Command::Migrate { dir, action }) => {
      cmd_migrate(dir, action)
    }
    None => {
      print_help()
      os.exit(1)
    }
  }
}
```

### 8.2 代码生成命令流程

```moonbit
fn cmd_gen(input: String, output: String, watch: Bool) {
  // 1. 扫描输入目录
  let sql_files = scan_sql_files(input)
  
  if sql_files.is_empty() {
    println("No .sql files found in {}", input)
    return
  }
  
  // 2. 解析每个 SQL 文件
  let mut queries = []
  for file in sql_files {
    let content = read_file(file.path)
    match parse_sql_file(content) {
      Ok(q) => queries.push(q)
      Err(e) => {
        eprintln("Error parsing {}: {}", file.name, e)
        os.exit(1)
      }
    }
  }
  
  // 3. 生成代码
  let generator = CodeGenerator {
    output_dir: output,
    gen_struct: true,
    format_output: true
  }
  
  match generator.generate(queries, output) {
    Ok(_) => println("Generated {} queries to {}", queries.length, output)
    Err(e) => {
      eprintln("Generation failed: {}", e)
      os.exit(1)
    }
  }
  
  // 4. 监听模式
  if watch {
    watch_directory(input, fn() => cmd_gen(input, output, false))
  }
}
```

---

## 9. 错误处理

详见 4.6 节。

---

## 10. 日志系统

详见 7.3 节。

---

## 11. 测试策略

### 11.1 测试分层

```
┌─────────────────────────────────────┐
│         End-to-End Tests            │  ← 完整流程测试
│  (CLI → SQL → Codegen → Runtime)    │
└─────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────┐
│         Integration Tests           │  ← 组件集成测试
│  (Parser + Analyzer + Codegen)      │
│  (Runtime + Driver Adapter)         │
└─────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────┐
│           Unit Tests                │  ← 单元测试
│  (Parser tests)                     │
│  (Type inference tests)             │
│  (Codegen snapshot tests)           │
│  (Runtime mock tests)               │
└─────────────────────────────────────┘
```

### 11.2 快照测试示例

```moonbit
// lib/codegen/codegen_wbtest.mbt

test fn test_gen_select_query {
  let query = QueryMeta {
    name: "getUserById",
    description: Some("Get user by ID"),
    result_type: ResultType::Single,
    sql: "SELECT id, name, age FROM users WHERE id = ?",
    param_count: 1,
    is_dynamic: false
  }
  
  let generator = CodeGenerator {
    output_dir: "./test_output",
    gen_struct: true,
    format_output: true
  }
  
  let code = generator.gen_query_fn(query)
  
  // 使用快照测试验证生成代码
  assert_snapshot(code)
}
```

### 11.3 并发测试（连接池）

```moonbit
// lib/runtime/pool_wbtest.mbt

test fn test_pool_concurrent_acquire {
  let pool = ConnectionPool::new(
    fn() => mock_connection(),
    max_size: 5,
    connection_timeout: 1000
  )
  
  // 并发获取连接
  let results = parallel_map([1, 2, 3, 4, 5], fn(i) => {
    pool.acquire()
  })
  
  // 所有连接都应该成功获取
  assert(results.all(fn(r) => r.is_ok()))
  
  // 第 6 个连接应该失败（池耗尽）
  assert(pool.acquire().is_err())
}
```

---

## 12. 里程碑与交付物

### v0.1.0 MVP

| 组件 | 文件 | 状态 |
|------|------|------|
| SQL Parser | `lib/parser/sql_file.mbt` | TODO |
| Type Analyzer | `lib/analyzer/type_infer.mbt` | TODO |
| Code Generator | `lib/codegen/gen_mapper.mbt` | TODO |
| Runtime Core | `lib/runtime/db.mbt` | TODO |
| Connection Pool (并发安全) | `lib/runtime/pool.mbt` | TODO |
| Transaction (显式传递) | `lib/runtime/transaction.mbt` | TODO |
| SQLite Adapter | `lib/driver/sqlite_adapter.mbt` | TODO |
| CLI Entry | `cmd/orion/main.mbt` | TODO |

### v0.1.1-v0.1.x

- [ ] 连接健康检查 (`lib/runtime/pool.mbt`)
- [ ] 预编译语句缓存 (`lib/runtime/prepared_stmt.mbt`)
- [ ] 错误处理完善 (`lib/runtime/error.mbt`)
- [ ] 日志系统 (`lib/runtime/log.mbt`)
- [ ] PostgreSQL Adapter

### v0.2.0

- [ ] 事务支持完善（嵌套事务）
- [ ] Migration CLI
- [ ] Schema 感知类型推导
- [ ] 动态 SQL 支持

---

## 附录：架构决策记录 (ADR)

### ADR-001: 连接池并发安全实现

**决策**: 使用 Mutex 锁保护 `idle` 队列和 `active_count`

**理由**:
- 简单直接，语义清晰
- 符合传统连接池实现模式
- 易于调试和测试

**风险**: MoonBit 标准库可能不提供 Mutex，需使用 `moonbitlang/core` 或社区包

---

### ADR-002: 事务传播机制

**决策**: MVP 采用显式传递 `Tx`，v0.2 考虑 Thread-Local Storage

**理由**:
- MVP 实现简单，API 语义清晰
- 类型安全，编译器保证正确性
- TLS 可作为后续优化

**影响**: 用户代码需要显式传递 `Tx` 或使用 `with_tx()` 构造 Mapper

---

### ADR-003: 事务连接归还

**决策**: 使用 `finally` 块确保连接始终归还

**理由**:
- 不依赖语言特性的 `defer` 或 `using`
- MoonBit 支持 `try/finally`
- 语义清晰，易于理解

---

### ADR-004: Connection 类型设计

**决策**: 使用 Enum 封装不同驱动连接

**理由**:
- 类型安全，编译期确定
- 模式匹配清晰
- MVP 阶段实现简单

**风险**: 新增驱动需修改 `Connection` enum，但 v0.3 可迁移到 Trait 对象

---

### ADR-005: 连接生命周期管理

**决策**: 采用 `with_connection` 块模式确保连接自动归还

**理由**:
- 函数式风格，符合 MoonBit 范式
- 不依赖 GC finalizer
- API 清晰，易于测试

---

## 附录：参考链接

- [PRD 文档](prd.md)
- [Prisma ORM](https://www.prisma.io/)
- [Drizzle ORM](https://orm.drizzle.team/)
- [MyBatis](https://mybatis.org/)
- [MoonBit 官方](https://www.moonbitlang.com/)
- [moonbit-community/sqlparser](https://mooncakes.io/docs/moonbit-community/sqlparser)
- [myfreess/sqlite3](https://mooncakes.io/docs/myfreess/sqlite3)
- [mattn/postgres](https://mooncakes.io/docs/mattn/postgres)
