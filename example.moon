import App from require "tbsp"

app = App debug_level: 5

app\bind "::", "8000"
app\bind "::", "8001"

print app\run!
