/// Schema DSL 核心模块
/// 表结构定义和 Schema Builder

///|
/// 字段类型
pub enum FieldType {
  Int
  String
  Bool
  Float
  DateTime
  Json
  Blob
} derive(Eq)

///|
/// 字段类型转 SQL 类型字符串
pub fn field_type_to_sql(t : FieldType) -> String {
  match t {
    FieldType::Int => "INTEGER"
    FieldType::String => "TEXT"
    FieldType::Bool => "BOOLEAN"
    FieldType::Float => "REAL"
    FieldType::DateTime => "TEXT"
    FieldType::Json => "TEXT"
    FieldType::Blob => "BLOB"
  }
}

///|
/// 字段定义
pub struct FieldDef {
  name : String
  field_type : FieldType
  constraints : Array[Constraint]
}

///|
/// 创建字段定义
pub fn make_field(
  name : String,
  field_type : FieldType,
  constraints : Array[Constraint],
) -> FieldDef {
  { name, field_type, constraints }
}

///|
/// 获取字段名称
pub fn field_name(f : FieldDef) -> String {
  f.name
}

///|
/// 获取字段类型
pub fn field_type(f : FieldDef) -> FieldType {
  f.field_type
}

///|
/// 获取字段约束
pub fn field_constraints(f : FieldDef) -> Array[Constraint] {
  f.constraints
}

///|
/// 检查字段是否为主键
pub fn field_is_primary_key(f : FieldDef) -> Bool {
  for c in f.constraints {
    if c == Constraint::PrimaryKey {
      return true
    }
  }
  false
}

///|
/// 检查字段是否为自增
pub fn field_is_auto_inc(f : FieldDef) -> Bool {
  for c in f.constraints {
    if c == Constraint::AutoInc {
      return true
    }
  }
  false
}

///|
/// 检查字段是否非空
pub fn field_is_not_null(f : FieldDef) -> Bool {
  for c in f.constraints {
    if c == Constraint::NotNull {
      return true
    }
  }
  false
}

///|
/// 检查字段是否有唯一约束
pub fn field_is_unique(f : FieldDef) -> Bool {
  for c in f.constraints {
    if c == Constraint::Unique {
      return true
    }
  }
  false
}

///|
/// 检查字段是否有默认值
pub fn field_has_default(f : FieldDef) -> Bool {
  for c in f.constraints {
    match c {
      Constraint::Default(_) => return true
      _ => ()
    }
  }
  false
}

///|
/// 获取字段默认值
pub fn field_default_value(f : FieldDef) -> String? {
  for c in f.constraints {
    match c {
      Constraint::Default(v) => return Some(v)
      _ => ()
    }
  }
  None
}

///|
/// 表 Schema 定义
pub struct TableSchema {
  name : String
  fields : Array[FieldDef]
  indexes : Array[IndexDef]
}

///|
/// 创建表 Schema
pub fn make_table_schema(
  name : String,
  fields : Array[FieldDef],
  indexes : Array[IndexDef],
) -> TableSchema {
  { name, fields, indexes }
}

///|
/// 获取表名
pub fn table_name(schema : TableSchema) -> String {
  schema.name
}

///|
/// 获取表字段
pub fn table_fields(schema : TableSchema) -> Array[FieldDef] {
  schema.fields
}

///|
/// 获取表索引
pub fn table_indexes(schema : TableSchema) -> Array[IndexDef] {
  schema.indexes
}

///|
/// 获取主键字段
pub fn get_primary_key_field(schema : TableSchema) -> FieldDef? {
  for f in schema.fields {
    if field_is_primary_key(f) {
      return Some(f)
    }
  }
  None
}

///|
/// Schema Builder（使用可变变量）
pub struct TableSchemaBuilder {
  name : String
  fields : Array[FieldDef]
  indexes : Array[IndexDef]
}

///|
/// 创建 Schema Builder
pub fn schema(name : String) -> TableSchemaBuilder {
  { name, fields: [], indexes: [] }
}

///|
/// 添加字段
pub fn add_field(
  builder : TableSchemaBuilder,
  name : String,
  field_type : FieldType,
  constraints : Array[Constraint],
) -> TableSchemaBuilder {
  let new_fields = builder.fields
  new_fields.push(make_field(name, field_type, constraints))
  { name: builder.name, fields: new_fields, indexes: builder.indexes }
}

///|
/// 添加 Int 字段
pub fn add_int_field(
  builder : TableSchemaBuilder,
  name : String,
  constraints : Array[Constraint],
) -> TableSchemaBuilder {
  add_field(builder, name, FieldType::Int, constraints)
}

///|
/// 添加 String 字段
pub fn add_string_field(
  builder : TableSchemaBuilder,
  name : String,
  constraints : Array[Constraint],
) -> TableSchemaBuilder {
  add_field(builder, name, FieldType::String, constraints)
}

///|
/// 添加 Bool 字段
pub fn add_bool_field(
  builder : TableSchemaBuilder,
  name : String,
  constraints : Array[Constraint],
) -> TableSchemaBuilder {
  add_field(builder, name, FieldType::Bool, constraints)
}

///|
/// 添加索引
pub fn add_index(
  builder : TableSchemaBuilder,
  name : String,
  columns : Array[String],
  unique : Bool,
) -> TableSchemaBuilder {
  let new_indexes = builder.indexes
  new_indexes.push(make_index(name, columns, unique))
  { name: builder.name, fields: builder.fields, indexes: new_indexes }
}

///|
/// 添加唯一索引
pub fn add_unique_index(
  builder : TableSchemaBuilder,
  name : String,
  columns : Array[String],
) -> TableSchemaBuilder {
  add_index(builder, name, columns, true)
}

///|
/// 添加普通索引
pub fn add_normal_index(
  builder : TableSchemaBuilder,
  name : String,
  columns : Array[String],
) -> TableSchemaBuilder {
  add_index(builder, name, columns, false)
}

///|
/// 构建表 Schema
pub fn build_schema(builder : TableSchemaBuilder) -> TableSchema {
  { name: builder.name, fields: builder.fields, indexes: builder.indexes }
}

///|
/// 辅助函数：创建主键 + 自增约束
pub fn pk_auto_inc() -> Array[Constraint] {
  [Constraint::PrimaryKey, Constraint::AutoInc]
}

///|
/// 辅助函数：创建非空约束
pub fn required() -> Array[Constraint] {
  [Constraint::NotNull]
}

///|
/// 辅助函数：创建非空 + 唯一约束
pub fn unique_required() -> Array[Constraint] {
  [Constraint::NotNull, Constraint::Unique]
}

///|
/// 辅助函数：创建默认值约束
pub fn with_default(value : String) -> Array[Constraint] {
  [Constraint::Default(value)]
}
