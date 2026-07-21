# File: src/mojo/mojoworker/models/pojo_ai_commands.mojo


struct PojoAiCommands:
    var id: Int
    var action_name: String
    var script_content: String
    var status: String
    # 💡 Added field for task execution time estimation
    var estimate_time: Int

    def __init__(
        out self: Self,
        id: Int,
        action_name: String,
        script_content: String,
        status: String,
        estimate_time: Int,
    ):
        self.id = id
        self.action_name = action_name
        self.script_content = script_content
        self.status = status
        self.estimate_time = estimate_time

    def get_id(self) -> Int:
        return self.id

    def get_script_content(self) -> String:
        return self.script_content

    def get_status(self) -> String:
        return self.status

    def set_status(self, new_status: String):
        self.status = new_status

    def is_safe(self) -> Bool:
        # Security logic validation placeholder
        return True
