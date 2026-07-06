///|
/// Render Markdown passed as command-line arguments.
fn main {
  let args = @env.args()
  let markdown = StringBuilder()
  let mut saw_input = false
  for i in 1..<args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      print_help()
      return
    } else if arg == "--version" || arg == "-V" {
      println("moonmark 0.1.0")
      return
    } else {
      if saw_input {
        markdown.write(" ")
      }
      markdown.write(arg)
      saw_input = true
    }
  }
  if saw_input {
    println(@moonmark.render(markdown.to_string()))
  } else {
    print_help()
  }
}

///|
fn print_help() -> Unit {
  let help =
    #|moonmark 0.1.0
    #|
    #|Usage:
    #|  moon run cmd/main -- "# Hello"
    #|  moon run cmd/main -- --version
    #|  moon run cmd/main -- --help
    #|
    #|Render a practical Markdown subset to an escaped HTML fragment.
  println(help)
}
