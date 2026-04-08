/// 代码生成器
/// 从 QueryMeta 生成 MoonBit 代码

///|
/// SQL 类型到 MoonBit 类型的映射
pub fn sql_type_to_moonbit(sql_type : String) -> String {
  let lower = sql_type.to_lower()
  if lower.contains("int") || lower.contains("integer") {
    "Int"
  } else if lower.contains("bool") || lower.contains("tinyint") {
    "Bool"
  } else if lower.contains("text") ||
    lower.contains("char") ||
    lower.contains("varchar") {
    "String"
  } else {
    "String" // 默认类型
  }
}

///|
/// 从 SQL SELECT 语句推断字段
pub fn infer_fields_from_sql(sql : String) -> Array[(String, String)] {
  // 提取 SELECT 和 FROM 之间的部分
  let upper_sql = sql.to_upper()
  let select_idx = upper_sql.find("SELECT")
  let from_idx = upper_sql.find("FROM")

  match (select_idx, from_idx) {
    (Some(sel), Some(frm)) => {
      let columns_part_start = sel + 6 // "SELECT".length()
      if columns_part_start >= frm {
        []
      } else {
        let columns_part = sql[columns_part_start:frm].trim().to_string()
        parse_columns(columns_part)
      }
    }
    _ => []
  }
}

///|
/// 解析列定义
fn parse_columns(columns_str : String) -> Array[(String, String)] {
  if columns_str.trim() == "*" {
    [] // 通配符，无法推断
  } else {
    let fields : Array[(String, String)] = []
    let parts = columns_str.split(",")
    for part in parts {
      let trimmed = part.trim().to_string()
      // 处理 "column AS alias" 或 "table.column"
      let field_name = extract_field_name(trimmed)
      if field_name != "" {
        fields.push((field_name, "String")) // 默认类型，后续可从 schema 推断
      }
    }
    fields
  }
}

///|
/// 从列表达式提取字段名
fn extract_field_name(expr : String) -> String {
  // 处理 "AS alias"
  let upper = expr.to_upper()
  let as_idx = upper.find(" AS ")
  match as_idx {
    Some(idx) => {
      let alias_part = expr[idx + 4:].trim().to_string()
      alias_part
    }
    None => {
      // 处理 "table.column" 或 "column"
      let dot_idx = expr.find(".")
      match dot_idx {
        Some(idx) => expr[idx + 1:].trim().to_string()
        None => expr.trim().to_string()
      }
    }
  }
}

///|
/// 生成 Struct 定义
pub fn gen_struct(name : String, fields : Array[(String, String)]) -> String {
  let mut code = "struct " + name + " {\n"
  for field in fields {
    code = code + "  " + field.0 + " : " + field.1 + "\n"
  }
  code = code + "}\n\n"
  code
}

///|
/// 从 SQL 生成结构体定义
pub fn gen_struct_from_sql(name : String, sql : String) -> String {
  let fields = infer_fields_from_sql(sql)
  gen_struct(name, fields)
}

///|
/// 生成 From DbValue 映射函数
pub fn gen_from_db_value(
  struct_name : String,
  fields : Array[(String, String)],
) -> String {
  let mut code = "fn " +
    to_snake_case(struct_name) +
    "_from_db_value(row : Array[@runtime.DbValue]) -> " +
    struct_name +
    " {\n"
  code = code + "  {\n"
  let mut i = 0
  for field in fields {
    let field_type = field.1
    let converter = if field_type == "Int" {
      "match row[" +
      Int::to_string(i) +
      "] {\n      @runtime.DbValue::Int(v) => v\n      _ => 0\n    }"
    } else if field_type == "String" {
      "match row[" +
      Int::to_string(i) +
      "] {\n      @runtime.DbValue::String(v) => v\n      _ => \"\"\n    }"
    } else if field_type == "Bool" {
      "match row[" +
      Int::to_string(i) +
      "] {\n      @runtime.DbValue::Bool(v) => v\n      _ => false\n    }"
    } else {
      "row[" + Int::to_string(i) + "]"
    }
    code = code + "    " + field.0 + ": " + converter
    if i < Array::length(fields) - 1 {
      code = code + ",\n"
    } else {
      code = code + "\n"
    }
    i += 1
  }
  code = code + "  }\n}\n\n"
  code
}

///|
/// 生成函数代码
pub fn gen_function(query : @parser.QueryMeta, struct_name : String) -> String {
  let func_name = to_snake_case(query.name)
  let sql = query.sql

  // 根据 result_type 生成不同的返回类型和实现
  let (result_type_str, return_expr) = match query.result_type {
    @parser.ResultType::Single =>
      (
        "Result[Option[" + struct_name + "], @runtime.DbError]",
        "let rows = rows\n      if Array::length(rows) > 0 {\n        Some(" +
        struct_name +
        "_from_db_value(rows[0]))\n      } else {\n        None\n      }",
      )
    @parser.ResultType::Many =>
      (
        "Result[List[" + struct_name + "], @runtime.DbError]",
        "let mut result : List[" +
        struct_name +
        "] = []\n      for row in rows {\n        result.push(" +
        struct_name +
        "_from_db_value(row))\n      }\n      result",
      )
    @parser.ResultType::LastInsertId =>
      (
        "Result[Int, @runtime.DbError]", "let rows = rows\n      if Array::length(rows) > 0 {\n        match rows[0] {\n          @runtime.DbValue::Int(id) => Ok(id)\n          _ => Ok(0)\n        }\n      } else {\n        Ok(0)\n      }",
      )
    @parser.ResultType::AffectedRows =>
      ("Result[Int, @runtime.DbError]", "@runtime.execute(db, sql, params)")
  }

  // 生成参数列表
  let params = gen_params(query.param_count)

  // 生成函数
  let mut code = "pub fn " + func_name + "(db : @runtime.Db"
  if !params.is_empty() {
    code = code + ", " + params
  }
  code = code + ") -> " + result_type_str + " {\n"
  code = code + "  let sql = \"" + sql + "\"\n"
  code = code + "  let params : Array[@runtime.DbValue] = ["

  // 生成参数数组
  let mut param_list = ""
  let mut i = 0
  while i < query.param_count {
    if i > 0 {
      param_list = param_list + ", "
    }
    param_list = param_list + "param_" + Int::to_string(i)
    i += 1
  }
  code = code + param_list + "]\n"

  if @parser.is_affected_rows(query.result_type) {
    code = code + "  " + return_expr + "\n"
  } else {
    code = code + "  match @runtime.query(db, sql, params) {\n"
    code = code + "    Ok(rows) => {\n      " + return_expr + "\n    }\n"
    code = code + "    Err(e) => Err(e)\n  }\n"
  }
  code = code + "}\n\n"

  code
}

///|
/// 生成参数列表
fn gen_params(count : Int) -> String {
  if count == 0 {
    ""
  } else {
    let mut params = ""
    let mut i = 0
    while i < count {
      if i > 0 {
        params = params + ", "
      }
      params = params + "param_" + Int::to_string(i) + " : DbValue"
      i += 1
    }
    params
  }
}

///|
/// 将驼峰命名转换为蛇形命名
/// 例如：getUserById -> get_user_by_id
pub fn to_snake_case(name : String) -> String {
  if name.length() == 0 {
    return ""
  }

  let mut result = ""
  let mut i = 0
  let len = name.length()

  while i < len {
    let c_int = name[i]
    let c = c_int.to_char()
    match c {
      Some(ch) =>
        // Check if uppercase
        if ch >= 'A' && ch <= 'Z' {
          let lower_int = ch.to_int() + 32
          match lower_int.to_char() {
            Some(lower_ch) =>
              if i > 0 {
                result = result + "_" + lower_ch.to_string()
              } else {
                result = result + lower_ch.to_string()
              }
            None => result = result + ch.to_string()
          }
        } else {
          result = result + ch.to_string()
        }
      None => ()
    }
    i += 1
  }

  result
}

///|
/// 将蛇形命名转换为帕斯卡命名
/// 例如：get_user_by_id -> GetUserById
pub fn to_pascal_case(name : String) -> String {
  if name.length() == 0 {
    return ""
  }

  let mut result = ""
  let mut capitalize_next = true
  let mut i = 0
  let len = name.length()

  while i < len {
    let c_int = name[i]
    let c = c_int.to_char()
    match c {
      Some(ch) =>
        if ch == '_' {
          capitalize_next = true
        } else if capitalize_next && ch >= 'a' && ch <= 'z' {
          // Convert to uppercase
          let upper_int = ch.to_int() - 32
          match upper_int.to_char() {
            Some(upper_ch) => {
              result = result + upper_ch.to_string()
              capitalize_next = false
            }
            None => {
              result = result + ch.to_string()
              capitalize_next = false
            }
          }
        } else {
          result = result + ch.to_string()
          capitalize_next = false
        }
      None => ()
    }
    i += 1
  }

  result
}
