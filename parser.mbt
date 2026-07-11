///|
/// Parse a MoonBit interface file into a normalized public API list.
pub fn parse_interface(text : String) -> Array[ApiItem] {
  let items : Array[ApiItem] = []
  let parse_legacy_associated_items = is_legacy_moon_info_interface(text)
  let mut container_kind = ""
  let mut container_name = ""
  let mut pending_attributes : Array[String] = []
  for raw_line in split_lines(text[:]) {
    let line = normalize_space(strip_comment(raw_line).trim())
    if line.length() == 0 {
      pending_attributes = []
      continue
    }
    if line.has_prefix("#") {
      pending_attributes.push(line)
      continue
    }
    if container_kind.length() > 0 {
      if line.has_prefix("}") {
        for item in parse_closing_derives(container_name, line[:]) {
          items.push(item)
        }
        container_kind = ""
        container_name = ""
        pending_attributes = []
        continue
      }
      if !is_public_line(line[:]) {
        match
          parse_container_item(
            container_kind,
            container_name,
            line[:],
            pending_attributes,
          ) {
          Some(item) => items.push(item)
          None => ()
        }
        pending_attributes = []
        continue
      }
      container_kind = ""
      container_name = ""
    }
    if !is_public_line(line[:]) {
      match parse_interface_item(line[:], pending_attributes) {
        Some(item) => {
          items.push(item)
          for derive_item in parse_closing_derives(item.name, line[:]) {
            items.push(derive_item)
          }
        }
        None =>
          if parse_legacy_associated_items {
            match parse_legacy_generated_item(line[:], pending_attributes) {
              Some(item) => items.push(item)
              None => ()
            }
          }
      }
      pending_attributes = []
      continue
    }
    match parse_public_item(line[:], pending_attributes) {
      Some(item) => {
        if opens_public_container(item.kind, line[:]) {
          container_kind = item.kind
          container_name = item.name
        }
        items.push(item)
        for
          inline_item in parse_inline_container_items(
            item.kind,
            item.name,
            line[:],
          ) {
          items.push(inline_item)
        }
        for derive_item in parse_closing_derives(item.name, line[:]) {
          items.push(derive_item)
        }
      }
      None => ()
    }
    pending_attributes = []
  }
  sort_items(items)
  items
}

///|
fn is_legacy_moon_info_interface(text : String) -> Bool {
  text.contains("Generated using `moon info`") && text.contains("package \"")
}

///|
/// Parse a MoonBit interface file and namespace every public API name.
pub fn parse_interface_with_namespace(
  text : String,
  scope : String,
) -> Array[ApiItem] {
  let items = parse_interface(text)
  if scope.length() == 0 {
    return items
  }
  let namespaced : Array[ApiItem] = []
  for item in items {
    namespaced.push({
      kind: item.kind,
      name: "\{scope}::\{item.name}",
      signature: item.signature,
    })
  }
  sort_items(namespaced)
  namespaced
}

///|
fn parse_interface_item(
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  if line.has_prefix("type ") {
    Some(make_type_item(line.view(start_offset=5), attributes))
  } else {
    None
  }
}

///|
fn parse_legacy_generated_item(
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  if line.has_prefix("fn ") {
    Some(
      make_item_with_visibility(
        "fn",
        line.view(start_offset=3),
        "pub",
        attributes,
      ),
    )
  } else if line.has_prefix("fn[") {
    Some(
      make_item_with_visibility(
        "fn",
        line.view(start_offset=2),
        "pub",
        attributes,
      ),
    )
  } else if line.has_prefix("async fn ") || line.has_prefix("async fn[") {
    Some(make_item_with_visibility("fn", line, "pub", attributes))
  } else if line.has_prefix("impl ") {
    Some(make_impl_item(line.view(start_offset=5), "pub", attributes))
  } else if line.has_prefix("impl[") {
    Some(make_impl_item(line.view(start_offset=4), "pub", attributes))
  } else {
    None
  }
}

///|
fn parse_public_item(line : StringView, attributes : Array[String]) -> ApiItem? {
  let public_body = public_body(line)
  let visibility = public_visibility(line)
  if public_body.length() == 0 {
    return None
  }
  if public_body.has_prefix("fn ") {
    Some(
      make_item_with_visibility(
        "fn",
        public_body.view(start_offset=3),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("fn[") {
    Some(
      make_item_with_visibility(
        "fn",
        public_body.view(start_offset=2),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("async fn ") {
    Some(make_item_with_visibility("fn", public_body, visibility, attributes))
  } else if public_body.has_prefix("async fn[") {
    Some(make_item_with_visibility("fn", public_body, visibility, attributes))
  } else if public_body.has_prefix("typealias ") {
    Some(
      make_item_with_visibility(
        "typealias",
        public_body.view(start_offset=10),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("type ") {
    Some(
      make_type_item_with_visibility(
        public_body.view(start_offset=5),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("struct ") {
    Some(
      make_container_item_with_visibility(
        "struct",
        public_body.view(start_offset=7),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("enum ") {
    Some(
      make_container_item_with_visibility(
        "enum",
        public_body.view(start_offset=5),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("trait ") {
    Some(
      make_container_item_with_visibility(
        "trait",
        public_body.view(start_offset=6),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("impl ") {
    Some(
      make_impl_item(public_body.view(start_offset=5), visibility, attributes),
    )
  } else if public_body.has_prefix("impl[") {
    Some(
      make_impl_item(public_body.view(start_offset=4), visibility, attributes),
    )
  } else if public_body.has_prefix("let ") {
    Some(
      make_item_with_visibility(
        "let",
        public_body.view(start_offset=4),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("const ") {
    Some(
      make_item_with_visibility(
        "const",
        public_body.view(start_offset=6),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("suberror ") {
    Some(
      make_container_item_with_visibility(
        "suberror",
        public_body.view(start_offset=9),
        visibility,
        attributes,
      ),
    )
  } else if public_body.has_prefix("using ") {
    Some(
      make_using_item(public_body.view(start_offset=6), visibility, attributes),
    )
  } else {
    Some(make_unknown_item(public_body, visibility, attributes))
  }
}

///|
fn make_type_item(body : StringView, attributes : Array[String]) -> ApiItem {
  let signature = normalize_signature(strip_inline_derive(body))
  {
    kind: "type",
    name: extract_name(signature[:]),
    signature: apply_attributes(signature, attributes),
  }
}

///|
fn make_type_item_with_visibility(
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(strip_inline_derive(body))
  {
    kind: "type",
    name: extract_name(signature[:]),
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn make_item_with_visibility(
  kind : String,
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  {
    kind,
    name: extract_name(signature[:]),
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn make_container_item_with_visibility(
  kind : String,
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(container_declaration(body))
  {
    kind,
    name: extract_name(signature[:]),
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn container_declaration(body : StringView) -> StringView {
  match body.find("{") {
    Some(index) => body.view(start_offset=0, end_offset=index).trim()
    None => strip_inline_derive(body)
  }
}

///|
fn make_named_item_with_attributes(
  kind : String,
  name : String,
  body : StringView,
  attributes : Array[String],
) -> ApiItem {
  {
    kind,
    name,
    signature: apply_attributes(normalize_signature(body), attributes),
  }
}

///|
fn make_impl_item(
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  let name = trim_leading_generic_params(signature[:]).to_owned()
  {
    kind: "impl",
    name,
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn make_using_item(
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  {
    kind: "using",
    name: extract_using_name(signature[:]),
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn make_unknown_item(
  body : StringView,
  visibility : String,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  {
    kind: "unknown",
    name: signature,
    signature: apply_attributes(
      apply_visibility(signature, visibility),
      attributes,
    ),
  }
}

///|
fn parse_container_item(
  kind : String,
  parent : String,
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  if line.has_prefix("#") || line.has_prefix("priv ") {
    return None
  }
  if kind == "struct" {
    parse_struct_field(parent, line, attributes)
  } else if kind == "enum" || kind == "suberror" {
    parse_constructor(parent, line, attributes)
  } else if kind == "trait" {
    parse_trait_method(parent, line, attributes)
  } else {
    None
  }
}

///|
fn parse_inline_container_items(
  kind : String,
  parent : String,
  line : StringView,
) -> Array[ApiItem] {
  let items : Array[ApiItem] = []
  if !is_public_container_kind(kind) || !has_close_brace(line) {
    return items
  }
  match brace_body(line) {
    Some(body) =>
      for part in split_inline_container_members(body) {
        let part = part.trim()
        if part.length() > 0 {
          match parse_container_item(kind, parent, part, []) {
            Some(item) => items.push(item)
            None => ()
          }
        }
      }
    None => ()
  }
  items
}

///|
fn split_inline_container_members(text : StringView) -> Array[StringView] {
  let parts : Array[StringView] = []
  let mut start = 0
  let mut round_depth = 0
  let mut square_depth = 0
  let mut curly_depth = 0
  for i in 0..<text.length() {
    let ch = text.unsafe_get(i).unsafe_to_char()
    if ch == '(' {
      round_depth += 1
    } else if ch == ')' {
      round_depth -= 1
    } else if ch == '[' {
      square_depth += 1
    } else if ch == ']' {
      square_depth -= 1
    } else if ch == '{' {
      curly_depth += 1
    } else if ch == '}' {
      curly_depth -= 1
    } else if (ch == ',' || ch == ';') &&
      round_depth == 0 &&
      square_depth == 0 &&
      curly_depth == 0 {
      parts.push(text.view(start_offset=start, end_offset=i))
      start = i + 1
    }
  }
  parts.push(text.view(start_offset=start, end_offset=text.length()))
  parts
}

///|
fn parse_struct_field(
  parent : String,
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  match line.find(":") {
    Some(_) => {
      let field_name = extract_field_name(line)
      if field_name.length() == 0 {
        None
      } else {
        Some(
          make_named_item_with_attributes(
            "field",
            "\{parent}.\{field_name}",
            line,
            attributes,
          ),
        )
      }
    }
    None => None
  }
}

///|
fn parse_constructor(
  parent : String,
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  let signature = normalize_signature(line)
  if signature.length() == 0 {
    None
  } else {
    let name = extract_name(signature[:])
    if name.length() == 0 {
      None
    } else {
      Some({
        kind: "constructor",
        name: "\{parent}.\{name}",
        signature: apply_attributes(signature, attributes),
      })
    }
  }
}

///|
fn parse_closing_derives(parent : String, line : StringView) -> Array[ApiItem] {
  let items : Array[ApiItem] = []
  match derive_body(line) {
    Some(body) =>
      for trait_name in split_top_level_commas(body) {
        let trait_name = trait_name.trim()
        if trait_name.length() > 0 {
          let signature = "derive(\{normalize_signature(trait_name)})"
          items.push({
            kind: "derive",
            name: "\{parent}.\{normalize_signature(trait_name)}",
            signature,
          })
        }
      }
    None => ()
  }
  items
}

///|
fn derive_body(line : StringView) -> StringView? {
  match line.find("derive(") {
    Some(start) => {
      let body_start = start + 7
      let mut depth = 1
      for i in body_start..<line.length() {
        let ch = line.unsafe_get(i).unsafe_to_char()
        if ch == '(' {
          depth += 1
        } else if ch == ')' {
          depth -= 1
          if depth == 0 {
            return Some(line.view(start_offset=body_start, end_offset=i).trim())
          }
        }
      }
      None
    }
    None => None
  }
}

///|
fn strip_inline_derive(text : StringView) -> StringView {
  match text.find(" derive(") {
    Some(index) => text.view(start_offset=0, end_offset=index).trim()
    None => text.trim()
  }
}

///|
fn split_top_level_commas(text : StringView) -> Array[StringView] {
  let parts : Array[StringView] = []
  let mut start = 0
  let mut round_depth = 0
  let mut square_depth = 0
  for i in 0..<text.length() {
    let ch = text.unsafe_get(i).unsafe_to_char()
    if ch == '(' {
      round_depth += 1
    } else if ch == ')' {
      round_depth -= 1
    } else if ch == '[' {
      square_depth += 1
    } else if ch == ']' {
      square_depth -= 1
    } else if ch == ',' && round_depth == 0 && square_depth == 0 {
      parts.push(text.view(start_offset=start, end_offset=i))
      start = i + 1
    }
  }
  parts.push(text.view(start_offset=start, end_offset=text.length()))
  parts
}

///|
fn parse_trait_method(
  parent : String,
  line : StringView,
  attributes : Array[String],
) -> ApiItem? {
  if line.has_prefix("fn ") {
    Some(make_trait_method(parent, line.view(start_offset=3), attributes))
  } else if line.has_prefix("fn[") {
    Some(make_trait_method(parent, line.view(start_offset=2), attributes))
  } else if line.has_prefix("async fn ") || line.has_prefix("async fn[") {
    Some(make_trait_method(parent, line, attributes))
  } else {
    None
  }
}

///|
fn make_trait_method(
  parent : String,
  body : StringView,
  attributes : Array[String],
) -> ApiItem {
  let signature = normalize_signature(body)
  let name = extract_name(signature[:])
  {
    kind: "trait-method",
    name: "\{parent}.\{name}",
    signature: apply_attributes(signature, attributes),
  }
}

///|
fn opens_public_container(kind : String, line : StringView) -> Bool {
  is_public_container_kind(kind) &&
  has_open_brace(line) &&
  !has_close_brace(line)
}

///|
fn is_public_container_kind(kind : String) -> Bool {
  kind == "struct" || kind == "enum" || kind == "trait" || kind == "suberror"
}

///|
fn has_open_brace(line : StringView) -> Bool {
  match line.find("{") {
    Some(_) => true
    None => false
  }
}

///|
fn has_close_brace(line : StringView) -> Bool {
  match line.find("}") {
    Some(_) => true
    None => false
  }
}

///|
fn public_body(line : StringView) -> StringView {
  if line.has_prefix("pub(all) ") {
    line.view(start_offset=9).trim()
  } else if line.has_prefix("pub(open) ") {
    line.view(start_offset=10).trim()
  } else if line.has_prefix("pub ") {
    line.view(start_offset=4).trim()
  } else {
    ""
  }
}

///|
fn public_visibility(line : StringView) -> String {
  if line.has_prefix("pub(all) ") {
    "pub(all)"
  } else if line.has_prefix("pub(open) ") {
    "pub(open)"
  } else {
    "pub"
  }
}

///|
fn apply_visibility(signature : String, visibility : String) -> String {
  if visibility == "pub" {
    signature
  } else {
    "\{visibility} \{signature}"
  }
}

///|
fn apply_attributes(signature : String, attributes : Array[String]) -> String {
  if attributes.is_empty() {
    return signature
  }
  let out = StringBuilder()
  for attribute in attributes {
    if !out.is_empty() {
      out.write(" ")
    }
    out.write(attribute)
  }
  out.write(" ")
  out.write(signature)
  out.to_string()
}

///|
fn is_public_line(line : StringView) -> Bool {
  line.has_prefix("pub ") ||
  line.has_prefix("pub(all) ") ||
  line.has_prefix("pub(open) ")
}

///|
fn normalize_signature(text : StringView) -> String {
  let signature = normalize_space(text.trim())
  if signature.length() > 0 &&
    signature.unsafe_get(signature.length() - 1).unsafe_to_char() == '{' {
    signature[:signature.length() - 1].trim().to_owned()
  } else {
    signature
  }
}

///|
fn extract_name(signature : StringView) -> String {
  let signature = trim_callable_prefix(signature)
  let mut end = 0
  while end < signature.length() {
    let ch = signature.unsafe_get(end).unsafe_to_char()
    if ch == ':' &&
      end + 1 < signature.length() &&
      signature.unsafe_get(end + 1).unsafe_to_char() == ':' {
      end += 2
      continue
    }
    if is_name_boundary(ch) {
      break
    }
    end += 1
  }
  signature.view(start_offset=0, end_offset=end).to_owned()
}

///|
fn trim_callable_prefix(signature : StringView) -> StringView {
  let signature = signature.trim()
  if signature.has_prefix("async fn ") {
    trim_leading_generic_params(signature.view(start_offset=9))
  } else if signature.has_prefix("async fn[") {
    trim_leading_generic_params(signature.view(start_offset=8))
  } else if signature.has_prefix("fn ") {
    trim_leading_generic_params(signature.view(start_offset=3))
  } else if signature.has_prefix("fn[") {
    trim_leading_generic_params(signature.view(start_offset=2))
  } else {
    trim_leading_generic_params(signature)
  }
}

///|
fn trim_leading_generic_params(text : StringView) -> StringView {
  let text = text.trim()
  if !text.has_prefix("[") {
    return text
  }
  let mut depth = 0
  for i in 0..<text.length() {
    let ch = text.unsafe_get(i).unsafe_to_char()
    if ch == '[' {
      depth += 1
    } else if ch == ']' {
      depth -= 1
      if depth == 0 {
        return text.view(start_offset=i + 1).trim()
      }
    }
  }
  text
}

///|
fn extract_field_name(line : StringView) -> String {
  let head = match line.find(":") {
    Some(index) => line.view(start_offset=0, end_offset=index).trim()
    None => line.trim()
  }
  let head = if head.has_prefix("mut ") {
    head.view(start_offset=4).trim()
  } else {
    head
  }
  extract_name(head)
}

///|
fn extract_using_name(signature : StringView) -> String {
  match brace_body(signature) {
    Some(body) =>
      match body.find(" as ") {
        Some(index) => extract_name(body.view(start_offset=index + 4).trim())
        None => extract_name(using_export_body(body))
      }
    None => extract_name(signature)
  }
}

///|
fn using_export_body(body : StringView) -> StringView {
  let body = body.trim()
  if body.has_prefix("type ") {
    body.view(start_offset=5).trim()
  } else if body.has_prefix("trait ") {
    body.view(start_offset=6).trim()
  } else if body.has_prefix("struct ") {
    body.view(start_offset=7).trim()
  } else if body.has_prefix("enum ") {
    body.view(start_offset=5).trim()
  } else if body.has_prefix("suberror ") {
    body.view(start_offset=9).trim()
  } else {
    body
  }
}

///|
fn brace_body(text : StringView) -> StringView? {
  match text.find("{") {
    Some(start) =>
      match text.find("}") {
        Some(end) =>
          if end > start {
            Some(text.view(start_offset=start + 1, end_offset=end).trim())
          } else {
            None
          }
        None => None
      }
    None => None
  }
}

///|
fn is_name_boundary(ch : Char) -> Bool {
  ch == '(' ||
  ch == ':' ||
  ch == '[' ||
  ch == '{' ||
  ch == '=' ||
  is_ascii_space(ch.to_int())
}

///|
fn strip_comment(line : StringView) -> StringView {
  let mut in_string = false
  let mut escaped = false
  let mut i = 0
  while i < line.length() {
    let ch = line.unsafe_get(i).unsafe_to_char()
    if in_string {
      if escaped {
        escaped = false
      } else if ch == '\\' {
        escaped = true
      } else if ch == '"' {
        in_string = false
      }
    } else if ch == '"' {
      in_string = true
    } else if ch == '/' &&
      i + 1 < line.length() &&
      line.unsafe_get(i + 1).unsafe_to_char() == '/' {
      return line.view(start_offset=0, end_offset=i)
    }
    i += 1
  }
  line
}

///|
fn normalize_space(text : StringView) -> String {
  let out = StringBuilder(size_hint=text.length())
  let mut saw_space = false
  let mut in_string = false
  let mut escaped = false
  for ch in text {
    if in_string {
      out.write_char(ch)
      if escaped {
        escaped = false
      } else if ch == '\\' {
        escaped = true
      } else if ch == '"' {
        in_string = false
      }
    } else if ch == '"' {
      if saw_space && !out.is_empty() {
        out.write(" ")
      }
      out.write_char(ch)
      saw_space = false
      in_string = true
    } else if is_ascii_space(ch.to_int()) {
      saw_space = true
    } else {
      if saw_space && !out.is_empty() {
        out.write(" ")
      }
      out.write_char(ch)
      saw_space = false
    }
  }
  out.to_string()
}

///|
fn split_lines(text : StringView) -> Array[StringView] {
  let lines : Array[StringView] = []
  let mut start = 0
  for i in 0..<text.length() {
    if text.unsafe_get(i).to_int() == '\n'.to_int() {
      lines.push(
        text.view(start_offset=start, end_offset=i).trim_end(chars="\r"),
      )
      start = i + 1
    }
  }
  lines.push(
    text.view(start_offset=start, end_offset=text.length()).trim_end(chars="\r"),
  )
  lines
}

///|
fn is_ascii_space(code : Int) -> Bool {
  code == ' '.to_int() || code == '\t'.to_int() || code == '\r'.to_int()
}
