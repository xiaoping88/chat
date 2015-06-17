local server = require "resty.websocket.server"
local cjson = require "cjson"
local wb, err = server:new{
  timeout = 5000,
  max_payload_len = 65535
}
if not wb then
  ngx.log(ngx.ERR, "failed to new websocket: ", err)
  return ngx.exit(444)
end
while true do
  local data, typ, err = wb:recv_frame()
  if wb.fatal then
    ngx.log(ngx.ERR, "failed to receive frame: ", err)
    return ngx.exit(444)
  end
  if not data then
    local bytes, err = wb:send_ping()
    if not bytes then
      ngx.log(ngx.ERR, "failed to send ping: ", err)
      return ngx.exit(444)
    end
  elseif typ == "close" then break
  elseif typ == "ping" then
    local bytes, err = wb:send_pong()
    if not bytes then
      ngx.log(ngx.ERR, "failed to send pong: ", err)
      return ngx.exit(444)
    end
  elseif typ == "pong" then
    ngx.log(ngx.INFO, "client ponged")
  elseif typ == "text" then
    ngx.log(ngx.INFO, "receive text: ", data)
    local bytes,err
    local rec_data = cjson.decode(string.sub(data,3))
    if (rec_data[1] == "add user") then
	bytes, err = wb:send_text('42["login",{"numUsers":20}]')
    else    
        bytes, err = wb:send_text(data)
    end   
    if not bytes then
      ngx.log(ngx.ERR, "failed to send text: ", err)
      return ngx.exit(444)
    end
  end
end
wb:send_close()
