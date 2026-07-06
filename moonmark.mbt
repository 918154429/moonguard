///|
/// Public entry point: render a Markdown document to an HTML fragment.
pub fn render(markdown : String) -> String {
  let out = StringBuilder(size_hint=markdown.length() + 32)
  let paragraph = StringBuilder()
  let list_items : Array[String] = []
  let ordered_items : Array[String] = []
  let blockquote_lines : Array[String] = []
  let code_block = StringBuilder()
  let mut in_code_block = false
  let mut code_info = ""
  for raw_line in split_lines(markdown[:]) {
    let line = raw_line.trim_end(chars="\r")
    let trimmed = line.trim()
    if in_code_block {
      if is_fence(trimmed) {
        write_code_block(out, code_block, code_info[:])
        in_code_block = false
        code_info = ""
      } else {
        code_block.write(escape_html(line))
        code_block.write("\n")
      }
    } else if is_fence(trimmed) {
      flush_paragraph(out, paragraph)
      flush_unordered_list(out, list_items)
      flush_ordered_list(out, ordered_items)
      flush_blockquote(out, blockquote_lines)
      in_code_block = true
      code_info = fence_info(trimmed).to_owned()
    } else if trimmed.length() == 0 {
      flush_paragraph(out, paragraph)
      flush_unordered_list(out, list_items)
      flush_ordered_list(out, ordered_items)
      flush_blockquote(out, blockquote_lines)
    } else {
      let heading_level = heading_level(trimmed)
      if heading_level > 0 {
        flush_paragraph(out, paragraph)
        flush_unordered_list(out, list_items)
        flush_ordered_list(out, ordered_items)
        flush_blockquote(out, blockquote_lines)
        write_heading(out, heading_level, heading_text(trimmed, heading_level))
      } else if setext_heading_level(trimmed) > 0 && !paragraph.is_empty() {
        let level = setext_heading_level(trimmed)
        let text = paragraph.to_string()
        paragraph.reset()
        flush_blockquote(out, blockquote_lines)
        write_heading(out, level, text[:])
      } else if is_thematic_break(trimmed) {
        flush_paragraph(out, paragraph)
        flush_unordered_list(out, list_items)
        flush_ordered_list(out, ordered_items)
        flush_blockquote(out, blockquote_lines)
        out.write("<hr />\n")
      } else if is_blockquote(trimmed) {
        flush_paragraph(out, paragraph)
        flush_unordered_list(out, list_items)
        flush_ordered_list(out, ordered_items)
        blockquote_lines.push(render_inline(blockquote_text(trimmed)))
      } else if is_unordered_item(trimmed) {
        flush_paragraph(out, paragraph)
        flush_ordered_list(out, ordered_items)
        flush_blockquote(out, blockquote_lines)
        list_items.push(render_inline(unordered_item_text(trimmed)))
      } else if ordered_marker_len(trimmed) > 0 {
        flush_paragraph(out, paragraph)
        flush_unordered_list(out, list_items)
        flush_blockquote(out, blockquote_lines)
        ordered_items.push(render_inline(ordered_item_text(trimmed)))
      } else {
        flush_unordered_list(out, list_items)
        flush_ordered_list(out, ordered_items)
        flush_blockquote(out, blockquote_lines)
        if !paragraph.is_empty() {
          paragraph.write(" ")
        }
        paragraph.write(trimmed)
      }
    }
  }
  flush_paragraph(out, paragraph)
  flush_unordered_list(out, list_items)
  flush_ordered_list(out, ordered_items)
  flush_blockquote(out, blockquote_lines)
  if in_code_block {
    write_code_block(out, code_block, code_info[:])
  }
  out.to_string()
}

///|
fn flush_paragraph(out : StringBuilder, paragraph : StringBuilder) -> Unit {
  if !paragraph.is_empty() {
    let text = paragraph.to_string()
    out.write("<p>")
    out.write(render_inline(text[:]))
    out.write("</p>\n")
    paragraph.reset()
  }
}

///|
fn flush_unordered_list(out : StringBuilder, items : Array[String]) -> Unit {
  if !items.is_empty() {
    out.write("<ul>\n")
    for item in items {
      out.write("<li>")
      out.write(item)
      out.write("</li>\n")
    }
    out.write("</ul>\n")
    items.clear()
  }
}

///|
fn flush_ordered_list(out : StringBuilder, items : Array[String]) -> Unit {
  if !items.is_empty() {
    out.write("<ol>\n")
    for item in items {
      out.write("<li>")
      out.write(item)
      out.write("</li>\n")
    }
    out.write("</ol>\n")
    items.clear()
  }
}

///|
fn flush_blockquote(out : StringBuilder, lines : Array[String]) -> Unit {
  if !lines.is_empty() {
    out.write("<blockquote>\n<p>")
    for i in 0..<lines.length() {
      if i > 0 {
        out.write(" ")
      }
      out.write(lines[i])
    }
    out.write("</p>\n</blockquote>\n")
    lines.clear()
  }
}

///|
fn write_code_block(
  out : StringBuilder,
  code : StringBuilder,
  info : StringView,
) -> Unit {
  out.write("<pre><code")
  let language = fence_language(info)
  if language.length() > 0 {
    out.write(" class=\"language-")
    out.write(escape_html_attr(language))
    out.write("\"")
  }
  out.write(">")
  out.write(code.to_string())
  out.write("</code></pre>\n")
  code.reset()
}

///|
/// Escape text so user content is safe in an HTML text node.
pub fn escape_html(text : StringView) -> String {
  let out = StringBuilder(size_hint=text.length())
  for ch in text[:] {
    write_escaped_char(out, ch)
  }
  out.to_string()
}

///|
/// Render inline Markdown inside text-bearing blocks.
pub fn render_inline(text : StringView) -> String {
  let out = StringBuilder(size_hint=text.length())
  let mut i = 0
  while i < text.length() {
    let ch = text.unsafe_get(i).unsafe_to_char()
    if ch == '`' {
      match find_char(text, '`', i + 1) {
        Some(close) => {
          out.write("<code>")
          out.write(
            escape_html(text.view(start_offset=i + 1, end_offset=close)),
          )
          out.write("</code>")
          i = close + 1
        }
        None => {
          write_escaped_char(out, ch)
          i += 1
        }
      }
    } else if ch == '*' && char_at(text, i + 1) == Some('*') {
      match find_double_star(text, i + 2) {
        Some(close) => {
          out.write("<strong>")
          out.write(
            escape_html(text.view(start_offset=i + 2, end_offset=close)),
          )
          out.write("</strong>")
          i = close + 2
        }
        None => {
          write_escaped_char(out, ch)
          i += 1
        }
      }
    } else if ch == '*' {
      match find_single_star(text, i + 1) {
        Some(close) => {
          out.write("<em>")
          out.write(
            escape_html(text.view(start_offset=i + 1, end_offset=close)),
          )
          out.write("</em>")
          i = close + 1
        }
        None => {
          write_escaped_char(out, ch)
          i += 1
        }
      }
    } else if ch == '!' && char_at(text, i + 1) == Some('[') {
      match parse_image(text, i) {
        Some(image) => {
          out.write("<img src=\"")
          out.write(escape_html_attr(image.url))
          out.write("\" alt=\"")
          out.write(escape_html_attr(image.alt))
          out.write("\" />")
          i = image.end_offset
        }
        None => {
          write_escaped_char(out, ch)
          i += 1
        }
      }
    } else if ch == '[' {
      match parse_link(text, i) {
        Some(link) => {
          out.write("<a href=\"")
          out.write(escape_html_attr(link.url))
          out.write("\">")
          out.write(escape_html(link.label))
          out.write("</a>")
          i = link.end_offset
        }
        None => {
          write_escaped_char(out, ch)
          i += 1
        }
      }
    } else if ch == '<' {
      match parse_autolink(text, i) {
        Some(link) => {
          let target = link.target
          let mut href = target.to_owned()
          if is_email_autolink(target) {
            href = "mailto:\{target}"
          }
          out.write("<a href=\"")
          out.write(escape_html_attr(href[:]))
          out.write("\">")
          out.write(escape_html(target))
          out.write("</a>")
          i = link.end_offset
        }
        None => {
          write_escaped_char(out, ch)
          i += 1
        }
      }
    } else {
      write_escaped_char(out, ch)
      i += 1
    }
  }
  out.to_string()
}

///|
fn escape_html_attr(text : StringView) -> String {
  escape_html(text)
}

///|
fn write_escaped_char(out : StringBuilder, ch : Char) -> Unit {
  match ch {
    '&' => out.write("&amp;")
    '<' => out.write("&lt;")
    '>' => out.write("&gt;")
    '"' => out.write("&quot;")
    '\'' => out.write("&#39;")
    _ => out.write_char(ch)
  }
}

///|
fn find_char(text : StringView, target : Char, start : Int) -> Int? {
  for i = start; i < text.length(); i = i + 1 {
    if text.unsafe_get(i).to_int() == target.to_int() {
      return Some(i)
    }
  }
  None
}

///|
fn char_at(text : StringView, index : Int) -> Char? {
  if index >= 0 && index < text.length() {
    Some(text.unsafe_get(index).unsafe_to_char())
  } else {
    None
  }
}

///|
fn find_double_star(text : StringView, start : Int) -> Int? {
  for i = start; i + 1 < text.length(); i = i + 1 {
    if text.unsafe_get(i).to_int() == '*'.to_int() &&
      text.unsafe_get(i + 1).to_int() == '*'.to_int() {
      return Some(i)
    }
  }
  None
}

///|
fn find_single_star(text : StringView, start : Int) -> Int? {
  for i = start; i < text.length(); i = i + 1 {
    if text.unsafe_get(i).to_int() == '*'.to_int() &&
      char_at(text, i + 1) != Some('*') &&
      char_at(text, i - 1) != Some('*') {
      return Some(i)
    }
  }
  None
}

///|
priv struct LinkSpan {
  label : StringView
  url : StringView
  end_offset : Int
}

///|
priv struct ImageSpan {
  alt : StringView
  url : StringView
  end_offset : Int
}

///|
priv struct AutolinkSpan {
  target : StringView
  end_offset : Int
}

///|
fn parse_link(text : StringView, open : Int) -> LinkSpan? {
  match find_char(text, ']', open + 1) {
    Some(close_label) =>
      if close_label + 1 < text.length() &&
        text.unsafe_get(close_label + 1).to_int() == '('.to_int() {
        match find_char(text, ')', close_label + 2) {
          Some(close_url) =>
            Some({
              label: text.view(start_offset=open + 1, end_offset=close_label),
              url: text.view(start_offset=close_label + 2, end_offset=close_url),
              end_offset: close_url + 1,
            })
          None => None
        }
      } else {
        None
      }
    None => None
  }
}

///|
fn parse_image(text : StringView, bang : Int) -> ImageSpan? {
  if bang + 1 >= text.length() ||
    text.unsafe_get(bang + 1).to_int() != '['.to_int() {
    return None
  }
  match find_char(text, ']', bang + 2) {
    Some(close_alt) =>
      if close_alt + 1 < text.length() &&
        text.unsafe_get(close_alt + 1).to_int() == '('.to_int() {
        match find_char(text, ')', close_alt + 2) {
          Some(close_url) =>
            Some({
              alt: text.view(start_offset=bang + 2, end_offset=close_alt),
              url: text.view(start_offset=close_alt + 2, end_offset=close_url),
              end_offset: close_url + 1,
            })
          None => None
        }
      } else {
        None
      }
    None => None
  }
}

///|
fn parse_autolink(text : StringView, open : Int) -> AutolinkSpan? {
  match find_char(text, '>', open + 1) {
    Some(close) => {
      let target = text.view(start_offset=open + 1, end_offset=close)
      if is_uri_autolink(target) || is_email_autolink(target) {
        Some({ target, end_offset: close + 1 })
      } else {
        None
      }
    }
    None => None
  }
}

///|
fn split_lines(text : StringView) -> Array[StringView] {
  let lines : Array[StringView] = []
  let mut start = 0
  for i in 0..<text.length() {
    if text.unsafe_get(i).to_int() == '\n'.to_int() {
      lines.push(text.view(start_offset=start, end_offset=i))
      start = i + 1
    }
  }
  lines.push(text.view(start_offset=start, end_offset=text.length()))
  lines
}

///|
fn heading_level(line : StringView) -> Int {
  let mut level = 0
  for ch in line {
    if ch == '#' && level < 6 {
      level += 1
    } else {
      break
    }
  }
  if level > 0 &&
    line.length() > level &&
    line.unsafe_get(level).to_int() == ' '.to_int() {
    level
  } else {
    0
  }
}

///|
fn heading_text(line : StringView, level : Int) -> StringView {
  line.view(start_offset=level).trim()
}

///|
fn is_unordered_item(line : StringView) -> Bool {
  line.length() >= 2 &&
  (
    line.unsafe_get(0).to_int() == '-'.to_int() ||
    line.unsafe_get(0).to_int() == '*'.to_int()
  ) &&
  line.unsafe_get(1).to_int() == ' '.to_int()
}

///|
fn unordered_item_text(line : StringView) -> StringView {
  line.view(start_offset=2).trim()
}

///|
fn ordered_marker_len(line : StringView) -> Int {
  let mut i = 0
  while i < line.length() && is_ascii_digit(line.unsafe_get(i).to_int()) {
    i += 1
  }
  if i > 0 &&
    i + 1 < line.length() &&
    line.unsafe_get(i).to_int() == '.'.to_int() &&
    line.unsafe_get(i + 1).to_int() == ' '.to_int() {
    i + 2
  } else {
    0
  }
}

///|
fn ordered_item_text(line : StringView) -> StringView {
  line.view(start_offset=ordered_marker_len(line)).trim()
}

///|
fn is_ascii_digit(code : Int) -> Bool {
  code >= '0'.to_int() && code <= '9'.to_int()
}

///|
fn is_fence(line : StringView) -> Bool {
  line.length() >= 3 &&
  line.unsafe_get(0).to_int() == '`'.to_int() &&
  line.unsafe_get(1).to_int() == '`'.to_int() &&
  line.unsafe_get(2).to_int() == '`'.to_int()
}

///|
fn fence_info(line : StringView) -> StringView {
  line.view(start_offset=3).trim()
}

///|
fn fence_language(info : StringView) -> StringView {
  let trimmed = info.trim()
  let mut end = 0
  while end < trimmed.length() &&
        !is_ascii_space(trimmed.unsafe_get(end).to_int()) {
    end += 1
  }
  let candidate = trimmed.view(start_offset=0, end_offset=end)
  if is_safe_language_name(candidate) {
    candidate
  } else {
    ""
  }
}

///|
fn is_safe_language_name(text : StringView) -> Bool {
  if text.length() == 0 {
    return false
  }
  for i in 0..<text.length() {
    let code = text.unsafe_get(i).to_int()
    if !(is_ascii_alnum(code) || code == '-'.to_int() || code == '_'.to_int()) {
      return false
    }
  }
  true
}

///|
fn is_ascii_alnum(code : Int) -> Bool {
  is_ascii_digit(code) ||
  (code >= 'a'.to_int() && code <= 'z'.to_int()) ||
  (code >= 'A'.to_int() && code <= 'Z'.to_int())
}

///|
fn is_ascii_space(code : Int) -> Bool {
  code == ' '.to_int() || code == '\t'.to_int()
}

///|
fn setext_heading_level(line : StringView) -> Int {
  if is_marker_line(line, '=') {
    1
  } else if is_marker_line(line, '-') {
    2
  } else {
    0
  }
}

///|
fn is_marker_line(line : StringView, marker : Char) -> Bool {
  if line.length() == 0 {
    return false
  }
  for ch in line {
    if ch != marker {
      return false
    }
  }
  true
}

///|
fn is_thematic_break(line : StringView) -> Bool {
  (line.length() >= 3 && is_marker_line(line, '-')) ||
  (line.length() >= 3 && is_marker_line(line, '*')) ||
  (line.length() >= 3 && is_marker_line(line, '_'))
}

///|
fn is_blockquote(line : StringView) -> Bool {
  line.length() > 0 && line.unsafe_get(0).to_int() == '>'.to_int()
}

///|
fn blockquote_text(line : StringView) -> StringView {
  let text = line.view(start_offset=1)
  if text.length() > 0 && text.unsafe_get(0).to_int() == ' '.to_int() {
    text.view(start_offset=1).trim()
  } else {
    text.trim()
  }
}

///|
fn is_uri_autolink(text : StringView) -> Bool {
  has_prefix(text, "http://") || has_prefix(text, "https://")
}

///|
fn is_email_autolink(text : StringView) -> Bool {
  let at = find_char(text, '@', 0)
  let dot = find_char(text, '.', 0)
  at is Some(_) && dot is Some(_) && !contains_ascii_space(text)
}

///|
fn contains_ascii_space(text : StringView) -> Bool {
  for i in 0..<text.length() {
    if is_ascii_space(text.unsafe_get(i).to_int()) {
      return true
    }
  }
  false
}

///|
fn has_prefix(text : StringView, prefix : String) -> Bool {
  if text.length() < prefix.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if text.unsafe_get(i).to_int() != prefix.unsafe_get(i).to_int() {
      return false
    }
  }
  true
}

///|
fn write_heading(out : StringBuilder, level : Int, text : StringView) -> Unit {
  match level {
    1 => {
      out.write("<h1>")
      out.write(render_inline(text))
      out.write("</h1>\n")
    }
    2 => {
      out.write("<h2>")
      out.write(render_inline(text))
      out.write("</h2>\n")
    }
    3 => {
      out.write("<h3>")
      out.write(render_inline(text))
      out.write("</h3>\n")
    }
    4 => {
      out.write("<h4>")
      out.write(render_inline(text))
      out.write("</h4>\n")
    }
    5 => {
      out.write("<h5>")
      out.write(render_inline(text))
      out.write("</h5>\n")
    }
    _ => {
      out.write("<h6>")
      out.write(render_inline(text))
      out.write("</h6>\n")
    }
  }
}
