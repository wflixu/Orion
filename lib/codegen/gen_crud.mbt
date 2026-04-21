/// Codegen 2.0 - 从 Schema 生成 CRUD 函数代码
/// 生成 create, findById, findAll, update, delete 等操作

///|
/// 生成 Mapper 结构定义
pub fn gen_mapper_struct(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let mapper_struct_name = struct_name + "Mapper"

  let mut code = "/// " + mapper_struct_name + " 数据访问对象\n"
  code = code + "/// 由 Orion Codegen 2.0 自动生成\n"
  code = code + "pub struct " + mapper_struct_name + " {\n"
  code = code + "  db : @runtime.Db\n"
  code = code + "}\n\n"
  code
}

///|
/// 生成 new_*_mapper 构造函数
pub fn gen_new_mapper_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let mapper_struct_name = struct_name + "Mapper"
  let func_name = "new_" + to_snake_case(schema.name) + "_mapper"

  let mut code = "/// 创建 " + mapper_struct_name + " 实例\n"
  code = code +
    "pub fn " +
    func_name +
    "(db : @runtime.Db) -> " +
    mapper_struct_name +
    " {\n"
  code = code + "  " + mapper_struct_name + " { db }\n"
  code = code + "}\n\n"
  code
}

///|
/// 生成 create 函数
pub fn gen_create_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let table_name = schema.name
  let func_name = "create_" + to_snake_case(schema.name)

  // 收集非自增字段
  let insertable_fields = []
  for f in schema.fields {
    if !@schema.field_is_auto_inc(f) {
      insertable_fields.push(f)
    }
  }

  // 生成参数字段和列名
  let mut params = ""
  let mut columns = ""
  let mut placeholders = ""
  let mut db_values = ""
  let mut first = true

  for f in insertable_fields {
    let mb_type = field_type_to_moonbit(f.field_type)
    if !first {
      params = params + ", "
      columns = columns + ", "
      placeholders = placeholders + ", "
      db_values = db_values + ", "
    }
    params = params + f.name + " : " + mb_type
    columns = columns + f.name
    placeholders = placeholders + "?"
    db_values = db_values + field_to_db_value(f.field_type, f.name)
    first = false
  }

  let mut code = "/// 创建 " + struct_name + " 记录\n"
  code = code + "/// @returns 最后插入的 ID\n"
  code = code +
    "pub fn " +
    func_name +
    "(self : " +
    to_pascal_case(schema.name) +
    "Mapper, " +
    params +
    ") -> Result[Int, @runtime.DbError] {\n"
  code = code +
    "  let sql = \"INSERT INTO " +
    table_name +
    " (" +
    columns +
    ") VALUES (" +
    placeholders +
    ")\"\n"
  code = code + "  @runtime.execute(self.db, sql, [" + db_values + "])\n"
  code = code + "}\n\n"
  code
}

///|
/// 生成 find_by_id 函数
pub fn gen_find_by_id_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let table_name = schema.name

  // 查找主键字段
  let pk_field = @schema.get_primary_key_field(schema)

  match pk_field {
    Some(pk) => {
      let pk_type = field_type_to_moonbit(pk.field_type)
      let func_name = "find_" + to_snake_case(schema.name) + "_by_id"

      let mut code = "/// 根据 ID 查找 " + struct_name + "\n"
      code = code +
        "pub fn " +
        func_name +
        "(self : " +
        struct_name +
        "Mapper, id : " +
        pk_type +
        ") -> Result[Option[" +
        struct_name +
        "], @runtime.DbError] {\n"
      code = code +
        "  let sql = \"SELECT " +
        select_columns(schema) +
        " FROM " +
        table_name +
        " WHERE " +
        pk.name +
        " = ?\"\n"
      code = code +
        "  match @runtime.query(self.db, sql, [" +
        field_to_db_value(pk.field_type, "id") +
        "]) {\n"
      code = code + "    Ok(rows) => {\n"
      code = code + "      if rows.length() > 0 {\n"
      code = code + "        Ok(Some(" + struct_name + "::from_row(rows[0])))\n"
      code = code + "      } else {\n"
      code = code + "        Ok(None)\n"
      code = code + "      }\n"
      code = code + "    }\n"
      code = code + "    Err(e) => Err(e)\n"
      code = code + "  }\n"
      code = code + "}\n\n"
      code
    }
    None =>
      "// 警告：没有找到主键字段，跳过 find_by_id 函数生成\n\n"
  }
}

///|
/// 生成 find_all 函数
pub fn gen_find_all_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let table_name = schema.name
  let func_name = "find_all_" + to_snake_case(schema.name)

  let mut code = "/// 查找所有 " + struct_name + " 记录\n"
  code = code +
    "pub fn " +
    func_name +
    "(self : " +
    struct_name +
    "Mapper) -> Result[List[" +
    struct_name +
    "], @runtime.DbError] {\n"
  code = code +
    "  let sql = \"SELECT " +
    select_columns(schema) +
    " FROM " +
    table_name +
    "\"\n"
  code = code + "  match @runtime.query(self.db, sql, []) {\n"
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
/// 生成 update 函数
pub fn gen_update_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let table_name = schema.name

  // 查找主键字段
  let pk_field = @schema.get_primary_key_field(schema)

  match pk_field {
    Some(pk) => {
      // 收集非主键且非自增的字段
      let updatable_fields = []
      for f in schema.fields {
        if !@schema.field_is_primary_key(f) && !@schema.field_is_auto_inc(f) {
          updatable_fields.push(f)
        }
      }

      // 生成 SET 子句
      let mut set_clause = ""
      let mut params = ""
      let mut db_values = ""
      let mut first = true

      for f in updatable_fields {
        let mb_type = field_type_to_moonbit(f.field_type)
        if !first {
          set_clause = set_clause + ", "
          params = params + ", "
          db_values = db_values + ", "
        }
        set_clause = set_clause + f.name + " = ?"
        params = params + f.name + " : " + mb_type
        db_values = db_values + field_to_db_value(f.field_type, f.name)
        first = false
      }

      let pk_type = field_type_to_moonbit(pk.field_type)
      let func_name = "update_" + to_snake_case(schema.name)

      let mut code = "/// 更新 " + struct_name + " 记录\n"
      code = code +
        "pub fn " +
        func_name +
        "(self : " +
        struct_name +
        "Mapper, id : " +
        pk_type +
        ", " +
        params +
        ") -> Result[Int, @runtime.DbError] {\n"
      code = code +
        "  let sql = \"UPDATE " +
        table_name +
        " SET " +
        set_clause +
        " WHERE " +
        pk.name +
        " = ?\"\n"
      code = code +
        "  @runtime.execute(self.db, sql, [" +
        db_values +
        ", " +
        field_to_db_value(pk.field_type, "id") +
        "])\n"
      code = code + "}\n\n"
      code
    }
    None =>
      "// 警告：没有找到主键字段，跳过 update 函数生成\n\n"
  }
}

///|
/// 生成 delete 函数
pub fn gen_delete_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let table_name = schema.name

  // 查找主键字段
  let pk_field = @schema.get_primary_key_field(schema)

  match pk_field {
    Some(pk) => {
      let pk_type = field_type_to_moonbit(pk.field_type)
      let func_name = "delete_" + to_snake_case(schema.name) + "_by_id"

      let mut code = "/// 删除 " + struct_name + " 记录\n"
      code = code +
        "pub fn " +
        func_name +
        "(self : " +
        struct_name +
        "Mapper, id : " +
        pk_type +
        ") -> Result[Int, @runtime.DbError] {\n"
      code = code +
        "  let sql = \"DELETE FROM " +
        table_name +
        " WHERE " +
        pk.name +
        " = ?\"\n"
      code = code +
        "  @runtime.execute(self.db, sql, [" +
        field_to_db_value(pk.field_type, "id") +
        "])\n"
      code = code + "}\n\n"
      code
    }
    None =>
      "// 警告：没有找到主键字段，跳过 delete 函数生成\n\n"
  }
}

///|
/// 生成完整的 CRUD 代码
pub fn gen_full_crud(schema : @schema.TableSchema) -> String {
  let header = "// @generated by Orion Codegen 2.0\n// 请勿手动编辑此文件\n\n"
  header +
  gen_mapper_struct(schema) +
  gen_new_mapper_function(schema) +
  gen_create_function(schema) +
  gen_find_by_id_function(schema) +
  gen_find_all_function(schema) +
  gen_update_function(schema) +
  gen_delete_function(schema)
}

///|
/// 获取 SELECT 列名列表
pub fn select_columns(schema : @schema.TableSchema) -> String {
  let columns = []
  for f in schema.fields {
    columns.push(f.name)
  }
  join_strings(columns, ", ")
}

///|
/// 连接字符串数组
pub fn join_strings(arr : Array[String], sep : String) -> String {
  let len = Array::length(arr)
  if len == 0 {
    ""
  } else if len == 1 {
    arr[0]
  } else {
    let mut result = arr[0]
    let mut i = 1
    while i < len {
      result = result + sep + arr[i]
      i += 1
    }
    result
  }
}

///|
/// 字段值转 DbValue
pub fn field_to_db_value(t : @schema.FieldType, name : String) -> String {
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
