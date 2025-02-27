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
-- @file        server.lua
--

-- imports
import("private.service.config")
import("private.service.message")
import("private.service.server")
import("private.service.stream", {alias = "socket_stream"})
import("private.service.remote_build.session", {alias = "server_session"})
import("lib.detect.find_tool")

-- define module
local remote_build_server = remote_build_server or server()
local super = remote_build_server:class()

-- init server
function remote_build_server:init(daemon)
    super.init(self, daemon)
    if self:daemon() then
        config.load()
    end

    -- check requires
    self:_check_requires()

    -- init address
    local address = assert(config.get("remote_build.server.listen"), "config(remote_build.server.listen): not found!")
    super.address_set(self, address)

    -- init handler
    super.handler_set(self, self._on_handle)

    -- init sessions
    self._SESSIONS = {}
end

-- get class
function remote_build_server:class()
    return remote_build_server
end

-- check requires
function remote_build_server:_check_requires()

    -- check git
    local git = find_tool("git")
    assert(git, "git not found!")

    -- check sshkeys
    -- TODO
end

-- on handle message
function remote_build_server:_on_handle(stream, msg)
    local session_id = msg:session_id()
    vprint("%s: %s: <session %s>: on handle message(%d)", self, stream:sock(), session_id, msg:code())
    vprint(msg:body())
    local session_ok, session_errs
    if msg:is_connect() then
        session_ok, session_errs = self:_session_open(session_id)
    elseif msg:is_disconnect() then
        session_ok, session_errs = self:_session_close(session_id)
    elseif msg:is_sync() then
        session_ok, session_errs = self:_session_syncfiles(session_id)
    end
    local respmsg = msg:clone()
    respmsg:status_set(session_ok)
    if not session_ok and session_errs then
        respmsg:errors_set(session_errs)
    end
    local ok = stream:send_msg(respmsg) and stream:flush()
    vprint("%s: %s: <session %s>: send %s", self, stream:sock(), session_id, ok and "ok" or "failed")
end

-- get session
function remote_build_server:_session(session_id)
    return self._SESSIONS[session_id]
end

-- open session
function remote_build_server:_session_open(session_id)
    local session = server_session(session_id)
    local errors
    local ok = try
    {
        function ()
            session:open()
            return true
        end,
        catch
        {
            function (errs)
                errors = tostring(errs)
            end
        }
    }
    if ok then
        self._SESSIONS[session_id] = session
    end
    return ok, errors
end

-- close session
function remote_build_server:_session_close(session_id)
    local session = self:_session(session_id)
    local errors
    local ok = try
    {
        function ()
            if session then
                session:close()
            end
            return true
        end,
        catch
        {
            function (errs)
                errors = tostring(errs)
            end
        }
    }
    if ok then
        self._SESSIONS[session_id] = nil
    end
    return ok, errors
end

-- sync files
function remote_build_server:_session_syncfiles(session_id)
    local session = self:_session(session_id)
    local errors
    local ok = try
    {
        function ()
            if session then
                session:syncfiles()
            end
            return true
        end,
        catch
        {
            function (errs)
                errors = tostring(errs)
            end
        }
    }
    if ok then
        self._SESSIONS[session_id] = nil
    end
    return ok, errors
end

function remote_build_server:__tostring()
    return "<remote_build_server>"
end

function main(daemon)
    local instance = remote_build_server()
    instance:init(daemon ~= nil)
    return instance
end
