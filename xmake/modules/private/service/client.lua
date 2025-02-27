--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        client.lua
--

-- imports
import("core.base.object")
import("core.base.socket")
import("core.base.scheduler")

-- define module
local client = client or object()

-- init client
function client:init()
end

-- set the given client address
function client:address_set(address)
    local splitinfo = address:split(':', {plain = true})
    if #splitinfo == 2 then
        self._ADDR = splitinfo[1]
        self._PORT = splitinfo[2]
    else
        self._ADDR = "127.0.0.1"
        self._PORT = splitinfo[1]
    end
    assert(self._ADDR and self._PORT, "invalid client address!")
end

-- get the address address
function client:addr()
    return self._ADDR
end

-- get the address port
function client:port()
    return self._PORT
end

-- get class
function client:class()
    return client
end

-- get working directory
function client:workdir()
    return os.tmpfile(tostring(self)) .. ".dir"
end

function client:__tostring()
    return "<client>"
end

function main()
    local instance = client()
    instance:init()
    return instance
end
