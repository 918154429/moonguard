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

test "render unordered list" {
  inspect(
    @moonmark.render("- one\n- two & more\n* three"),
    content="<ul>\n<li>one</li>\n<li>two &amp; more</li>\n<li>three</li>\n</ul>\n",
  )
}

test "separate lists from paragraphs" {
  inspect(
    @moonmark.render("intro\n- item\n\n# Done"),
    content="<p>intro</p>\n<ul>\n<li>item</li>\n</ul>\n<h1>Done</h1>\n",
  )
}

test "render ordered list" {
  inspect(
    @moonmark.render("1. collect\n2. parse <safe>\n10. render"),
    content="<ol>\n<li>collect</li>\n<li>parse &lt;safe&gt;</li>\n<li>render</li>\n</ol>\n",
  )
}

test "separate ordered and unordered lists" {
  inspect(
    @moonmark.render("1. first\n- bullet"),
    content="<ol>\n<li>first</li>\n</ol>\n<ul>\n<li>bullet</li>\n</ul>\n",
  )
}

test "render fenced code block" {
  inspect(
    @moonmark.render("```moonbit\nfn main { println(\"<ok>\") }\n```"),
    content="<pre><code>fn main { println(&quot;&lt;ok&gt;&quot;) }\n</code></pre>\n",
  )
}

test "close unclosed fenced code at document end" {
  inspect(
    @moonmark.render("```\n# not heading"),
    content="<pre><code># not heading\n</code></pre>\n",
  )
}

test "render inline code spans" {
  inspect(
    @moonmark.render("Use `moon test` before `<push>`."),
    content="<p>Use <code>moon test</code> before <code>&lt;push&gt;</code>.</p>\n",
  )
}

test "render inline code in headings and lists" {
  inspect(
    @moonmark.render("## Run `moon`\n- call `render`"),
    content="<h2>Run <code>moon</code></h2>\n<ul>\n<li>call <code>render</code></li>\n</ul>\n",
  )
}

test "escape unmatched backtick" {
  inspect(@moonmark.render("`open"), content="<p>`open</p>\n")
}

test "render inline links" {
  inspect(
    @moonmark.render("Read [docs](https://docs.moonbitlang.cn/?q=<x>)."),
    content="<p>Read <a href=\"https://docs.moonbitlang.cn/?q=&lt;x&gt;\">docs</a>.</p>\n",
  )
}

test "escape malformed links as text" {
  inspect(
    @moonmark.render("[broken](url"),
    content="<p>[broken](url</p>\n",
  )
}

test "render emphasis and strong text" {
  inspect(
    @moonmark.render("*small* and **important <safe>**"),
    content="<p><em>small</em> and <strong>important &lt;safe&gt;</strong></p>\n",
  )
}

test "keep unmatched emphasis markers" {
  inspect(
    @moonmark.render("*open and **also open"),
    content="<p>*open and **also open</p>\n",
  )
}
