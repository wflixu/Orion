/// Schema DSL 约束定义
/// 表约束和索引定义

///|
/// 字段约束类型
pub enum Constraint {
  PrimaryKey
  AutoInc
  NotNull
  Unique
  Default(String)
  MaxLength(Int)
  Index
  ForeignKey(String, String)
} derive(Eq)

///|
/// 创建主键约束
pub fn primary_key() -> Constraint {
  Constraint::PrimaryKey
}

///|
/// 创建自增约束
pub fn auto_inc() -> Constraint {
  Constraint::AutoInc
}

///|
/// 创建非空约束
pub fn not_null() -> Constraint {
  Constraint::NotNull
}

///|
/// 创建唯一约束
pub fn unique() -> Constraint {
  Constraint::Unique
}

///|
/// 创建默认值约束
pub fn default(value : String) -> Constraint {
  Constraint::Default(value)
}

///|
/// 创建最大长度约束
pub fn max_length(n : Int) -> Constraint {
  Constraint::MaxLength(n)
}

///|
/// 创建索引约束
pub fn index() -> Constraint {
  Constraint::Index
}

///|
/// 创建外键约束
pub fn foreign_key(table : String, column : String) -> Constraint {
  Constraint::ForeignKey(table, column)
}

///|
/// 索引定义
pub struct IndexDef {
  name : String
  columns : Array[String]
  unique : Bool
}

///|
/// 创建索引定义
pub fn make_index(
  name : String,
  columns : Array[String],
  unique : Bool,
) -> IndexDef {
  { name, columns, unique }
}

///|
/// 创建唯一索引
pub fn make_unique_index(name : String, columns : Array[String]) -> IndexDef {
  { name, columns, unique: true }
}

///|
/// 创建普通索引
pub fn make_normal_index(name : String, columns : Array[String]) -> IndexDef {
  { name, columns, unique: false }
}

///|
/// 获取索引名称
pub fn index_name(idx : IndexDef) -> String {
  idx.name
}

///|
/// 获取索引列
pub fn index_columns(idx : IndexDef) -> Array[String] {
  idx.columns
}

///|
/// 检查索引是否为唯一索引
pub fn index_is_unique(idx : IndexDef) -> Bool {
  idx.unique
}

///|
/// 约束验证结果
pub struct ConstraintValidationResult {
  valid : Bool
  errors : Array[String]
}

///|
/// 创建验证通过结果
pub fn constraint_valid() -> ConstraintValidationResult {
  { valid: true, errors: [] }
}

///|
/// 创建验证失败结果
pub fn constraint_invalid(errors : Array[String]) -> ConstraintValidationResult {
  { valid: false, errors }
}

///|
/// 验证约束组合是否合法
/// 例如：AutoInc 必须与 PrimaryKey 一起使用
pub fn validate_constraints(
  constraints : Array[Constraint],
) -> ConstraintValidationResult {
  let errors = []

  let mut has_auto_inc = false
  let mut has_primary_key = false

  for c in constraints {
    match c {
      Constraint::AutoInc => has_auto_inc = true
      Constraint::PrimaryKey => has_primary_key = true
      _ => ()
    }
  }

  // AutoInc 必须与 PrimaryKey 一起使用
  if has_auto_inc && !has_primary_key {
    errors.push("AutoInc must be used with PrimaryKey")
  }

  if Array::length(errors) > 0 {
    constraint_invalid(errors)
  } else {
    constraint_valid()
  }
}
