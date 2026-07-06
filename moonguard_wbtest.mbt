///|
test "unknown public declarations remain visible" {
  let api = parse_interface("pub suberror IoError\n")
  inspect(api.length(), content="1")
  inspect(api[0].kind, content="unknown")
  inspect(api[0].name, content="suberror")
  inspect(api[0].signature, content="suberror IoError")
}
