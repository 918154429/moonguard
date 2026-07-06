///|
/// Compare two interface snapshots passed as command-line arguments.
fn main {
  let args = @env.args()
  if args.length() == 2 && (args[1] == "--help" || args[1] == "-h") {
    print_help()
    return
  }
  if args.length() == 2 && (args[1] == "--version" || args[1] == "-V") {
    println("moonguard 0.1.0")
    return
  }
  if args.length() != 4 || args[1] != "report" {
    print_help()
    return
  }
  let report = @moonguard.diff_interfaces(args[2], args[3])
  println(@moonguard.render_markdown_report(report))
}

///|
fn print_help() -> Unit {
  let help =
    #|moonguard 0.1.0
    #|
    #|Usage:
    #|  moon run cmd/main -- report "pub fn old() -> Unit" "pub fn new() -> Unit"
    #|  moon run cmd/main -- --version
    #|  moon run cmd/main -- --help
    #|
    #|Compare two MoonBit interface snapshots and print a Markdown report.
  println(help)
}
