local App
App = require("tbsp").App
local app = App({
  debug_level = 5
})
app:bind("::", "8000")
app:bind("::", "8001")
return print(app:run())
