test "escape html entities" {
  inspect(
    @moonmark.escape_html("<tag a=\"1\">Tom & Jerry's</tag>"),
    content="&lt;tag a=&quot;1&quot;&gt;Tom &amp; Jerry&#39;s&lt;/tag&gt;",
  )
}

test "render plain paragraph" {
  inspect(
    @moonmark.render("hello <moonbit>"),
    content="<p>hello &lt;moonbit&gt;</p>\n",
  )
}

test "ignore all whitespace document" {
  inspect(@moonmark.render("   \n\t"), content="")
}

test "render headings and paragraphs" {
  inspect(
    @moonmark.render("# Title\nhello\nworld\n\n## Next"),
    content="<h1>Title</h1>\n<p>hello world</p>\n<h2>Next</h2>\n",
  )
}

test "limit atx headings to six levels" {
  inspect(
    @moonmark.render("###### Deep\n####### not heading"),
    content="<h6>Deep</h6>\n<p>####### not heading</p>\n",
  )
}
