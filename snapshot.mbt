///|
/// Create an interface file record for package-level snapshot APIs.
pub fn api_file(path : String, text : String) -> ApiFile {
  { path, text }
}

///|
/// Build a package-level API snapshot from named interface files.
pub fn build_api_snapshot(files : Array[ApiFile]) -> ApiSnapshot {
  let items : Array[ApiItem] = []
  let located_items : Array[LocatedApiItem] = []
  let diagnostics : Array[ApiDiagnostic] = []
  if files.is_empty() {
    diagnostics.push(
      make_diagnostic(
        "warning", "empty-file-list", "", "no interface files were provided",
      ),
    )
    return { items, diagnostics }
  }
  for file in files {
    if file.path.length() == 0 {
      diagnostics.push(
        make_diagnostic(
          "error", "empty-path", "", "interface file path must not be empty",
        ),
      )
      continue
    }
    let file_items = parse_interface_with_namespace(
      file.text,
      package_scope_from_path(file.path),
    )
    if file_items.is_empty() {
      diagnostics.push(
        make_diagnostic(
          "warning",
          "empty-interface",
          file.path,
          "interface file has no public API items",
        ),
      )
    }
    for item in file_items {
      items.push(item)
      located_items.push({ item, path: file.path })
    }
  }
  sort_located_items(located_items)
  for diagnostic in duplicate_item_diagnostics(located_items) {
    diagnostics.push(diagnostic)
  }
  sort_items(items)
  { items, diagnostics }
}

///|
fn make_diagnostic(
  severity : String,
  code : String,
  path : String,
  message : String,
) -> ApiDiagnostic {
  { severity, code, path, message }
}

///|
fn duplicate_item_diagnostics(
  items : Array[LocatedApiItem],
) -> Array[ApiDiagnostic] {
  let diagnostics : Array[ApiDiagnostic] = []
  let mut start = 0
  while start < items.length() {
    let located = items[start]
    let item = located.item
    let mut end = start + 1
    while end < items.length() && same_api_identity(items[end].item, item) {
      end += 1
    }
    let count = end - start
    if count > 1 {
      diagnostics.push(
        make_diagnostic(
          "error",
          "duplicate-symbol",
          located.path,
          "duplicate API item '\{item.kind} \{item.name}' appears \{count} times",
        ),
      )
    }
    start = end
  }
  diagnostics
}

///|
fn same_api_identity(left : ApiItem, right : ApiItem) -> Bool {
  left.kind == right.kind && left.name == right.name
}

///|
fn package_scope_from_path(path : String) -> String {
  let mut separator = -1
  for i in 0..<path.length() {
    let ch = path[i].unsafe_to_char()
    if ch == '/' || ch == '\\' {
      separator = i
    }
  }
  if separator < 0 {
    ""
  } else {
    path[:separator].replace(old="\\", new="/").to_owned()
  }
}

///|
fn sort_located_items(items : Array[LocatedApiItem]) -> Unit {
  items.sort_by(fn(a, b) {
    let order = compare_item_key(a.item, b.item)
    if order != 0 {
      order
    } else {
      a.path.compare(b.path)
    }
  })
}
