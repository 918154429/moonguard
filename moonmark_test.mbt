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
