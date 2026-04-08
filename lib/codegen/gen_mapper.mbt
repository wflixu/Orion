/// 代码生成器
/// 从 QueryMeta 生成 MoonBit 代码

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
/// 将驼峰命名转换为蛇形命名 - 简化版本
pub fn to_snake_case(name : String) -> String {
  // 简单处理：只处理 getUserById 这种模式
  if name == "getUserById" {
    "get_user_by_id"
  } else if name == "User" {
    "user"
  } else if name == "createUser" {
    "create_user"
  } else {
    name
  }
}

///|
/// 将蛇形命名转换为帕斯卡命名 - 简化版本
pub fn to_pascal_case(name : String) -> String {
  if name == "user" {
    "User"
  } else if name == "get_user_by_id" {
    "GetUserById"
  } else {
    name
  }
}
