/// Codegen 2.0 - 从 Schema 生成 Query Builder 代码
/// 生成链式查询构建器

///|
/// 辅助函数：检查字段类型是否为 String
fn is_string_type(t : @schema.FieldType) -> Bool {
  match t {
    @schema.FieldType::String => true
    _ => false
  }
}

///|
/// 生成 Query Builder 结构定义
pub fn gen_query_builder_struct(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let query_builder_name = struct_name + "Query"

  let mut code = "/// " + query_builder_name + " 查询构建器\n"
  code = code + "/// 由 Orion Codegen 2.0 自动生成\n"
  code = code + "pub struct " + query_builder_name + " {\n"
  code = code + "  db : @runtime.Db\n"
  code = code + "  where_clauses : Array[String]\n"
  code = code + "  params : Array[@runtime.DbValue]\n"
  code = code + "  order_by : Option[String]\n"
  code = code + "  limit : Option[Int]\n"
  code = code + "  offset : Option[Int]\n"
  code = code + "}\n\n"
  code
}

///|
/// 生成 where_* 方法（为每个字段生成）
pub fn gen_where_methods(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let query_builder_name = struct_name + "Query"
  let mut code = ""

  for f in schema.fields {
    let field_name = f.name
    let method_name = "where_" + field_name
    let mb_type = field_type_to_moonbit(f.field_type)
    let db_value_converter = field_to_db_value_expr(f.field_type, "value")

    code = code + "/// WHERE " + field_name + " = ?\n"
    code = code +
      "pub fn " +
      query_builder_name +
      "::" +
      method_name +
      "(mut self, value : " +
      mb_type +
      ") -> Self {\n"
    code = code + "  self.where_clauses.push(\"" + field_name + " = ?\")\n"
    code = code + "  self.params.push(" + db_value_converter + ")\n"
    code = code + "  self\n"
    code = code + "}\n\n"
  }

  code
}

///|
/// 生成 where_*_like 方法（仅 String 字段）
pub fn gen_where_like_methods(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let query_builder_name = struct_name + "Query"
  let mut code = ""

  for f in schema.fields {
    if is_string_type(f.field_type) {
      let field_name = f.name

      code = code + "/// WHERE " + field_name + " LIKE ?\n"
      code = code +
        "pub fn " +
        query_builder_name +
        "::where_" +
        field_name +
        "_contains(mut self, pattern : String) -> Self {\n"
      code = code + "  self.where_clauses.push(\"" + field_name + " LIKE ?\")\n"
      code = code +
        "  self.params.push(@runtime.DbValue::String(\"%\" + pattern + \"%\"))\n"
      code = code + "  self\n"
      code = code + "}\n\n"

      code = code + "/// WHERE " + field_name + " LIKE ?%\n"
      code = code +
        "pub fn " +
        query_builder_name +
        "::where_" +
        field_name +
        "_starts_with(mut self, prefix : String) -> Self {\n"
      code = code + "  self.where_clauses.push(\"" + field_name + " LIKE ?\")\n"
      code = code +
        "  self.params.push(@runtime.DbValue::String(prefix + \"%\"))\n"
      code = code + "  self\n"
      code = code + "}\n\n"

      code = code + "/// WHERE " + field_name + " LIKE %?\n"
      code = code +
        "pub fn " +
        query_builder_name +
        "::where_" +
        field_name +
        "_ends_with(mut self, suffix : String) -> Self {\n"
      code = code + "  self.where_clauses.push(\"" + field_name + " LIKE ?\")\n"
      code = code +
        "  self.params.push(@runtime.DbValue::String(\"%\" + suffix))\n"
      code = code + "  self\n"
      code = code + "}\n\n"
    }
  }

  code
}

///|
/// 生成 order_by_* 方法
pub fn gen_order_by_methods(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let query_builder_name = struct_name + "Query"
  let mut code = ""

  for f in schema.fields {
    let field_name = f.name
    let method_name = "order_by_" + field_name

    code = code + "/// ORDER BY " + field_name + " [ASC|DESC]\n"
    code = code +
      "pub fn " +
      query_builder_name +
      "::" +
      method_name +
      "(mut self, desc : Bool = false) -> Self {\n"
    code = code +
      "  self.order_by = Some(\"" +
      field_name +
      " \" + (if desc { \"DESC\" } else { \"ASC\" }))\n"
    code = code + "  self\n"
    code = code + "}\n\n"
  }

  code
}

///|
/// 生成 limit 和 offset 方法
pub fn gen_limit_offset_methods(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let query_builder_name = struct_name + "Query"

  let mut code = "/// LIMIT n\n"
  code = code +
    "pub fn " +
    query_builder_name +
    "::limit(mut self, n : Int) -> Self {\n"
  code = code + "  self.limit = Some(n)\n"
  code = code + "  self\n"
  code = code + "}\n\n"

  code = code + "/// OFFSET n\n"
  code = code +
    "pub fn " +
    query_builder_name +
    "::offset(mut self, n : Int) -> Self {\n"
  code = code + "  self.offset = Some(n)\n"
  code = code + "  self\n"
  code = code + "}\n\n"

  code
}

///|
/// 生成 execute 方法
pub fn gen_execute_method(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let query_builder_name = struct_name + "Query"

  let select_columns = select_columns(schema)

  let mut code = "/// 执行查询，返回 List[" + struct_name + "]\n"
  code = code +
    "pub fn " +
    query_builder_name +
    "::execute(self) -> Result[List[" +
    struct_name +
    "], @runtime.DbError] {\n"
  code = code +
    "  let mut sql = \"SELECT " +
    select_columns +
    " FROM " +
    schema.name +
    "\"\n\n"

  code = code + "  if self.where_clauses.length() > 0 {\n"
  code = code +
    "    sql = sql + \" WHERE \" + String::join(self.where_clauses, \" AND \")\n"
  code = code + "  }\n\n"

  code = code + "  if self.order_by != None {\n"
  code = code + "    sql = sql + \" ORDER BY \" + self.order_by.unwrap()\"\n"
  code = code + "  }\n\n"

  code = code + "  if self.limit != None {\n"
  code = code +
    "    sql = sql + \" LIMIT \" + Int::to_string(self.limit.unwrap()\")\n"
  code = code + "  }\n\n"

  code = code + "  if self.offset != None {\n"
  code = code +
    "    sql = sql + \" OFFSET \" + Int::to_string(self.offset.unwrap()\")\n"
  code = code + "  }\n\n"

  code = code + "  match @runtime.query(self.db, sql, self.params) {\n"
  code = code + "    Ok(rows) => {\n"
  code = code + "      let mut result : List[" + struct_name + "] = []\n"
  code = code + "      for row in rows {\n"
  code = code + "        result.push(" + struct_name + "::from_row(row))\n"
  code = code + "      }\n"
  code = code + "      Ok(result)\n"
  code = code + "    }\n"
  code = code + "    Err(e) => Err(e)\n"
  code = code + "  }\n"
  code = code + "}\n\n"

  code
}

///|
/// 生成 first 方法（返回单条记录）
pub fn gen_first_method(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let query_builder_name = struct_name + "Query"

  let mut code = "/// 执行查询，返回单条结果\n"
  code = code +
    "pub fn " +
    query_builder_name +
    "::first(self) -> Result[Option[" +
    struct_name +
    "], @runtime.DbError] {\n"
  code = code + "  self.limit(1).execute().map(fn(list) => list.head())\n"
  code = code + "}\n\n"

  code
}

///|
/// 生成 count 方法
pub fn gen_count_method(schema : @schema.TableSchema) -> String {
  let query_builder_name = to_pascal_case(schema.name) + "Query"

  let mut code = "/// 执行 COUNT 查询\n"
  code = code +
    "pub fn " +
    query_builder_name +
    "::count(mut self) -> Result[Int, @runtime.DbError] {\n"
  code = code +
    "  let mut sql = \"SELECT COUNT(*) FROM " +
    schema.name +
    "\"\n\n"

  code = code + "  if self.where_clauses.length() > 0 {\n"
  code = code +
    "    sql = sql + \" WHERE \" + String::join(self.where_clauses, \" AND \")\n"
  code = code + "  }\n\n"

  code = code + "  match @runtime.query(self.db, sql, self.params) {\n"
  code = code + "    Ok(rows) => {\n"
  code = code + "      if rows.length() > 0 {\n"
  code = code + "        match rows[0] {\n"
  code = code + "          @runtime.DbValue::Int(count) => Ok(count)\n"
  code = code + "          _ => Ok(0)\n"
  code = code + "        }\n"
  code = code + "      } else {\n"
  code = code + "        Ok(0)\n"
  code = code + "      }\n"
  code = code + "    }\n"
  code = code + "    Err(e) => Err(e)\n"
  code = code + "  }\n"
  code = code + "}\n\n"

  code
}

///|
/// 生成完整的 Query Builder 代码
pub fn gen_full_query_builder(schema : @schema.TableSchema) -> String {
  let header = "// @generated by Orion Codegen 2.0\n// 请勿手动编辑此文件\n\n"
  header +
  gen_query_builder_struct(schema) +
  gen_new_query_function(schema) +
  gen_where_methods(schema) +
  gen_where_like_methods(schema) +
  gen_order_by_methods(schema) +
  gen_limit_offset_methods(schema) +
  gen_execute_method(schema) +
  gen_first_method(schema) +
  gen_count_method(schema)
}

///|
/// 生成 new_*_query 构造函数
pub fn gen_new_query_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let query_builder_name = struct_name + "Query"

  let mut code = "/// 创建 " + query_builder_name + " 实例\n"
  code = code +
    "pub fn new_" +
    to_snake_case(schema.name) +
    "_query(db : @runtime.Db) -> " +
    query_builder_name +
    " {\n"
  code = code + "  " + query_builder_name + " {\n"
  code = code + "    db,\n"
  code = code + "    where_clauses: [],\n"
  code = code + "    params: [],\n"
  code = code + "    order_by: None,\n"
  code = code + "    limit: None,\n"
  code = code + "    offset: None,\n"
  code = code + "  }\n"
  code = code + "}\n\n"
  code
}

///|
/// 字段值转 DbValue 表达式
fn field_to_db_value_expr(t : @schema.FieldType, name : String) -> String {
  match t {
    @schema.FieldType::Int => "@runtime.DbValue::Int(" + name + ")"
    @schema.FieldType::String => "@runtime.DbValue::String(" + name + ")"
    @schema.FieldType::Bool => "@runtime.DbValue::Bool(" + name + ")"
    @schema.FieldType::Float =>
      "@runtime.DbValue::Int(Float::to_int(" + name + "))"
    @schema.FieldType::DateTime => "@runtime.DbValue::String(" + name + ")"
    @schema.FieldType::Json => "@runtime.DbValue::String(" + name + ")"
    @schema.FieldType::Blob =>
      "@runtime.DbValue::String(String::from_bytes(" + name + "))"
  }
}
