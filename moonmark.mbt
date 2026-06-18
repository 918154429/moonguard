///| Public entry point: render a Markdown document to an HTML fragment.
pub fn render(markdown : String) -> String {
  let out = StringBuilder(size_hint=markdown.length() + 32)
  let text = markdown.trim()
  if text.length() > 0 {
    out.write("<p>")
    out.write(escape_html(text))
    out.write("</p>\n")
  }
  out.to_string()
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
