local ngx = ngx
local Class = require 'shared.base.Class'
local util = require 'shared.util'
local cjson = require 'cjson.safe'
local redis = require 'resty.redis'
local byte, sub, find = string.byte, string.sub, string.find
local insert = table.insert
local tostring, tonumber, next, pairs, ipairs = tostring, tonumber, next, pairs, ipairs
local time = os.time
--local ffi = require 'ffi'
--local bilin_util = ffi.load("bilin_lib_c.so")
require 'conf.redis_conf'
local redis_list = REDIS_SERVER
--ffi.cdef[[
--    unsigned int fnv1a(const char * str, int servers);
--]]

-- when num of key-value in the table > NUM, use command 'mset' set this table to redis
-- changing NUM can be effective, 200 may be a good one
local NUM = 200

local need_to_set = {nil}
local need_to_set_count = {nil}
local servers = {}

for k, v in pairs(redis_list) do
    ngx.log(ngx.ERR, cjson.encode(v))
    insert(servers, redis.connect(v.opt.host, v.opt.port))
    need_to_set[tostring(k)] = {nil}
    need_to_set_count[tostring(k)] = 0
end

Importer = Class:new()
--TODO, import cookie list
local ListType = {['i'] = 'ip', ['u'] = 'url', ['d'] = 'domain'}

--add/update/delete/check list
function Importer:update(ngx)
    ngx.header['Content-Type'] = 'application/json'
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    local param = ngx.req.get_uri_args()
    local info = self:init_info()

    -- if redis can not connect
    if not self:validate_connect() then
        info.success = false
        ngx.say(cjson.encode(info))
        ngx.exit(200)
    end

    if param.op == 'add' then
        self:add(data, info)
    elseif param.op == 'del' then
        self:del(data, info)
    elseif param.op == 'check' then
        self:check(data, info)
    else
        info.success = false
    end

    if not next(info.data) then
        ngx.say(cjson.encode(info))
    else
        info.success = false
        ngx.say(cjson.encode(info))
    end
    ngx.exit(200)
end

-- success or error info
-- data["code"] meaning
-- 1: type error(not in [i, p, d])
-- 2: format error(must split by '\t')
-- 3: set or delete failure, because redis may be busy or down, try again
-- 4: list id to be delete not exists
-- 5: data(ip,url,doamin) to be delete not exists
-- 6: timestamp error, timestamp is time to live, and must be larger than now()
-- 7: check error, data is not in redis
function Importer:init_info()
    local info = {['success'] = true, ['data'] = {}}
    return info
end

function Importer:insert_info(info, id, member, type, code)
    info.success = false
    insert(info.data, {['list'] = tonumber(id), ['member'] = member, ['type'] = type, ['code'] = code})
end

-- validate connection
function Importer:validate_connect()
    for _,s in pairs(servers) do
        if not s:ping() then return false end
    end
    return true
end

function Importer:validate_ct(ct)
    if ct - time() <= 0 then return false end
    return true
end

--check whether the list has imported successfully
--I believe the list format is correct
function Importer:check(data, info)
    local lines = util.split(data, '\n')
    for k, line in ipairs(lines) do
        if line and line ~= '' then
            local elements = util.split(line, '\t')
            local type = elements[1]
            local id = elements[2]
            local key = elements[3]
            local ct = tonumber(elements[4])
            local domain, subdomain, old_value = nil, nil, nil
            if type == 'd' then
                _,subdomain,_,_,old_value = self:get_old_domain('d_', key)
            else
                _,_,old_value = self:get_old_value(type..'_', key)
            end
            if not old_value then 
                self:insert_info(info, id, key, type, 7)
            else
                if type == 'd' then
                    if not(next(old_value[subdomain or '*']) 
                        and old_value[subdomain or '*']['d'..id] == ct) then
                        self:insert_info(info, id, key, type, 7)
                    end
                else
                    if not(next(old_value['segments']) 
                        and old_value['segments'][type..id] == ct) then
                        self:insert_info(info, id, key, type, 7)
                    end
                end
            end
        end
    end
end

--delete list
function Importer:del(data, info)
    local lines = util.split(data, '\n')
    for k, line in ipairs(lines) do
        local elements = util.split(line, '\t')
        local type = ListType[elements[1]]
        if not type and line and line ~= '' then
            self:insert_info(info, nil, line, elements[1], 1)
        elseif elements[1] and elements[2] and elements[3]
            and tonumber(elements[2]) and not tonumber(elements[3]) then
            if type == 'domain' then
                self:delete_domain('d_', elements[3], 'd'.. elements[2], info)
            elseif type == 'url' then
                self:delete_other('u_', elements[3], 'u'.. elements[2], info)
            elseif type == 'ip' then
                self:delete_other('i_', elements[3], 'i'.. elements[2], info)
            end
        -- ignore empty line, and note line which format is error
        elseif line and line ~= '' then
            self:insert_info(info, nil, line, type, 2)
        end
    end
end

--add list
function Importer:add(data, info)
    local lines = util.split(data, '\n')
    for k, line in ipairs(lines) do
        local elements = util.split(line, '\t')
        local type = ListType[elements[1]]
        if not type and line and line ~= '' then 
            self:insert_info(info, nil, line, elements[1], 1)
        elseif elements[2] and elements[3] and elements[3] ~= '' and elements[4] 
            and tonumber(elements[2]) and tonumber(elements[4]) then 
            if not self:validate_ct(tonumber(elements[4])) then
                self:insert_info(info, tonumber(elements[2]), elements[3], type, 6)
            else
                if type == 'domain' then
                    self:store_domain('d_', elements[3], 'd'.. elements[2], tonumber(elements[4]), info)
                elseif type == 'url' then
                    self:store_other('u_', elements[3], 'u'.. elements[2], tonumber(elements[4]), info)
                elseif type == 'ip' then
                    self:store_other('i_', elements[3], 'i'.. elements[2], tonumber(elements[4]), info)
                end
            end
        elseif line and line ~= '' then
            self:insert_info(info, nil, line, type, 2)
        end
    end
    self:set_rest_list()
end

--TODO
--function Importer:fnv1a_hash_key(key)
--    return bilin_util.fnv1a(key, #servers) + 1
--end

-- which redis to save
function Importer:hash_key(key)
    local len = #key
    return (byte(key, 1) + byte(key, 2) + byte(key, len) + byte(key, len-1)) % #servers
end

-- get old domain that has been in redis
function Importer:get_old_domain(prefix, key)
    local domain = util.get_domain_from_url(key)
    local subdomain = util.get_subdomain(domain, key)
    return domain, subdomain, self:get_old_value(prefix, domain)
end

-- get data that has been in redis
function Importer:get_old_value(prefix, key)
    local pre_key = prefix .. ngx.md5(key) 
    local idx = self:hash_key(pre_key) + 1
    --local idx = self:fnv1a_hash_key(pre_key)
    local s_idx = tostring(idx)
    local old_value = nil
    if need_to_set[s_idx] and need_to_set[s_idx][pre_key] then
        old_value = need_to_set[s_idx][pre_key]
    else
        old_value = servers[idx]:get(pre_key)
    end
    old_value = cjson.decode(old_value)
    return pre_key, idx, old_value
end
 
-- store domain
function Importer:store_domain(prefix, key, id, ct, add_info)
    local domain, subdomain, pre_key, idx, old_value = self:get_old_domain(prefix, key)
    -- if old_value, update
    if old_value then
        if subdomain then
            if not old_value[subdomain] then
                old_value[subdomain] = {}
            end
            old_value[subdomain][id] = ct
        else
            if not old_value["*"] then
                old_value["*"] = {}
            end
            old_value["*"][id] = ct
        end
        -- old_value["?"] stores domain
        old_value["?"] = domain
        self:push_to_list(idx, pre_key, cjson.encode(old_value), info)
    -- create a new data
    else
        local new_value = {[subdomain or "*"] = {[id] = ct}, ["?"] = domain}
        self:push_to_list(idx, pre_key, cjson.encode(new_value), info)
    end
end

-- store ip or url
function Importer:store_other(prefix, key, id, ct, info)
    local pre_key, idx, old_value = self:get_old_value(prefix, key)
    -- if old_value, update
    if old_value then
        old_value.segments[id] = ct
        old_value["value"] = key 
        self:push_to_list(idx, pre_key, cjson.encode(old_value), info)
    -- create a new data
    else
        local new_value = {['segments'] = {[id] = ct}, ['value'] = key}
        self:push_to_list(idx, pre_key, cjson.encode(new_value), info)
    end 
end

-- delete list
-- if delete fail, add del_info to {del_info}
function Importer:delete_domain(prefix, key, id, info)
    local domain, subdomain, pre_key, idx, old_value = self:get_old_domain(prefix, key)
    if old_value then
        if subdomain then
            if not (old_value[subdomain] and old_value[subdomain][id]) then
                self:insert_info(info, sub(id,2), subdomain, sub(id,1,1), 4)
            else
                old_value[subdomain][id] = nil
            end
        else
            if not old_value["*"] then
                self:insert_info(info, sub(id,2), domain, sub(id,1,1), 4)
            else
                old_value["*"][id] = nil
            end
        end
        -- delete empty table
        for k,v in pairs(old_value) do
            if k ~= '?' and not next(v) then
                old_value[k] = nil
            end
        end
    else
        self:insert_info(info, sub(id,2), domain, sub(id,1,1), 5)
        return
    end
    local sign = false
    -- delete key that has no "*" or subdomain
    for k,v in pairs(old_value) do
        if k ~= '?' and next(v) then
            sign = true
            break
        end
    end
    local update_status, del_status
    if sign then
        update_status = servers[idx]:set(pre_key, cjson.encode(old_value))
    else
        -- delete empty key
        del_status = servers[idx]:del(pre_key)
    end
    if not (update_status or del_status == 1) then
        self:insert_info(info, sub(id,2), domain, sub(id,1,1), 3)
    end
end

function Importer:delete_other(prefix, key, id, info)
    local pre_key, idx, old_value = self:get_old_value(prefix, key)
    local update_status, del_status
    if old_value then
        if not old_value.segments[id] then
            self:insert_info(info, sub(id,2), key, sub(id,1,1), 4)
        end 
        old_value.segments[id] = nil 
        update_status = servers[idx]:set(pre_key, cjson.encode(old_value))
        -- delete keys which segments is empty
        if not next(old_value['segments']) then
            del_status = servers[idx]:del(pre_key)
        end 
    else
        self:insert_info(info, sub(id,2), key, sub(id,1,1), 5)
        return
    end 
    if not (update_status or del_status == 1) then
        self:insert_info(info, sub(id,2), key, sub(id,1,1), 3)
    end
end

function Importer:push_to_list(idx, key, value, info)
    local s_idx = tostring(idx)
    need_to_set[s_idx][key] = value
    need_to_set_count[s_idx] = need_to_set_count[s_idx]+1
    if need_to_set_count[s_idx] > NUM then
        self:mset_table(s_idx)
    end
end

function Importer:set_rest_list()
    for k,v in pairs(need_to_set) do
        if next(need_to_set[k]) then
            self:mset_table(k)
        end
    end
end

function Importer:mset_table(s_idx)
    --TODO, what to do when mset failed
    servers[tonumber(s_idx)]:mset(need_to_set[s_idx])
    need_to_set[s_idx] = {nil}
    need_to_set_count[s_idx] = 0
end

return Importer
