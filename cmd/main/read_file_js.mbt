///|
extern "js" fn read_file_raw(path : String) -> String =
  #|(path) => {
  #|  try {
  #|    return require("fs").readFileSync(path, "utf8")
  #|  } catch (error) {
  #|    return "__MOONGUARD_READ_ERROR__:" + error.message
  #|  }
  #|}

///|
extern "js" fn list_interface_files_raw(root : String) -> String =
  #|(root) => {
  #|  const fs = require("fs")
  #|  const path = require("path")
  #|  try {
  #|    const stat = fs.statSync(root)
  #|    if (!stat.isDirectory()) {
  #|      return "__MOONGUARD_READ_ERROR__:expected a directory"
  #|    }
  #|    const files = []
  #|    const walk = (dir, rel) => {
  #|      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
  #|        const child = path.join(dir, entry.name)
  #|        const childRel = rel ? rel + "/" + entry.name : entry.name
  #|        if (entry.isDirectory()) {
  #|          walk(child, childRel)
  #|        } else if (entry.isFile() && entry.name.endsWith(".mbti")) {
  #|          files.push(childRel)
  #|        }
  #|      }
  #|    }
  #|    walk(root, "")
  #|    files.sort()
  #|    return files.join("\n")
  #|  } catch (error) {
  #|    return "__MOONGUARD_READ_ERROR__:" + error.message
  #|  }
  #|}
