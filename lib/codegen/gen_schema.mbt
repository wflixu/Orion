/// Codegen 2.0 - 从 Schema 生成 Struct 代码
/// 生成 Struct 定义、工厂函数和 FromJson/ToJson 实现

///|
/// 字段类型转 MoonBit 类型
pub fn field_type_to_moonbit(t : @schema.FieldType) -> String {
  match t {
    @schema.FieldType::Int => "Int"
    @schema.FieldType::String => "String"
    @schema.FieldType::Bool => "Bool"
    @schema.FieldType::Float => "Float"
    @schema.FieldType::DateTime => "String"
    @schema.FieldType::Json => "String"
    @schema.FieldType::Blob => "Array[Byte]"
  }
}

///|
/// 生成 make_* 工厂函数（所有字段）
pub fn gen_make_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let func_name = "make_" + to_snake_case(schema.name)

  // 生成参数列表
  let mut params = ""
  let mut struct_init = ""
  let mut first = true

  for f in schema.fields {
    let mb_type = field_type_to_moonbit(f.field_type)
    if !first {
      params = params + ", "
      struct_init = struct_init + ",\n    "
    }
    params = params + f.name + " : " + mb_type
    struct_init = struct_init + f.name + ""
    first = false
  }

  let mut code = "/// 创建 " + struct_name + " 实例（所有字段）\n"
  code = code +
    "pub fn " +
    func_name +
    "(" +
    params +
    ") -> " +
    struct_name +
    " {\n"
  code = code + "  " + struct_name + " {\n    " + struct_init + "\n  }\n"
  code = code + "}\n\n"
  code
}

///|
/// 生成 CreateInput 结构（仅必填字段，省略自增字段）
pub fn gen_create_input_struct(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let input_struct_name = "Create" + struct_name + "Input"

  let mut code = "/// 创建 " +
    struct_name +
    " 的输入结构（仅必填字段）\n"
  code = code + "pub struct " + input_struct_name + " {\n"

  let mut has_fields = false
  for f in schema.fields {
    // 跳过自增字段
    if @schema.field_is_auto_inc(f) {
      continue
    }
    // 跳过有默认值的字段
    if @schema.field_has_default(f) {
      continue
    }

    let mb_type = field_type_to_moonbit(f.field_type)
    code = code + "  " + f.name + " : " + mb_type + ",\n"
    has_fields = true
  }

  if !has_fields {
    code = code + "  _dummy : Unit, // 占位字段\n"
  }

  code = code + "}\n\n"
  code
}

///|
/// 生成 create_*_input 工厂函数
pub fn gen_create_input_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let input_struct_name = "Create" + struct_name + "Input"
  let func_name = "create_" + to_snake_case(schema.name) + "_input"

  // 生成参数列表
  let mut params = ""
  let mut struct_init = ""
  let mut first = true

  for f in schema.fields {
    if @schema.field_is_auto_inc(f) {
      continue
    }
    if @schema.field_has_default(f) {
      continue
    }

    let mb_type = field_type_to_moonbit(f.field_type)
    if !first {
      params = params + ", "
      struct_init = struct_init + ",\n    "
    }
    params = params + f.name + " : " + mb_type
    struct_init = struct_init + f.name + ""
    first = false
  }

  if params == "" {
    params = "_dummy : Unit"
    struct_init = "_dummy"
  }

  let mut code = "/// 创建 " + input_struct_name + " 实例\n"
  code = code +
    "pub fn " +
    func_name +
    "(" +
    params +
    ") -> " +
    input_struct_name +
    " {\n"
  code = code + "  " + input_struct_name + " {\n    " + struct_init + "\n  }\n"
  code = code + "}\n\n"
  code
}

///|
/// 生成 FromRow 转换函数
pub fn gen_from_row_function(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let func_name = struct_name + "::from_row"

  let mut code = "/// 从数据库行转换\n"
  code = code +
    "pub fn " +
    func_name +
    "(row : Array[@runtime.DbValue]) -> " +
    struct_name +
    " {\n"
  code = code + "  " + struct_name + " {\n"

  let mut i = 0
  let field_count = Array::length(schema.fields)
  let mut has_fields = false

  for f in schema.fields {
    let mb_type = field_type_to_moonbit(f.field_type)
    let converter = db_value_converter(f.field_type, i)
    code = code + "    " + f.name + " : " + converter
    if i < field_count - 1 {
      code = code + ",\n"
    } else {
      code = code + "\n"
    }
    i += 1
    has_fields = true
  }

  if !has_fields {
    code = code + "    // 无字段\n"
  }

  code = code + "  }\n"
  code = code + "}\n\n"
  code
}

///|
/// 生成 DbValue 转换器
fn db_value_converter(t : @schema.FieldType, idx : Int) -> String {
  let idx_str = Int::to_string(idx)
  match t {
    @schema.FieldType::Int =>
      "match row[" +
      idx_str +
      "] {\n      @runtime.DbValue::Int(v) => v\n      _ => 0\n    }"
    @schema.FieldType::String =>
      "match row[" +
      idx_str +
      "] {\n      @runtime.DbValue::String(v) => v\n      _ => \"\"\n    }"
    @schema.FieldType::Bool =>
      "match row[" +
      idx_str +
      "] {\n      @runtime.DbValue::Bool(v) => v\n      _ => false\n    }"
    @schema.FieldType::Float =>
      "match row[" +
      idx_str +
      "] {\n      @runtime.DbValue::Int(v) => Float::from_int(v)\n      @runtime.DbValue::String(v) => Float::from_string(v).unwrap_or(0.0)\n      _ => 0.0\n    }"
    @schema.FieldType::DateTime =>
      "match row[" +
      idx_str +
      "] {\n      @runtime.DbValue::String(v) => v\n      _ => \"\"\n    }"
    @schema.FieldType::Json =>
      "match row[" +
      idx_str +
      "] {\n      @runtime.DbValue::String(v) => v\n      _ => \"\"\n    }"
    @schema.FieldType::Blob =>
      "match row[" +
      idx_str +
      "] {\n      @runtime.DbValue::String(v) => String::to_bytes(v)\n      _ => []\n    }"
  }
}

///|
/// 生成完整的 Struct 代码（包含所有辅助函数）
pub fn gen_full_struct(schema : @schema.TableSchema) -> String {
  let header = "// @generated by Orion Codegen 2.0\n// 请勿手动编辑此文件\n\n"
  header +
  gen_struct_code(schema) +
  gen_make_function(schema) +
  gen_create_input_struct(schema) +
  gen_create_input_function(schema) +
  gen_from_row_function(schema)
}

///|
/// 生成 Struct 定义代码
fn gen_struct_code(schema : @schema.TableSchema) -> String {
  let struct_name = to_pascal_case(schema.name)
  let mut code = "/// " + struct_name + " 数据模型\n"
  code = code + "/// 由 Orion Codegen 2.0 自动生成\n"
  code = code + "#[derive(Eq, Hash, FromJson, ToJson, Show)]\n"
  code = code + "pub struct " + struct_name + " {\n"

  for f in schema.fields {
    let mb_type = field_type_to_moonbit(f.field_type)
    code = code + "  " + f.name + " : " + mb_type + ",\n"
  }

  code = code + "}\n\n"
  code
}
