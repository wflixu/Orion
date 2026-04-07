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
│   │   ├── pool.mbt        # 连接池
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
  /// 查询超时（毫秒）
  query_timeout: Int
  /// 是否启用日志
  enable_log: Bool
}

/// 数据库连接
struct Db {
  config: DbConfig
  pool: ConnectionPool
}

/// 连接池
struct ConnectionPool {
  /// 空闲连接
  idle_connections: List[Connection]
  /// 活跃连接数
  active_count: Int
  /// 最大连接数
  max_size: Int
}

/// 事务上下文
struct Transaction {
  conn: Connection
  /// 事务是否已完成
  committed: Bool
  /// 事务是否已回滚
  rolled_back: Bool
}
```

### 4.3 Driver 接口

```moonbit
// lib/driver/driver_iface.mbt

/// 值类型（参数和结果）
enum DbValue {
  Null
  Int(Int)
  Float(Float)
  String(String)
  Bool(Bool)
  Bytes(List[Int])
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
  fn begin_tx(conn: Connection) -> Result[Transaction, DbError]
  
  /// 提交事务
  fn commit(tx: Transaction) -> Result[Unit, DbError]
  
  /// 回滚事务
  fn rollback(tx: Transaction) -> Result[Unit, DbError]
}

/// 结果集
struct ResultSet {
  columns: List[ColumnInfo]
  rows: List[List[DbValue]]
}

/// 数据库错误
enum DbError {
  /// 连接失败
  ConnectionError(String)
  /// 查询错误
  QueryError(String)
  /// 约束违反
  ConstraintViolation(String)
  /// 未找到记录
  NotFound
  /// 驱动内部错误
  DriverError(String)
}
```

### 4.4 SQLite Adapter 实现示例

```moonbit
// lib/driver/sqlite_adapter.mbt

import myfreess/sqlite3

struct SqliteDriver {
  impl DbDriver for SqliteDriver
}

impl DbDriver for SqliteDriver {
  fn open(url: String) -> Result[Connection, DbError] {
    match Sqlite3.open(url) {
      Ok(conn) => Ok(Connection::Sqlite(conn))
      Err(e) => Err(DbError::ConnectionError(e.message))
    }
  }
  
  fn query(
    conn: Connection,
    sql: String,
    params: List[DbValue]
  ) -> Result[ResultSet, DbError] {
    // 将 DbValue 转换为 Sqlite3.Value
    let sqlite_params = params.map(fn(v) => to_sqlite_value(v))
    
    match conn {
      Connection::Sqlite(c) => {
        match Sqlite3.query(c, sql, sqlite_params) {
          Ok(result) => Ok(to_result_set(result))
          Err(e) => Err(DbError::QueryError(e.message))
        }
      }
      _ => Err(DbError::DriverError("Wrong driver type"))
    }
  }
  
  // ... 其他方法实现
}

fn to_sqlite_value(v: DbValue) -> Sqlite3.Value {
  match v {
    DbValue::Null => Sqlite3.Null
    DbValue::Int(i) => Sqlite3.Integer(i)
    DbValue::Float(f) => Sqlite3.Real(f)
    DbValue::String(s) => Sqlite3.Text(s)
    DbValue::Bool(b) => Sqlite3.Integer(if b { 1 } else { 0 })
    DbValue::Bytes(_) => todo!("blob support")
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
  db: Db
}

/// 创建 UserMapper 实例
fn new_user_mapper(db: Db) -> UserMapper {
  UserMapper { db: db }
}

/// getUserById - Get user by ID
/// @param id: Int
/// @returns: Option[User]
fn get_user_by_id(self: UserMapper, id: Int) -> Result[Option[User], DbError] {
  let sql = "SELECT id, name, age FROM users WHERE id = ?"
  let result = self.db.query_one(sql, [DbValue::Int(id)])
  
  match result {
    Ok(Some(row)) => {
      Ok(Some(User {
        id: row.get_int(0),
        name: row.get_string(1),
        age: row.get_int(2)
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

### 7.1 连接池设计

```moonbit
// lib/runtime/pool.mbt

/// 连接池实现
struct ConnectionPool {
  /// 工厂函数（创建新连接）
  factory: () -> Result[Connection, DbError]
  /// 空闲连接队列
  idle: List[Connection]
  /// 当前活跃连接数
  active_count: Int
  /// 最大连接数
  max_size: Int
}

impl ConnectionPool {
  /// 创建新连接池
  fn new(
    factory: () -> Result[Connection, DbError],
    max_size: Int
  ) -> ConnectionPool {
    ConnectionPool {
      factory: factory,
      idle: [],
      active_count: 0,
      max_size: max_size
    }
  }
  
  /// 获取连接
  fn acquire(self) -> Result[PooledConnection, DbError> {
    // 有空闲连接：复用
    if !self.idle.is_empty() {
      let conn = self.idle.pop()
      self.active_count += 1
      Ok(PooledConnection::new(conn, self))
    }
    // 未达上限：创建新连接
    else if self.active_count < self.max_size {
      match self.factory() {
        Ok(conn) => {
          self.active_count += 1
          Ok(PooledConnection::new(conn, self))
        }
        Err(e) => Err(e)
      }
    }
    // 已达上限：等待或报错
    else {
      Err(DbError::ConnectionError("Pool exhausted"))
    }
  }
  
  /// 归还连接
  fn release(self, conn: Connection) {
    self.active_count -= 1
    self.idle.push(conn)
  }
}

/// 池化连接（RAII 模式）
struct PooledConnection {
  conn: Option[Connection]
  pool: ConnectionPool
}

impl PooledConnection {
  /// 连接用完时自动归还到池
  fn close(mut self) {
    match self.conn.take() {
      Some(c) => self.pool.release(c)
      None => ()
    }
  }
}
```

### 7.2 事务支持

```moonbit
// lib/runtime/transaction.mbt

/// 事务执行函数
fn transaction<T>(
  db: Db,
  f: (Transaction) -> Result[T, DbError>
) -> Result[T, DbError> {
  // 1. 获取连接
  let conn = db.pool.acquire()?
  
  // 2. 开始事务
  conn.driver.begin_tx(conn.inner)?
  
  // 3. 创建事务上下文
  let tx = Transaction {
    conn: conn,
    committed: false,
    rolled_back: false
  }
  
  // 4. 执行用户函数
  match f(tx) {
    Ok(result) => {
      // 成功：提交
      tx.commit()?
      Ok(result)
    }
    Err(e) => {
      // 失败：回滚
      tx.rollback()?
      Err(e)
    }
  }
}

/// 事务 API 示例
fn example_usage(db: Db) -> Result[Unit, DbError> {
  transaction(db, fn(tx) {
    // 在事务内执行多个查询
    let user_id = UserMapper.create(tx, "Alice", 25)?
    OrderMapper.create(tx, user_id, 100)?
    Ok(unit)
  })
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

### 9.1 错误类型定义

```moonbit
// lib/runtime/error.mbt

/// Orion 错误类型
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
  /// 运行时数据库错误
  DbError {
    kind: DbErrorKind
    message: String
    sql: Option[String]
  }
  /// CLI 配置错误
  ConfigError {
    option: String
    message: String
  }
}

/// 数据库错误详细类型
enum DbErrorKind {
  Connection
  Query
  ConstraintViolation
  NotFound
  Timeout
  PoolExhausted
}

/// 错误转换辅助函数
impl From[myfreess/sqlite3.Error] for OrionError {
  fn from(e: myfreess/sqlite3.Error) -> OrionError {
    OrionError::DbError {
      kind: match e.code {
        1 => DbErrorKind::ConstraintViolation
        12 => DbErrorKind::NotFound
        _ => DbErrorKind::Query
      },
      message: e.message,
      sql: None
    }
  }
}
```

### 9.2 错误处理最佳实践

```moonbit
/// 使用 Result[T, OrionError] 作为统一返回类型
fn execute_query(
  db: Db,
  query_name: String,
  sql: String,
  params: List[DbValue]
) -> Result[ResultSet, OrionError] {
  // 获取连接
  let conn = db.acquire().map_err(|e| OrionError::DbError {
    kind: DbErrorKind::Connection,
    message: "Failed to acquire connection: \(e.message)",
    sql: None
  })?
  
  // 执行查询
  match conn.execute(sql, params) {
    Ok(result) => Ok(result)
    Err(e) => {
      // 记录日志
      if db.config.enable_log {
        db.logger.error("Query failed", {
          query: query_name,
          sql: sql,
          error: e.message
        })
      }
      
      // 转换错误
      Err(OrionError::DbError {
        kind: DbErrorKind::Query,
        message: e.message,
        sql: Some(sql)
      })
    }
  }
}
```

---

## 10. 日志系统

### 10.1 日志级别和输出

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

/// 日志格式示例
/// [2026-04-07T12:34:56Z] INFO  Query executed {query: getUserById, duration_ms: 15}
```

### 10.2 SQL 日志中间件

```moonbit
/// 带日志的查询包装器
fn logged_query(
  db: Db,
  query_name: String,
  sql: String,
  params: List[DbValue]
) -> Result[ResultSet, OrionError> {
  let start = now_ms()
  
  match db.query(sql, params) {
    Ok(result) => {
      let duration = now_ms() - start
      db.logger.debug("Query executed", {
        query: query_name,
        sql: sql,
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

test fn test_gen_insert_query {
  let query = QueryMeta {
    name: "createUser",
    description: Some("Create a new user"),
    result_type: ResultType::LastInsertId,
    sql: "INSERT INTO users (name, age) VALUES (?, ?)",
    param_count: 2,
    is_dynamic: false
  }
  
  let generator = CodeGenerator {
    output_dir: "./test_output",
    gen_struct: true,
    format_output: true
  }
  
  let code = generator.gen_query_fn(query)
  
  assert_snapshot(code)
}
```

### 11.3 集成测试

```moonbit
// integration/integration_test.mbt

import myfreess/sqlite3

test fn test_sqlite_end_to_end {
  // 创建临时数据库
  let tmp_db = create_temp_db()
  
  // 初始化 schema
  sqlite3.execute(tmp_db, "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
  
  // 运行代码生成
  let queries = [
    QueryMeta {
      name: "createUser",
      sql: "INSERT INTO users (name, age) VALUES (?, ?)",
      result_type: LastInsertId,
      ...
    }
  ]
  
  // 生成并加载代码
  let code = generate_code(queries)
  write_file("./test_gen/user_mapper.mbt", code)
  
  // 执行测试
  let db = Orion.connect("sqlite://" + tmp_db.path)
  let mapper = new_user_mapper(db)
  
  let result = mapper.create_user("Alice", 25)
  assert_eq!(result, Ok(1))
  
  // 清理
  cleanup(tmp_db)
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
| SQLite Adapter | `lib/driver/sqlite_adapter.mbt` | TODO |
| CLI Entry | `cmd/orion/main.mbt` | TODO |

### v0.1.1-v0.1.x

- [ ] 连接池实现 (`lib/runtime/pool.mbt`)
- [ ] 错误处理完善 (`lib/runtime/error.mbt`)
- [ ] 日志系统 (`lib/runtime/log.mbt`)
- [ ] PostgreSQL Adapter

### v0.2.0

- [ ] 事务支持 (`lib/runtime/transaction.mbt`)
- [ ] Migration CLI
- [ ] 动态 SQL 支持

---

## 附录：设计决策记录

### ADR-001: 为什么复用现有包而不是自研？

**决策**: 复用 moonbit-community/sqlparser 和社区 driver 包

**理由**:
1. 社区包已验证可用性
2. 降低 MVP 开发时间（从 2 周到 1 周）
3. Orion 核心价值在 SQL 规范 + 代码生成 + 工具链
4. 可与社区包维护者建立合作

### ADR-002: 为什么选择 Mapper 模式而非 Repository？

**决策**: 采用 Mapper 模式（一 SQL 一函数）

**理由**:
1. 更符合 SQL-first 理念
2. 代码生成更直接
3. 学习 MyBatis 用户成本低
4. 可后续扩展 Repository 层

### ADR-003: 为什么不做 DSL？

**决策**: 不做 schema DSL，SQL 是唯一权威来源

**理由**:
1. MoonBit 类型系统已足够强大
2. 避免维护 DSL 编译器的复杂度
3. SQL 本身已经是标准
4. 减少一层抽象，降低认知负担
