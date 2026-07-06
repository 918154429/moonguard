///|
test "suberror declarations are first class api items" {
  let api = parse_interface("pub suberror IoError\n")
  inspect(api.length(), content="1")
  inspect(api[0].kind, content="suberror")
  inspect(api[0].name, content="IoError")
  inspect(api[0].signature, content="IoError")
}

///|
test "unknown public declarations remain visible" {
  let api = parse_interface("pub magic IoError\npub magic NetworkError\n")
  inspect(api.length(), content="2")
  inspect(api[0].kind, content="unknown")
  inspect(api[0].name, content="magic IoError")
  inspect(api[1].kind, content="unknown")
  inspect(api[1].name, content="magic NetworkError")
}
