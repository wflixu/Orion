/// 动态 SQL 构建器
/// 支持条件性 SQL 片段组装

///|
/// SQL 条件
pub enum SqlCondition {
  /// 等于
  Equal(String, String)
  /// 不等于
  NotEqual(String, String)
  /// 大于
  GreaterThan(String, String)
  /// 小于
  LessThan(String, String)
  /// LIKE 查询
  Like(String, String)
  /// IN 查询
  In(String, Array[String])
  /// IS NULL
  IsNull(String)
  /// IS NOT NULL
  IsNotNull(String)
  /// AND 组合
  And(Array[SqlCondition])
  /// OR 组合
  Or(Array[SqlCondition])
  /// NOT
  Not(SqlCondition)
  /// 原始 SQL
  Raw(String)
}

///|
/// SQL 排序
pub struct SqlOrder {
  column : String
  ascending : Bool
}

///|
/// 创建排序
pub fn make_order(column : String, ascending : Bool) -> SqlOrder {
  { column, ascending }
}

///|
/// SQL 查询构建器
pub struct SqlBuilder {
  base_query : String
  conditions : Array[SqlCondition]
  order_by : Array[SqlOrder]
  limit : Int?
  offset : Int?
}

///|
/// 创建 SQL 构建器
pub fn make_sql_builder(base_query : String) -> SqlBuilder {
  { base_query, conditions: [], order_by: [], limit: None, offset: None }
}

///|
/// 添加条件
pub fn where_clause(
  builder : SqlBuilder,
  condition : SqlCondition,
) -> SqlBuilder {
  Array::append(builder.conditions, [condition])
  {
    base_query: builder.base_query,
    conditions: builder.conditions,
    order_by: builder.order_by,
    limit: builder.limit,
    offset: builder.offset,
  }
}

///|
/// 添加排序
pub fn order_by(builder : SqlBuilder, order : SqlOrder) -> SqlBuilder {
  Array::append(builder.order_by, [order])
  {
    base_query: builder.base_query,
    conditions: builder.conditions,
    order_by: builder.order_by,
    limit: builder.limit,
    offset: builder.offset,
  }
}

///|
/// 设置限制
pub fn limit(builder : SqlBuilder, n : Int) -> SqlBuilder {
  {
    base_query: builder.base_query,
    conditions: builder.conditions,
    order_by: builder.order_by,
    limit: Some(n),
    offset: builder.offset,
  }
}

///|
/// 设置偏移
pub fn offset(builder : SqlBuilder, n : Int) -> SqlBuilder {
  {
    base_query: builder.base_query,
    conditions: builder.conditions,
    order_by: builder.order_by,
    limit: builder.limit,
    offset: Some(n),
  }
}

///|
/// 构建 SQL 查询
pub fn build(builder : SqlBuilder) -> String {
  let mut result = builder.base_query

  // 添加 WHERE 子句
  let len = Array::length(builder.conditions)
  if len > 0 {
    result = result + " WHERE "
    result = result + build_conditions(builder.conditions)
  }

  // 添加 ORDER BY 子句
  let order_len = Array::length(builder.order_by)
  if order_len > 0 {
    result = result + " ORDER BY "
    result = result + build_order_by(builder.order_by)
  }

  // 添加 LIMIT
  match builder.limit {
    Some(n) => result = result + " LIMIT " + n.to_string()
    None => ()
  }

  // 添加 OFFSET
  match builder.offset {
    Some(n) => result = result + " OFFSET " + n.to_string()
    None => ()
  }

  result
}

///|
/// 构建条件字符串
fn build_conditions(conditions : Array[SqlCondition]) -> String {
  build_conditions_iter(conditions, "", 0)
}

///|
/// 迭代构建条件
fn build_conditions_iter(
  conditions : Array[SqlCondition],
  acc : String,
  index : Int,
) -> String {
  let len = Array::length(conditions)
  if index >= len {
    acc
  } else {
    let current = conditions[index]
    let condition_str = build_condition(current)
    let separator = if index == 0 { "" } else { " AND " }
    let new_acc = acc + separator + condition_str
    build_conditions_iter(conditions, new_acc, index + 1)
  }
}

///|
/// 构建单个条件
fn build_condition(condition : SqlCondition) -> String {
  match condition {
    SqlCondition::Equal(col, val) => col + " = " + val
    SqlCondition::NotEqual(col, val) => col + " != " + val
    SqlCondition::GreaterThan(col, val) => col + " > " + val
    SqlCondition::LessThan(col, val) => col + " < " + val
    SqlCondition::Like(col, val) => col + " LIKE " + val
    SqlCondition::In(col, values) => {
      let values_str = build_in_values(values, "", 0)
      col + " IN (" + values_str + ")"
    }
    SqlCondition::IsNull(col) => col + " IS NULL"
    SqlCondition::IsNotNull(col) => col + " IS NOT NULL"
    SqlCondition::And(conds) => {
      let inner = build_conditions_iter(conds, "", 0)
      "(" + inner + ")"
    }
    SqlCondition::Or(conds) => {
      let inner = build_or_conditions(conds, "", 0)
      "(" + inner + ")"
    }
    SqlCondition::Not(cond) => {
      let inner = build_condition(cond)
      "NOT " + inner
    }
    SqlCondition::Raw(sql) => sql
  }
}

///|
/// 构建 OR 条件
fn build_or_conditions(
  conditions : Array[SqlCondition],
  acc : String,
  index : Int,
) -> String {
  let len = Array::length(conditions)
  if index >= len {
    acc
  } else {
    let current = conditions[index]
    let condition_str = build_condition(current)
    let separator = if index == 0 { "" } else { " OR " }
    let new_acc = acc + separator + condition_str
    build_or_conditions(conditions, new_acc, index + 1)
  }
}

///|
/// 构建 IN 值列表
fn build_in_values(values : Array[String], acc : String, index : Int) -> String {
  let len = Array::length(values)
  if index >= len {
    acc
  } else {
    let current = values[index]
    let separator = if index == 0 { "" } else { ", " }
    let new_acc = acc + separator + current
    build_in_values(values, new_acc, index + 1)
  }
}

///|
/// 构建排序字符串
fn build_order_by(orders : Array[SqlOrder]) -> String {
  build_order_by_iter(orders, "", 0)
}

///|
/// 迭代构建排序
fn build_order_by_iter(
  orders : Array[SqlOrder],
  acc : String,
  index : Int,
) -> String {
  let len = Array::length(orders)
  if index >= len {
    acc
  } else {
    let current = orders[index]
    let direction = if current.ascending { " ASC" } else { " DESC" }
    let order_str = current.column + direction
    let separator = if index == 0 { "" } else { ", " }
    let new_acc = acc + separator + order_str
    build_order_by_iter(orders, new_acc, index + 1)
  }
}

///|
/// 条件构建器辅助函数
pub fn equal(column : String, value : String) -> SqlCondition {
  SqlCondition::Equal(column, value)
}

///|
pub fn not_equal(column : String, value : String) -> SqlCondition {
  SqlCondition::NotEqual(column, value)
}

///|
pub fn greater_than(column : String, value : String) -> SqlCondition {
  SqlCondition::GreaterThan(column, value)
}

///|
pub fn less_than(column : String, value : String) -> SqlCondition {
  SqlCondition::LessThan(column, value)
}

///|
pub fn like(column : String, pattern : String) -> SqlCondition {
  SqlCondition::Like(column, pattern)
}

///|
pub fn in_list(column : String, values : Array[String]) -> SqlCondition {
  SqlCondition::In(column, values)
}

///|
pub fn is_null(column : String) -> SqlCondition {
  SqlCondition::IsNull(column)
}

///|
pub fn is_not_null(column : String) -> SqlCondition {
  SqlCondition::IsNotNull(column)
}

///|
pub fn sql_and(conditions : Array[SqlCondition]) -> SqlCondition {
  SqlCondition::And(conditions)
}

///|
pub fn sql_or(conditions : Array[SqlCondition]) -> SqlCondition {
  SqlCondition::Or(conditions)
}

///|
pub fn sql_not(condition : SqlCondition) -> SqlCondition {
  SqlCondition::Not(condition)
}

///|
pub fn raw_sql(sql : String) -> SqlCondition {
  SqlCondition::Raw(sql)
}
