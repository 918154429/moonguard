///|
extern "js" fn read_file_raw(path : String) -> String =
  #|(path) => {
  #|  try {
  #|    return require("fs").readFileSync(path, "utf8")
  #|  } catch (error) {
  #|    return "__MOONGUARD_READ_ERROR__:" + error.message
  #|  }
  #|}
