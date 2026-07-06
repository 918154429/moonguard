///|
fn read_file_raw(_path : String) -> String {
  read_error_prefix +
  "file input currently requires the JS backend; run with `moon run --target js cmd/main -- report old.mbti new.mbti`"
}

///|
fn list_interface_files_raw(_root : String) -> String {
  read_error_prefix +
  "directory input currently requires the JS backend; run with `moon run --target js cmd/main -- report-dir old_dir new_dir`"
}
