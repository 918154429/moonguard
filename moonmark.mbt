///| Public entry point: render a Markdown document to an HTML fragment.
pub fn render(markdown : String) -> String {
  let out = StringBuilder(size_hint=markdown.length() + 32)
  let paragraph = StringBuilder()
  let list_items : Array[String] = []
  for raw_line in split_lines(markdown[:]) {
    let line = raw_line.trim_end(chars="\r")
    let trimmed = line.trim()
    if trimmed.length() == 0 {
      flush_paragraph(out, paragraph)
      flush_unordered_list(out, list_items)
    } else {
      let heading_level = heading_level(trimmed)
      if heading_level > 0 {
        flush_paragraph(out, paragraph)
        flush_unordered_list(out, list_items)
        write_heading(out, heading_level, heading_text(trimmed, heading_level))
      } else if is_unordered_item(trimmed) {
        flush_paragraph(out, paragraph)
        list_items.push(escape_html(unordered_item_text(trimmed)))
      } else {
        flush_unordered_list(out, list_items)
        if !paragraph.is_empty() {
          paragraph.write(" ")
        }
        paragraph.write(escape_html(trimmed))
      }
    }
  }
  flush_paragraph(out, paragraph)
  flush_unordered_list(out, list_items)
  out.to_string()
}

fn flush_paragraph(out : StringBuilder, paragraph : StringBuilder) -> Unit {
  if !paragraph.is_empty() {
    out.write("<p>")
    out.write(paragraph.to_string())
    out.write("</p>\n")
    paragraph.reset()
  }
}

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

///| Escape text so user content is safe in an HTML text node.
pub fn escape_html(text : StringView) -> String {
  let out = StringBuilder(size_hint=text.length())
  for ch in text[:] {
    match ch {
      '&' => out.write("&amp;")
      '<' => out.write("&lt;")
      '>' => out.write("&gt;")
      '"' => out.write("&quot;")
      '\'' => out.write("&#39;")
      _ => out.write_char(ch)
    }
  }
  out.to_string()
}

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

fn heading_text(line : StringView, level : Int) -> StringView {
  line.view(start_offset=level).trim()
}

fn is_unordered_item(line : StringView) -> Bool {
  line.length() >= 2 &&
  (line.unsafe_get(0).to_int() == '-'.to_int() ||
   line.unsafe_get(0).to_int() == '*'.to_int()) &&
  line.unsafe_get(1).to_int() == ' '.to_int()
}

fn unordered_item_text(line : StringView) -> StringView {
  line.view(start_offset=2).trim()
}

fn write_heading(out : StringBuilder, level : Int, text : StringView) -> Unit {
  match level {
    1 => {
      out.write("<h1>")
      out.write(escape_html(text))
      out.write("</h1>\n")
    }
    2 => {
      out.write("<h2>")
      out.write(escape_html(text))
      out.write("</h2>\n")
    }
    3 => {
      out.write("<h3>")
      out.write(escape_html(text))
      out.write("</h3>\n")
    }
    4 => {
      out.write("<h4>")
      out.write(escape_html(text))
      out.write("</h4>\n")
    }
    5 => {
      out.write("<h5>")
      out.write(escape_html(text))
      out.write("</h5>\n")
    }
    _ => {
      out.write("<h6>")
      out.write(escape_html(text))
      out.write("</h6>\n")
    }
  }
}
