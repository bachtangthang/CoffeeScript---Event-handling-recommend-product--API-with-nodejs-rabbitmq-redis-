express             = require "express"
app                 = express()
router              = require "./route/index.coffee"
cookieParser        = require "cookie-parser"

require('dotenv').config()
cors                = require "cors"
app.use cors()
app.use cookieParser()
app.use express.json()

app.listen 5000, ->
  console.log 'Sesrver is listening on port 5000'
  return
app.use '/', router