coffee  = require("coffee-script")
express = require("express")
http    = require("http")
spawn   = require("child_process").spawn

express.logger.format "method", (req, res) ->
  req.method.toLowerCase()

express.logger.format "url", (req, res) ->
  req.url.replace('"', '&quot')

express.logger.format "user-agent", (req, res) ->
  (req.headers["user-agent"] || "").replace('"', '')

app = express.createServer(
  express.logger
    buffer: false
    format: "subject=\"http\" method=\":method\" url=\":url\" status=\":status\" elapsed=\":response-time\" from=\":remote-addr\" agent=\":user-agent\"")

app.get "/", (req, res) ->
  res.send "ok"

app.post "/log", (req, res) ->
  splunk  = req.query.splunk.split(":")
  project = splunk[0]
  token   = splunk[1]
  buffer  = ""

  options =
    method:   "POST"
    hostname: "api.splunkstorm.com"
    port:     80
    path:     "/1/inputs/http?index=#{project}&sourcetype=syslog"
    auth:     "#{token}:x"

  req.on "data", (data) ->
    buffer += data.toString()
    parts   = buffer.split("\n")
    remain  = parts.pop()
    for part in parts
      request = headers:
        "Content-Length": part.length
      splunk_req = http.request coffee.helpers.merge(options, request), (splunk_res) ->
        console.log "code", splunk_res.statusCode, splunk_res.headers
      console.log "part", part
      splunk_req.write part
      splunk_req.end()
    splunk_req.on "error", (err) ->
      console.log "error", err

port = process.env.PORT || 5000

app.listen port, ->
  console.log "listening on port #{port}"
