/// 日志系统
/// 提供分级日志输出功能

///|
/// 日志级别
pub enum LogLevel {
  Debug
  Info
  Warn
  Error
}

///|
/// 日志记录器配置
pub struct LoggerConfig {
  min_level : LogLevel
  enabled : Bool
}

///|
/// 日志记录器
pub struct Logger {
  config : LoggerConfig
}

///|
/// 创建默认日志配置
pub fn make_default_config() -> LoggerConfig {
  { min_level: Info, enabled: true }
}

///|
/// 创建日志配置
pub fn make_config(min_level : LogLevel, enabled : Bool) -> LoggerConfig {
  { min_level, enabled }
}

///|
/// 创建日志记录器
pub fn make_logger(config : LoggerConfig) -> Logger {
  { config: config }
}

///|
/// 使用默认配置创建日志记录器
pub fn make_default_logger() -> Logger {
  make_logger(make_default_config())
}

///|
/// 检查是否应该记录该级别的日志
fn should_log(logger : Logger, level : LogLevel) -> Bool {
  if !logger.config.enabled {
    false
  } else {
    level_order(level) >= level_order(logger.config.min_level)
  }
}

///|
/// 获取日志级别的顺序值（用于比较）
fn level_order(level : LogLevel) -> Int {
  match level {
    LogLevel::Debug => 0
    LogLevel::Info => 1
    LogLevel::Warn => 2
    LogLevel::Error => 3
  }
}

///|
/// 格式化日志消息
fn format_message(level : LogLevel, message : String) -> String {
  let level_str = match level {
    LogLevel::Debug => "DEBUG"
    LogLevel::Info => "INFO"
    LogLevel::Warn => "WARN"
    LogLevel::Error => "ERROR"
  }
  "[" + level_str + "] " + message
}

///|
/// 记录调试日志
pub fn debug(logger : Logger, message : String) -> Unit {
  if should_log(logger, LogLevel::Debug) {
    println(format_message(LogLevel::Debug, message))
  } else {
    ()
  }
}

///|
/// 记录信息日志
pub fn info(logger : Logger, message : String) -> Unit {
  if should_log(logger, LogLevel::Info) {
    println(format_message(LogLevel::Info, message))
  } else {
    ()
  }
}

///|
/// 记录警告日志
pub fn warn(logger : Logger, message : String) -> Unit {
  if should_log(logger, LogLevel::Warn) {
    println(format_message(LogLevel::Warn, message))
  } else {
    ()
  }
}

///|
/// 记录错误日志
pub fn log_error(logger : Logger, message : String) -> Unit {
  if should_log(logger, LogLevel::Error) {
    println(format_message(LogLevel::Error, message))
  } else {
    ()
  }
}

///|
/// 启用日志记录器
pub fn enable(logger : Logger) -> Logger {
  let new_config = { min_level: logger.config.min_level, enabled: true }
  { config: new_config }
}

///|
/// 禁用日志记录器
pub fn disable(logger : Logger) -> Logger {
  let new_config = { min_level: logger.config.min_level, enabled: false }
  { config: new_config }
}

///|
/// 设置日志级别
pub fn set_level(logger : Logger, level : LogLevel) -> Logger {
  let new_config = { min_level: level, enabled: logger.config.enabled }
  { config: new_config }
}

///|
/// 检查日志记录器是否启用
pub fn is_enabled(logger : Logger) -> Bool {
  logger.config.enabled
}

///|
/// 获取当前日志级别
pub fn get_level(logger : Logger) -> LogLevel {
  logger.config.min_level
}
