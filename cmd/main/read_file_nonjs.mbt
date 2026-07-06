///|
fn read_file_raw(_path : String) -> String {
  read_error_prefix +
  "file input currently requires the JS backend; run with `moon run --target js cmd/main -- report old.mbti new.mbti`"
}
