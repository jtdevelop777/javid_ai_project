from std.python import Python, PythonObject


# 1. ฟังก์ชันตรวจสอบสิทธิ์ระดับแอดมินแบบไดนามิก
def check_admin_privilege(role: PythonObject, is_active: PythonObject) -> Bool:
    try:
        # 💡 แยกตัวแปรออกมา Cast เป็น Bool ของ Mojo ให้เด็ดขาดทีละบรรทัด
        var is_admin = Bool(role == "admin")
        var is_user_active = Bool(is_active.to_int() == 1)

        # 💡 เอา Bool แท้ ๆ ของ Mojo มา AND กันข้ามท่อ
        return is_admin and is_user_active
    except:
        return False


# 2. ฟังก์ชันตรวจสอบความถูกต้องของโอเปอเรเตอร์
def validate_operator(
    operator: PythonObject, action: String, target_user: PythonObject
) -> Bool:
    try:
        var opt_role = operator.role
        var opt_active = operator.is_active

        if check_admin_privilege(opt_role, opt_active):
            return True
    except:
        print("⚠️ [Auth Service] Error accessing Python dynamic properties.")

    print("🔒 Access Denied: Operator lacks required admin privileges.")
    return False
