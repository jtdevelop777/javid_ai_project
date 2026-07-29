from std.python import Python, PythonObject


struct UserModel:
    var username: String
    var role: String
    var is_active: Int
    var allowed_projects: PythonObject

    def __init__(
        out self,
        username: String,
        role: String,
        is_active: Int,
        allowed_projects: PythonObject,
    ):
        self.username = username
        self.role = role
        self.is_active = is_active
        self.allowed_projects = allowed_projects
