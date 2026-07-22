from std.python import Python


struct JavidConfig:
    var filepath: String

    def __init__(out self, path: String = "javid_config.json"):
        self.filepath = path

    def get(self, key: String) -> String:
        try:
            var json_mod = Python.import_module("json")
            var builtin = Python.import_module("builtins")

            var f = builtin.open(self.filepath, "r")
            var data = json_mod.load(f)
            f.close()

            return String(data[key])
        except:
            return ""
