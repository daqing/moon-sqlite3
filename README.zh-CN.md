# moon-sqlite3

MoonBit 的 SQLite 数据库绑定 —— 支持 **native**（C FFI）、**JavaScript**（Node.js）和 **Wasm**（moonrun）三种目标。

## 特性

- 数据库管理（打开、关闭）
- 执行 SQL
- 基于 `SqlValue` 枚举的类型安全预编译语句
- 通过 `bind_all()` 进行数组式参数绑定
- 通过 `iter()` 进行迭代器式结果遍历
- 事务支持（BEGIN、COMMIT、ROLLBACK、SAVEPOINT）
- UTF-8 文本编码
- 跨目标兼容（native、js、wasm）

## 环境要求

### Native 目标

- libsqlite3
  - Ubuntu：`apt install libsqlite3-dev`
  - macOS：系统自带

### JavaScript 目标

- Node.js 22.5.0+（需要内置的 `node:sqlite` 模块）

### Wasm 目标

- 提供 moonrun `moonbitlang/sqlite` 导入的 Wasm 宿主。MoonBit CLI 自带的 `moonrun` 运行时已内置 SQLite，因此 `moon test --target wasm` 开箱即用。

## 安装

```bash
moon add daqing/moon-sqlite3
```

在你的 `moon.pkg` 中添加：

```
import {
  "daqing/moon-sqlite3" @sqlite,
}

options(
  link: { "native": { "cc-link-flags": "-lsqlite3" } },
)
```

## 用法

```moonbit
let db = match @sqlite.Database::open(":memory:") {
  Some(d) => d
  None => {
    println("Failed to open database")
    return
  }
}

// 建表
db.exec("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")

// 用 bind_all() 插入数据
match db.prepare("INSERT INTO users (name, age) VALUES (?, ?)") {
  Some(stmt) => {
    stmt.bind_all([Text(string_to_bytes("Alice")), Int(30)]) |> ignore
    stmt.execute() |> ignore
    stmt.finalize()
  }
  None => println("Failed to prepare statement")
}

// 用迭代器查询
match db.query("SELECT id, name, age FROM users") {
  Some(stmt) => {
    for row in stmt.iter() {
      let id = row.column_int(0)
      let age = row.column_int(2)
      println("id=\{id}, age=\{age}")
    }
    stmt.finalize()
  }
  None => println("Failed to prepare statement")
}

db.close()
```

## 构建与测试

```bash
# Native 目标
moon build --target native
moon test --target native

# JavaScript 目标
moon build --target js
moon test --target js

# Wasm 目标
moon build --target wasm
moon test --target wasm
```

## API

### 高层 API

**数据库操作：**
- `Database::open(path: String) -> Database?` - 打开数据库
- `Database::close(self)` - 关闭数据库
- `Database::exec(self, sql: String) -> Bool` - 执行 SQL
- `Database::prepare(self, sql: String) -> Statement?` - 预编译语句
- `Database::query(self, sql: String) -> Statement?` - 预编译 SELECT 语句

**事务 API：**
- `Database::begin(self) -> Bool` - 开启事务
- `Database::begin_immediate(self) -> Bool` - 开启 IMMEDIATE 事务
- `Database::begin_exclusive(self) -> Bool` - 开启 EXCLUSIVE 事务
- `Database::commit(self) -> Bool` - 提交事务
- `Database::rollback(self) -> Bool` - 回滚事务
- `Database::savepoint(self, name: String) -> Bool` - 创建保存点
- `Database::release(self, name: String) -> Bool` - 释放保存点
- `Database::rollback_to(self, name: String) -> Bool` - 回滚到保存点

**语句操作：**
- `Statement::bind(idx: Int, value: SqlValue) -> Bool` - 绑定单个参数
- `Statement::bind_all(values: Array[SqlValue]) -> Bool` - 一次性绑定全部参数
- `Statement::execute() -> Bool` - 执行 INSERT/UPDATE/DELETE
- `Statement::step() -> Bool` - 前进到下一行（用于 SELECT）
- `Statement::column(col: Int) -> SqlValue` - 以 SqlValue 读取列值
- `Statement::column_int(col: Int) -> Int` - 以 Int 读取列值
- `Statement::column_text(col: Int) -> Bytes` - 以 Bytes 读取列值
- `Statement::column_count() -> Int` - 获取列数
- `Statement::iter() -> Iter[Statement]` - 为查询结果创建迭代器
- `Statement::reset()` - 重置语句
- `Statement::finalize()` - 结束语句

**SqlValue 枚举：**
```moonbit
pub enum SqlValue {
  Null
  Int(Int)
  Int64(Int64)
  Double(Double)
  Text(Bytes)
  Blob(Bytes)
}
```

### 目标兼容性

| API | Native | JS | Wasm | 说明 |
|-----|--------|-----|------|-------|
| `Database::open` | ✅ | ✅ | ✅ | |
| `Database::close` | ✅ | ✅ | ✅ | |
| `Database::exec` | ✅ | ✅ | ✅ | |
| `Database::prepare` | ✅ | ✅ | ✅ | |
| `Database::query` | ✅ | ✅ | ✅ | |
| `Database::begin` | ✅ | ✅ | ✅ | |
| `Database::commit` | ✅ | ✅ | ✅ | |
| `Database::rollback` | ✅ | ✅ | ✅ | |
| `Database::savepoint` | ✅ | ✅ | ✅ | |
| `Database::changes` | ✅ | ✅ | ✅ | JS/Wasm 在需要时回退到 SQL |
| `Database::last_insert_rowid` | ✅ | ✅ | ✅ | JS/Wasm 使用 `SELECT last_insert_rowid()` |
| `Database::total_changes` | ✅ | ✅ | ✅ | JS/Wasm 使用 `SELECT total_changes()` |
| `Database::errcode` | ✅ | ⚠️ | ✅ | JS 始终返回 0 |
| `Database::errmsg` | ✅ | ⚠️ | ✅ | JS 始终返回空 |
| `Database::extended_errcode` | ✅ | ⚠️ | ✅ | JS 始终返回 0 |
| `Database::busy_timeout` | ✅ | ⚠️ | ⚠️ | JS/Wasm 始终返回 false |
| `Database::get_autocommit` | ✅ | ⚠️ | ⚠️ | JS/Wasm 始终返回 true |
| `Statement::bind` | ✅ | ✅ | ✅ | |
| `Statement::bind_all` | ✅ | ✅ | ✅ | |
| `Statement::execute` | ✅ | ✅ | ✅ | |
| `Statement::step` | ✅ | ✅ | ✅ | |
| `Statement::column` | ✅ | ✅ | ✅ | 整数类型存在差异（见下） |
| `Statement::column_int` | ✅ | ✅ | ✅ | |
| `Statement::column_text` | ✅ | ✅ | ✅ | |
| `Statement::column_count` | ✅ | ✅ | ✅ | |
| `Statement::iter` | ✅ | ✅ | ✅ | |
| `Statement::reset` | ✅ | ✅ | ✅ | |
| `Statement::finalize` | ✅ | ✅ | ✅ | |

### 已知差异

1. **整数列类型**：通过 `column()` 读取整数列时，Native 和 Wasm 返回 `Int64`，JS 返回 `Int`。

2. **Int64 绑定**：Node.js SQLite 不支持把 BigInt 作为绑定参数，Int64 值会被转换成 Number（超大整数可能丢失精度）。Wasm 精确绑定 `Int64`。

3. **错误处理**：JS 目标的错误信息有限，需要配合 try-catch 使用。

4. **底层 API**：Native 目标暴露底层 C FFI 函数（如 `sqlite_*`），JS 与 Wasm 目标不提供。Wasm 目标改为通过 moonrun 的 `moonbitlang/sqlite` 宿主导入访问 SQLite。

## 许可证

MIT License
