# Project CLAUDE.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

## Native Target

This project targets **native** (not wasm-gc). All build and test commands must include `--target native`.

### C FFI (Foreign Function Interface)

This project uses C language bindings via MoonBit's C-FFI feature.

**Key files:**
- `stub.c` - C wrapper functions that MoonBit calls via `extern "C"`
- `moon.pkg` - Contains `options("native-stub": ["stub.c"])` to include a C source

**How it works:**
1. MoonBit declares external C functions: `extern "C" fn name(args) -> Type = "c_func_name"`
2. C implementations are provided in `stub.c`
3. `moon build --target native` compiles MoonBit to C, then links with `stub.c`

**Commands:**
```bash
moon build --target native   # Build executable
moon run . --target native   # Run the program
moon test --target native    # Run tests
moon bench --target native   # Run benchmarks
```

**Type mapping (MoonBit → C):**
- `Int32` → `int32_t`
- `Int64` → `int64_t`
- `Double` → `double`
- `Bool` → `int32_t` (0/1)
- `Unit` → `void`

## Project Structure

- MoonBit packages are organized per directory. Each directory contains a `moon.pkg` file listing its dependencies. Each package has its files and blackbox test files (ending in `_test.mbt`) and whitebox test files (ending in `_wbtest.mbt`).

- In the top-level directory, there is a `moon.mod` file with module information and metadata. The `moon.work` workspace manifest lists the root module (`.`) and the `example` module so the example can depend on the library through a local workspace member.

## Coding Convention

- MoonBit code is organized in block style. Each block is separated by `///|`, and the order of blocks is irrelevant. In some refactorings, you can process block by block independently.

- Try to keep deprecated blocks in a file called `deprecated.mbt` in each directory.

## Tooling

- `moon fmt` - Format your code properly.

- `moon info` - Update the generated interface of the package. Each package has a generated interface file `.mbti`, which is a brief formal description of the package. If nothing in `.mbti` changes, your change does not bring visible changes to external package users - typically a safe refactoring.

- In the last step, run `moon info && moon fmt` to update the interface and format the code. Check the diffs of `.mbti` file to see if the changes are expected.

- `moon test` - Check if tests pass. MoonBit supports snapshot testing, so when your changes affect the behavior, run `moon test --update` to update the snapshot.

- `moon check` - Check if the code is linted correctly.

- When writing tests, use `inspect` and run `moon test --update` to update snapshots. Only use assertions like `assert_eq` when you are in loops where each snapshot may vary. You can use `moon coverage analyze > uncovered.log` to see which parts of your code are not covered by tests.

- CLAUDE.md has some small tasks that are easy for AI to pick up. Agents are welcome to finish the tasks and check the box when done.

## Resolved Issues

### Native FFI string returns - SOLVED ✅

Returning a raw `const char*` from a stub as `moonbit_bytes_t` is undefined
behavior: `Bytes` is a length-prefixed MoonBit heap object, so MoonBit reads a
header in front of the pointer and may try to release it. This showed up as an
intermittent SIGSEGV that landed later, in unrelated test-driver code.

- Affected stubs: `sqlite_errstr`, `sqlite_bind_parameter_name`, `sqlite_errmsg`,
  `sqlite_sql`, `sqlite_db_filename`, `sqlite_expanded_sql`, `sqlite_column_name`.
- Fix: copy every returned C string into a fresh `moonbit_make_bytes(len, 0)`
  buffer before returning (see `cstring_to_bytes` in `stub.c`).
- Note: the earlier "copy into a global static buffer" fix still handed back a
  raw pointer, so it only masked the bug.

### Lessons Learned

**Best practices for string handling in MoonBit C FFI:**

1. **Never return a raw C pointer as `Bytes`.** For every `extern "C" fn ... -> Bytes`
   whose C side has a `const char*`, copy the bytes into `moonbit_make_bytes`.
   Use the `cstring_to_bytes` helper in `stub.c`.

2. **NULL / empty handling.** When the source can be NULL, return an empty
   `moonbit_make_bytes(0, 0)` and only `memcpy` when `len > 0`.

3. **Free dynamic sources after copying.** `sqlite3_expanded_sql` returns memory
   that must be `sqlite3_free`d after the copy.

## Writing Benchmarks

See: https://docs.moonbitlang.com/en/latest/language/benchmarks.html

Benchmark files should be named `*_wbtest.mbt` or `*_test.mbt` and use the `@bench.T` parameter in test blocks.
