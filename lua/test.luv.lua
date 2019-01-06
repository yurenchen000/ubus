#!/usr/bin/env lua

require "ubus"
--require "uloop"

--print ('----init')
--uloop.init()

print ('----conn')

local conn, err = ubus.connect()
print (' conn, err: ', conn, err)

print (' conn get_fd: ', conn:get_fd())


if not conn then
	error("Failed to connect to ubus")
end

local my_method = {
	broken = {
		hello = 1,
		hello1 = {
			function(req)
			end, {id = "fail" }
		},
	},
	test = {
		hello = {
			function(req, msg)
				conn:reply(req, {message="foo"});
				print("Call to function 'hello'")
				for k, v in pairs(msg) do
					print("key=" .. k .. " value=" .. tostring(v))
				end
			end, {id = ubus.INT32, msg = ubus.STRING }
		},
		hello1 = {
			function(req)
				conn:reply(req, {message="foo1"});
				conn:reply(req, {message="foo2"});
				print("Call to function 'hello1'")
			end, {id = ubus.INT32, msg = ubus.STRING }
		},
		--[[
		deferred = {
			function(req)
				conn:reply(req, {message="wait for it"})
				local def_req = conn:defer_request(req)
				uloop.timer(function()
						conn:reply(def_req, {message="done"})
						conn:complete_deferred_request(def_req, 0)
						print("Deferred request complete")
					end, 2000)
				print("Call to function 'deferred'")
			end, {}
		}
		--]]
	}
}

print ('----add')
conn:add(my_method)

local my_event = {
	test = function(msg)
		print("Call to test event")
		for k, v in pairs(msg) do
			print("key=" .. k .. " value=" .. tostring(v))
		end
	end,
}

--print ('----listen')
conn:listen(my_event)

function show(obj)
	local keys={}
	for k in pairs(obj) do table.insert(keys, k) end
	table.sort(keys)
	for i,k in ipairs(keys) do
		--print(k, obj[k])
		print(string.format('\t%-18s %s', k, tostring(obj[k]) ))
	end
end

print '---ubus:'
show(ubus)

print '---conn:'
print(conn)

--uloop.run()

------ try libuv
local uv = require('luv')

function fd_handle(err, event) -- err always nil; event = 'r', 'w', 'd', 'rw'..
	if string.find(event, 'r') then
		conn:handle_fd()
	end
	if string.find(event, 'w') then

	end
	if string.find(event, 'd') then
		print('  deal disconnect:', event)
	end
end

--- main

sock_poll = uv.new_poll(conn:get_fd())
sock_poll:start('rd', fd_handle)

print ('----uv run')
uv.run()

