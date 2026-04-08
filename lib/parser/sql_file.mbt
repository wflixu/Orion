/// SQL 文件解析器
/// 解析 .sql 文件的元数据（name, description, result type, SQL 语句）

///|
/// 返回类型枚举
pub enum ResultType {
  Single
  Many
  LastInsertId
  AffectedRows
}

///|
/// 检查 ResultType 是否为 AffectedRows
pub fn is_affected_rows(t : ResultType) -> Bool {
  match t {
    ResultType::AffectedRows => true
    _ => false
  }
}

///|
/// SQL 查询的元数据
pub struct QueryMeta {
  name : String
  description : String?
  result_type : ResultType
  sql : String
  param_count : Int
  is_dynamic : Bool
}

///|
/// 解析 SQL 文件
/// 返回 QueryMeta 数组
pub fn parse_sql_file(content : String) -> Result[Array[QueryMeta], String] {
  let queries : Array[QueryMeta] = []
  let mut current_name : String? = None
  let mut current_description : String? = None
  let mut current_result : String? = None
  let mut current_sql_lines : Array[String] = []
  let mut in_sql = false

  for line in content.split("\n") {
    let trimmed = line.trim()

    // 检查是否是注释行
    if trimmed.has_prefix("--") {
      let comment_content = trimmed[2:].trim()

      if comment_content.has_prefix("name:") {
        // 保存之前的查询
        match current_name {
          Some(name) => {
            let sql = Array::join(current_sql_lines, "\n")
            let sql_trimmed = sql.trim()
            if !sql_trimmed.is_empty() {
              let result_type = match current_result {
                Some("single") => ResultType::Single
                Some("many") => ResultType::Many
                Some("last_insert_id") => ResultType::LastInsertId
                Some("affected_rows") => ResultType::AffectedRows
                Some(r) => return Err("Invalid result type: " + r)
                None => return Err("Missing result type for query: " + name)
              }
              queries.push({
                name,
                description: current_description,
                result_type,
                sql: sql_trimmed.to_string(),
                param_count: count_params(sql_trimmed.to_string()),
                is_dynamic: sql_trimmed.contains("[@if"),
              })
            }
          }
          None => ()
        }
        // 开始新查询
        current_name = Some(comment_content[5:].trim().to_string())
        current_description = None
        current_result = None
        current_sql_lines = []
        in_sql = true
      } else if comment_content.has_prefix("description:") {
        current_description = Some(comment_content[12:].trim().to_string())
      } else if comment_content.has_prefix("result:") {
        current_result = Some(comment_content[7:].trim().to_string())
      }
    } else if in_sql && !trimmed.is_empty() {
      current_sql_lines.push(trimmed.to_string())
    }
  }

  // 保存最后一个查询
  match current_name {
    Some(name) => {
      let sql = Array::join(current_sql_lines, "\n")
      let sql_trimmed = sql.trim()
      if !sql_trimmed.is_empty() {
        let result_type = match current_result {
          Some("single") => ResultType::Single
          Some("many") => ResultType::Many
          Some("last_insert_id") => ResultType::LastInsertId
          Some("affected_rows") => ResultType::AffectedRows
          Some(r) => return Err("Invalid result type: " + r)
          None => return Err("Missing result type for query: " + name)
        }
        queries.push({
          name,
          description: current_description,
          result_type,
          sql: sql_trimmed.to_string(),
          param_count: count_params(sql_trimmed.to_string()),
          is_dynamic: sql_trimmed.contains("[@if"),
        })
      }
    }
    None => return Err("No queries found in file")
  }

  Ok(queries)
}

///|
/// 统计 SQL 中的参数数量
/// 支持？和 $1, $2... 风格
fn count_params(sql : String) -> Int {
  // 统计？的数量
  let mut question_count = 0
  for c in sql {
    if c == '?' {
      question_count += 1
    }
  }

  // 统计 $N 风格的参数
  let mut max_dollar = 0
  let len = sql.length()
  let mut i = 0

  while i < len {
    let c = sql[i]
    if c == '$' && i + 1 < len {
      let mut num = 0
      let mut j = i + 1
      let mut has_digit = false
      while j < len {
        let cj = sql[j]
        if cj >= '0' && cj <= '9' {
          has_digit = true
          num = num * 10 + (cj.to_int() - '0'.to_int())
          j += 1
        } else {
          break
        }
      }
      if has_digit && num > max_dollar {
        max_dollar = num
      }
      i = j
    } else {
      i += 1
    }
  }

  if max_dollar > 0 {
    max_dollar
  } else {
    question_count
  }
}
