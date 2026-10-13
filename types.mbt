// SQLite common types for MoonBit

///|
pub(all) enum SqlValue {
  Null
  Int(Int32)
  Int64(Int64)
  Double(Double)
  Text(Bytes)
  Blob(Bytes)
}
