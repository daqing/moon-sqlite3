// SQLite bindings for MoonBit (Wasm backend via moonrun host imports)
//
// The `moonbitlang/sqlite` host module is provided by moonrun. SQLite handles
// stay inside the host and are represented here as opaque 64-bit values; SQL
// and text cross the boundary as UTF-16, blobs as raw bytes.

// SQLite result codes

///|
const SQLITE_OK : Int32 = 0

///|
const SQLITE_ROW : Int32 = 100

///|
const SQLITE_DONE : Int32 = 101

// SQLite column types

///|
const SQLITE_INTEGER : Int32 = 1

///|
const SQLITE_FLOAT : Int32 = 2

///|
const SQLITE_TEXT : Int32 = 3

///|
const SQLITE_BLOB : Int32 = 4

///|
const SQLITE_NULL : Int32 = 5

// sqlite3_open_v2 flags

///|
const SQLITE_OPEN_READWRITE : Int32 = 0x00000002

///|
const SQLITE_OPEN_CREATE : Int32 = 0x00000004

// Host imports

///|
fn sqlite3_null_handle_import() -> UInt64 = "moonbitlang/sqlite" "sqlite3_null_handle"

///|
#unsafe_skip_stub_check
#borrow(filename, database)
fn sqlite3_open_v2_import(
  filename : Bytes,
  filename_length : Int32,
  database : Ref[UInt64],
  flags : Int32,
  vfs : UInt64,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_open_v2"

///|
fn sqlite3_errmsg16_length_import(database : UInt64) -> Int32 = "moonbitlang/sqlite" "sqlite3_errmsg16_length"

///|
#unsafe_skip_stub_check
#borrow(output)
fn sqlite3_errmsg16_import(
  database : UInt64,
  output : String,
  capacity : Int32,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_errmsg16"

///|
fn sqlite3_errcode_import(database : UInt64) -> Int32 = "moonbitlang/sqlite" "sqlite3_errcode"

///|
fn sqlite3_extended_errcode_import(database : UInt64) -> Int32 = "moonbitlang/sqlite" "sqlite3_extended_errcode"

///|
fn sqlite3_changes64_import(database : UInt64) -> Int64 = "moonbitlang/sqlite" "sqlite3_changes64"

///|
fn sqlite3_close_import(database : UInt64) -> Int32 = "moonbitlang/sqlite" "sqlite3_close"

///|
#unsafe_skip_stub_check
#borrow(sql, statement, tail)
fn sqlite3_prepare16_v2_import(
  database : UInt64,
  sql : String,
  sql_offset : Int32,
  sql_length : Int32,
  statement : Ref[UInt64],
  tail : Ref[Int32],
) -> Int32 = "moonbitlang/sqlite" "sqlite3_prepare16_v2"

///|
fn sqlite3_bind_null_import(statement : UInt64, index : Int32) -> Int32 = "moonbitlang/sqlite" "sqlite3_bind_null"

///|
fn sqlite3_bind_int64_import(
  statement : UInt64,
  index : Int32,
  value : Int64,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_bind_int64"

///|
fn sqlite3_bind_double_import(
  statement : UInt64,
  index : Int32,
  value : Double,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_bind_double"

///|
#unsafe_skip_stub_check
#borrow(value)
fn sqlite3_bind_text16_import(
  statement : UInt64,
  index : Int32,
  value : String,
  value_offset : Int32,
  value_length : Int32,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_bind_text16"

///|
#unsafe_skip_stub_check
#borrow(value)
fn sqlite3_bind_blob_import(
  statement : UInt64,
  index : Int32,
  value : Bytes,
  value_offset : Int32,
  value_length : Int32,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_bind_blob"

///|
fn sqlite3_step_import(statement : UInt64) -> Int32 = "moonbitlang/sqlite" "sqlite3_step"

///|
fn sqlite3_reset_import(statement : UInt64) -> Int32 = "moonbitlang/sqlite" "sqlite3_reset"

///|
fn sqlite3_finalize_import(statement : UInt64) -> Int32 = "moonbitlang/sqlite" "sqlite3_finalize"

///|
fn sqlite3_column_count_import(statement : UInt64) -> Int32 = "moonbitlang/sqlite" "sqlite3_column_count"

///|
fn sqlite3_column_name16_length_import(
  statement : UInt64,
  column : Int32,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_column_name16_length"

///|
#unsafe_skip_stub_check
#borrow(output)
fn sqlite3_column_name16_import(
  statement : UInt64,
  column : Int32,
  output : String,
  capacity : Int32,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_column_name16"

///|
fn sqlite3_column_type_import(statement : UInt64, column : Int32) -> Int32 = "moonbitlang/sqlite" "sqlite3_column_type"

///|
fn sqlite3_column_int64_import(statement : UInt64, column : Int32) -> Int64 = "moonbitlang/sqlite" "sqlite3_column_int64"

///|
fn sqlite3_column_double_import(statement : UInt64, column : Int32) -> Double = "moonbitlang/sqlite" "sqlite3_column_double"

///|
fn sqlite3_column_text16_length_import(
  statement : UInt64,
  column : Int32,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_column_text16_length"

///|
#unsafe_skip_stub_check
#borrow(output)
fn sqlite3_column_text16_import(
  statement : UInt64,
  column : Int32,
  output : String,
  capacity : Int32,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_column_text16"

///|
fn sqlite3_column_blob_length_import(
  statement : UInt64,
  column : Int32,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_column_blob_length"

///|
#unsafe_skip_stub_check
#borrow(output)
fn sqlite3_column_blob_import(
  statement : UInt64,
  column : Int32,
  output : FixedArray[Byte],
  capacity : Int32,
) -> Int32 = "moonbitlang/sqlite" "sqlite3_column_blob"

// Encoding helpers. The public API represents text as UTF-8 `Bytes`; the host
// ABI exchanges UTF-16 `String`s.

///|
fn string_to_bytes(s : String) -> Bytes {
  @encoding.encode(UTF8, s)
}

///|
fn bytes_to_string(bytes : Bytes) -> String {
  @encoding.decoder(UTF8).decode_lossy(bytes[:])
}

// High-level API

///|
pub struct Database {
  priv handle : UInt64
}

///|
fn is_null_handle(handle : UInt64) -> Bool {
  handle == sqlite3_null_handle_import()
}

///|
pub fn Database::open(path : String) -> Database? {
  let filename = string_to_bytes(path)
  let database = Ref(sqlite3_null_handle_import())
  let rescode = sqlite3_open_v2_import(
    filename,
    filename.length(),
    database,
    SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
    sqlite3_null_handle_import(),
  )
  if rescode != SQLITE_OK || is_null_handle(database.val) {
    None
  } else {
    Some({ handle: database.val, })
  }
}

///|
pub fn Database::close(self : Database) -> Unit {
  sqlite3_close_import(self.handle) |> ignore
}

///|
pub fn Database::exec(self : Database, sql : String) -> Bool {
  let sql_length = sql.length()
  let mut offset = 0
  let mut ok = true
  while offset < sql_length {
    let statement = Ref(sqlite3_null_handle_import())
    let tail = Ref(offset)
    let rescode = sqlite3_prepare16_v2_import(
      self.handle,
      sql,
      offset,
      sql_length - offset,
      statement,
      tail,
    )
    if rescode != SQLITE_OK {
      ok = false
      break
    }
    if is_null_handle(statement.val) {
      break
    }
    let mut rc = sqlite3_step_import(statement.val)
    while rc == SQLITE_ROW {
      rc = sqlite3_step_import(statement.val)
    }
    if rc != SQLITE_DONE {
      ok = false
    }
    sqlite3_finalize_import(statement.val) |> ignore
    let next = tail.val
    if next <= offset {
      break
    }
    offset = next
  }
  ok
}

///|
pub fn Database::prepare(self : Database, sql : String) -> Statement? {
  let statement = Ref(sqlite3_null_handle_import())
  let tail = Ref(0)
  let rescode = sqlite3_prepare16_v2_import(
    self.handle,
    sql,
    0,
    sql.length(),
    statement,
    tail,
  )
  if rescode != SQLITE_OK || is_null_handle(statement.val) {
    None
  } else {
    Some({ stmt: statement.val, done: false, })
  }
}

///|
pub fn Database::query(self : Database, sql : String) -> Statement? {
  self.prepare(sql)
}

///|
pub fn Database::errcode(self : Database) -> Int32 {
  sqlite3_errcode_import(self.handle)
}

///|
pub fn Database::errmsg(self : Database) -> Bytes {
  let length = sqlite3_errmsg16_length_import(self.handle)
  if length <= 0 {
    return b""
  }
  let output = String::make(length, '\u0000')
  let copied = sqlite3_errmsg16_import(self.handle, output, output.length())
  if copied != length {
    return b""
  }
  string_to_bytes(output)
}

///|
pub fn Database::extended_errcode(self : Database) -> Int32 {
  sqlite3_extended_errcode_import(self.handle)
}

///|
pub fn Database::changes(self : Database) -> Int32 {
  sqlite3_changes64_import(self.handle).to_int()
}

///|
pub fn Database::last_insert_rowid(self : Database) -> Int64 {
  match self.prepare("SELECT last_insert_rowid()") {
    Some(stmt) => {
      let mut result : Int64 = 0L
      if stmt.step() {
        result = stmt.column_int64(0)
      }
      stmt.finalize()
      result
    }
    None => 0L
  }
}

///|
pub fn Database::busy_timeout(self : Database, ms : Int32) -> Bool {
  let _ = self
  let _ = ms
  false
}

///|
pub fn Database::get_autocommit(self : Database) -> Bool {
  let _ = self
  true
}

///|
pub fn Database::total_changes(self : Database) -> Int32 {
  match self.prepare("SELECT total_changes()") {
    Some(stmt) => {
      let mut result : Int32 = 0
      if stmt.step() {
        result = stmt.column_int64(0).to_int()
      }
      stmt.finalize()
      result
    }
    None => 0
  }
}

// Transaction API

///|
pub fn Database::begin(self : Database) -> Bool {
  self.exec("BEGIN")
}

///|
pub fn Database::begin_immediate(self : Database) -> Bool {
  self.exec("BEGIN IMMEDIATE")
}

///|
pub fn Database::begin_exclusive(self : Database) -> Bool {
  self.exec("BEGIN EXCLUSIVE")
}

///|
pub fn Database::commit(self : Database) -> Bool {
  self.exec("COMMIT")
}

///|
pub fn Database::rollback(self : Database) -> Bool {
  self.exec("ROLLBACK")
}

///|
pub fn Database::savepoint(self : Database, name : String) -> Bool {
  self.exec("SAVEPOINT " + name)
}

///|
pub fn Database::release(self : Database, name : String) -> Bool {
  self.exec("RELEASE " + name)
}

///|
pub fn Database::rollback_to(self : Database, name : String) -> Bool {
  self.exec("ROLLBACK TO " + name)
}

///|
pub struct Statement {
  priv stmt : UInt64
  priv mut done : Bool
}

///|
pub fn Statement::step(self : Statement) -> Bool {
  if self.done {
    return false
  }
  let result = sqlite3_step_import(self.stmt)
  if result == SQLITE_ROW {
    true
  } else {
    self.done = true
    false
  }
}

///|
pub fn Statement::execute(self : Statement) -> Bool {
  let result = sqlite3_step_import(self.stmt)
  result == SQLITE_DONE || result == SQLITE_ROW
}

///|
fn Statement::column_int64(self : Statement, col : Int32) -> Int64 {
  sqlite3_column_int64_import(self.stmt, col)
}

///|
pub fn Statement::column_int(self : Statement, col : Int32) -> Int32 {
  self.column_int64(col).to_int()
}

///|
fn Statement::column_blob(self : Statement, col : Int32) -> Bytes {
  let length = sqlite3_column_blob_length_import(self.stmt, col)
  if length <= 0 {
    return b""
  }
  let output : FixedArray[Byte] = FixedArray::make(length, 0)
  let copied = sqlite3_column_blob_import(
    self.stmt,
    col,
    output,
    output.length(),
  )
  if copied != length {
    return b""
  }
  Bytes::from_array(output)
}

///|
pub fn Statement::column_text(self : Statement, col : Int32) -> Bytes {
  let length = sqlite3_column_text16_length_import(self.stmt, col)
  if length <= 0 {
    return b""
  }
  let output = String::make(length, '\u0000')
  let copied = sqlite3_column_text16_import(
    self.stmt,
    col,
    output,
    output.length(),
  )
  if copied != length {
    return b""
  }
  string_to_bytes(output)
}

///|
pub fn Statement::column_count(self : Statement) -> Int32 {
  sqlite3_column_count_import(self.stmt)
}

///|
/// Return the declared name of the `col`-th column in the result set.
/// Returns "" when `col` is out of range. Mirrors sqlite3_column_name.
pub fn Statement::column_name(self : Statement, col : Int32) -> String {
  if col < 0 || col >= sqlite3_column_count_import(self.stmt) {
    return ""
  }
  let length = sqlite3_column_name16_length_import(self.stmt, col)
  if length <= 0 {
    return ""
  }
  let output = String::make(length, '\u0000')
  let copied = sqlite3_column_name16_import(
    self.stmt,
    col,
    output,
    output.length(),
  )
  if copied != length {
    return ""
  }
  output
}

///|
pub fn Statement::bind(self : Statement, idx : Int32, value : SqlValue) -> Bool {
  let result = match value {
    Null => sqlite3_bind_null_import(self.stmt, idx)
    Int(v) => sqlite3_bind_int64_import(self.stmt, idx, v.to_int64())
    Int64(v) => sqlite3_bind_int64_import(self.stmt, idx, v)
    Double(v) => sqlite3_bind_double_import(self.stmt, idx, v)
    Text(b) => {
      let text = bytes_to_string(b)
      sqlite3_bind_text16_import(self.stmt, idx, text, 0, text.length())
    }
    Blob(b) => sqlite3_bind_blob_import(self.stmt, idx, b, 0, b.length())
  }
  result == SQLITE_OK
}

///|
pub fn Statement::bind_all(self : Statement, values : Array[SqlValue]) -> Bool {
  for i = 0; i < values.length(); i = i + 1 {
    if !self.bind(i + 1, values[i]) {
      return false
    }
  }
  true
}

///|
pub fn Statement::column(self : Statement, col : Int32) -> SqlValue {
  let col_type = sqlite3_column_type_import(self.stmt, col)
  match col_type {
    SQLITE_NULL => Null
    SQLITE_INTEGER => Int64(self.column_int64(col))
    SQLITE_FLOAT => Double(sqlite3_column_double_import(self.stmt, col))
    SQLITE_TEXT => Text(self.column_text(col))
    SQLITE_BLOB => Blob(self.column_blob(col))
    _ => Null
  }
}

///|
pub fn Statement::reset(self : Statement) -> Unit {
  sqlite3_reset_import(self.stmt) |> ignore
  self.done = false
}

///|
pub fn Statement::finalize(self : Statement) -> Unit {
  sqlite3_finalize_import(self.stmt) |> ignore
}

///|
pub fn Statement::iter(self : Statement) -> Iter[Statement] {
  self.reset()
  Iter::new(fn() { if self.step() { Some(self) } else { None } })
}
