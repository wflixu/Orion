/// 类型推导分析器
/// 基于 Schema 信息推导 SQL 查询的类型

///|
/// 数据库类型
pub enum DatabaseType {
  Text
  Integer
  Real
  Boolean
  Blob
  Null
  Unknown
}

///|
/// 创建 Text 类型
pub fn db_type_text() -> DatabaseType {
  DatabaseType::Text
}

///|
/// 创建 Integer 类型
pub fn db_type_integer() -> DatabaseType {
  DatabaseType::Integer
}

///|
/// 创建 Real 类型
pub fn db_type_real() -> DatabaseType {
  DatabaseType::Real
}

///|
/// 创建 Boolean 类型
pub fn db_type_boolean() -> DatabaseType {
  DatabaseType::Boolean
}

///|
/// 列信息
pub struct ColumnInfo {
  name : String
  db_type : DatabaseType
  nullable : Bool
  primary_key : Bool
}

///|
/// 表信息
pub struct TableInfo {
  name : String
  columns : Array[ColumnInfo]
}

///|
/// Schema 信息
pub struct SchemaInfo {
  tables : Array[TableInfo]
}

///|
/// 创建空 Schema
pub fn make_empty_schema() -> SchemaInfo {
  { tables: [] }
}

///|
/// 添加表到 Schema
pub fn add_table(schema : SchemaInfo, table : TableInfo) -> SchemaInfo {
  Array::append(schema.tables, [table])
  { tables: schema.tables }
}

///|
/// 创建列信息
pub fn make_column(
  name : String,
  db_type : DatabaseType,
  nullable : Bool,
  primary_key : Bool,
) -> ColumnInfo {
  { name, db_type, nullable, primary_key }
}

///|
/// 创建表信息
pub fn make_table(name : String, columns : Array[ColumnInfo]) -> TableInfo {
  { name, columns }
}

///|
/// 根据 DatabaseType 推导 MoonBit 类型
pub fn db_type_to_mb_type(db_type : DatabaseType) -> String {
  match db_type {
    DatabaseType::Text => "String"
    DatabaseType::Integer => "Int"
    DatabaseType::Real => "Double"
    DatabaseType::Boolean => "Bool"
    DatabaseType::Blob => "Array[Byte]"
    DatabaseType::Null => "Unit"
    DatabaseType::Unknown => "String" // 默认使用 String
  }
}

///|
/// 推导列的 MoonBit 类型
pub fn infer_column_type(column : ColumnInfo) -> String {
  let base_type = db_type_to_mb_type(column.db_type)
  if column.nullable {
    base_type
  } else {
    base_type
  }
}

///|
/// 从 Schema 查找表
pub fn find_table(schema : SchemaInfo, name : String) -> TableInfo? {
  find_table_iter(schema.tables, name)
}

///|
/// 迭代查找表
fn find_table_iter(tables : Array[TableInfo], name : String) -> TableInfo? {
  let len = Array::length(tables)
  if len == 0 {
    None
  } else {
    let first = tables[0]
    if first.name == name {
      Some(first)
    } else {
      // 使用索引跳过第一个元素
      find_table_by_index(tables, name, 1)
    }
  }
}

///|
/// 按索引查找表
fn find_table_by_index(
  tables : Array[TableInfo],
  name : String,
  index : Int,
) -> TableInfo? {
  let len = Array::length(tables)
  if index >= len {
    None
  } else {
    let current = tables[index]
    if current.name == name {
      Some(current)
    } else {
      find_table_by_index(tables, name, index + 1)
    }
  }
}

///|
/// 从表查找列
pub fn find_column(table : TableInfo, name : String) -> ColumnInfo? {
  find_column_iter(table.columns, name)
}

///|
/// 迭代查找列
fn find_column_iter(columns : Array[ColumnInfo], name : String) -> ColumnInfo? {
  let len = Array::length(columns)
  if len == 0 {
    None
  } else {
    let first = columns[0]
    if first.name == name {
      Some(first)
    } else {
      find_column_by_index(columns, name, 1)
    }
  }
}

///|
/// 按索引查找列
fn find_column_by_index(
  columns : Array[ColumnInfo],
  name : String,
  index : Int,
) -> ColumnInfo? {
  let len = Array::length(columns)
  if index >= len {
    None
  } else {
    let current = columns[index]
    if current.name == name {
      Some(current)
    } else {
      find_column_by_index(columns, name, index + 1)
    }
  }
}

///|
/// 从 SQL SELECT 推导返回类型
pub fn infer_select_type(
  schema : SchemaInfo,
  sql : String,
) -> Array[(String, String)] {
  // 简化实现：解析 SELECT 列
  // TODO: 使用 SQL parser 进行完整解析

  // 示例：SELECT id, name FROM users
  let columns = parse_select_columns(sql)
  infer_columns_type(schema, columns)
}

///|
/// 解析 SELECT 列名
pub fn parse_select_columns(sql : String) -> Array[String] {
  // 简化实现：提取 SELECT 和 FROM 之间的列名
  let select_idx = sql.find("SELECT")
  let from_idx = sql.find("FROM")

  match select_idx {
    Some(s_idx) =>
      match from_idx {
        Some(f_idx) =>
          if f_idx > s_idx && f_idx > s_idx + 7 {
            // 使用 substring 需要确保索引正确
            let columns_part = extract_between(sql, s_idx + 7, f_idx)
            split_columns(columns_part)
          } else {
            []
          }
        None => []
      }
    None => []
  }
}

///|
/// 提取字符串两个索引之间的内容
fn extract_between(s : String, start : Int, end : Int) -> String {
  s[start:end].to_string()
}

///|
/// 分割列名
pub fn split_columns(s : String) -> Array[String] {
  // 简化实现：按逗号分割
  let result = []
  let mut current = ""
  let mut i = 0
  let len = s.length()

  while i < len {
    let c = s[i]
    // 字符串索引返回 UInt16，逗号的 ASCII 码是 44
    if c.to_int() == 44 {
      Array::append(result, [trim(current)])
      current = ""
    } else {
      current = current + s[i:i + 1].to_string()
    }
    i = i + 1
  }

  if current.length() > 0 {
    Array::append(result, [trim(current)])
  }

  result
}

///|
/// 去除字符串首尾空格
pub fn trim(s : String) -> String {
  let len = s.length()
  let mut start = 0
  let mut end = len

  // 找到第一个非空格字符
  while start < len {
    match s[start].to_char() {
      Some(c) => if is_space(c) { start = start + 1 } else { break }
      None => break
    }
  }

  // 找到最后一个非空格字符
  while end > start {
    match s[end - 1].to_char() {
      Some(c) => if is_space(c) { end = end - 1 } else { break }
      None => break
    }
  }

  extract_between(s, start, end)
}

///|
/// 检查字符是否为空格
fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
/// 从 Schema 推导列类型
fn infer_columns_type(
  schema : SchemaInfo,
  columns : Array[String],
) -> Array[(String, String)] {
  infer_columns_type_iter(schema, columns, [], 0)
}

///|
/// 迭代推导列类型
fn infer_columns_type_iter(
  schema : SchemaInfo,
  columns : Array[String],
  acc : Array[(String, String)],
  index : Int,
) -> Array[(String, String)] {
  let len = Array::length(columns)
  if index >= len {
    acc
  } else {
    let current = columns[index]
    let mb_type = guess_column_type(schema, current)
    Array::append(acc, [(trim(current), mb_type)])
    infer_columns_type_iter(schema, columns, acc, index + 1)
  }
}

///|
/// 猜测列类型（基于常见命名约定）
pub fn guess_column_type(_schema : SchemaInfo, column_name : String) -> String {
  let name_lower = to_lower_case(column_name)

  // 基于列名猜测类型
  if name_lower.has_suffix("_id") || name_lower.has_suffix("id") {
    "Int"
  } else if name_lower.has_prefix("is_") || name_lower.has_prefix("has_") {
    "Bool"
  } else if name_lower.contains("email") || name_lower.contains("name") {
    "String"
  } else if name_lower.contains("created_at") ||
    name_lower.contains("updated_at") {
    "String"
  } else if name_lower.contains("count") || name_lower.contains("amount") {
    "Int"
  } else if name_lower.contains("price") || name_lower.contains("rate") {
    "Double"
  } else {
    "String" // 默认为 String
  }
}

///|
/// 转换为小写
fn to_lower_case(s : String) -> String {
  // 简化实现：不进行实际转换
  // TODO: 使用标准库的小写转换函数
  s
}

///|
/// 生成结构体字段定义
pub fn gen_struct_fields(
  fields : Array[(String, String)],
  struct_name : String,
) -> String {
  gen_struct_fields_iter(
    fields,
    struct_name,
    "pub struct " + struct_name + " {\n",
    0,
  )
}

///|
/// 迭代生成字段定义
fn gen_struct_fields_iter(
  fields : Array[(String, String)],
  _struct_name : String,
  acc : String,
  index : Int,
) -> String {
  let len = Array::length(fields)
  if index >= len {
    acc + "\n}\n"
  } else {
    let current = fields[index]
    let (name, typ) = current
    let field_def = "  " + name + " : " + typ + "\n"
    gen_struct_fields_iter(fields, _struct_name, acc + field_def, index + 1)
  }
}
