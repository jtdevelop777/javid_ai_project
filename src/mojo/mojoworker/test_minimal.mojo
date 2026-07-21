from std.python import Python


def main() raises:
    var p = Python.import_module("builtins")
    print("Mojo Test: Success")
    var test_str = String("Hello") + String(" World")
    print(test_str)
