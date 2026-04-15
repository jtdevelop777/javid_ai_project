def add_numbers(a: Int, b: Int) -> Int:
    return a + b

def main():
    # ในเวอร์ชันใหม่ ใช้ var แทน let หรือประกาศลอยๆ แบบ Python ได้เลย
    var x: Int = 10
    var y: Int = 20
    
    # หรือเขียนแบบ Python เลยก็ได้:
    # x = 10
    # y = 20
    
    result = add_numbers(x, y)
    print("ผลรวมคือ:", result)