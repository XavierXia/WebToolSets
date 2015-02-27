local ngx = ngx
local redis = require 'redis'
local cjson = require 'cjson.safe'
local util = require 'shared.util'
local logger = require 'shared.log'
local insert = table.insert
local find, sub, byte = string.find, string.sub, string.byte
require 'redis_conf'

local redis_list = REDIS_SERVER
local KEY_TYPE = {['i']='ip', ['d']='domain', ['u']='url'}

local servers = {}

for k, v in pairs(redis_list) do
    insert(servers, redis.connect(v.opt.host, v.opt.port))
end
R = {}
R.mem_usage, R.key_location, R.ping, R.check_upload = nil,nil,nil,nil

local function hash_key(key)
    local len = #key
    return (byte(key, 1) + byte(key, 2) + byte(key, len) + byte(key, len-1)) % #servers
end

-- get data that has been in redis
local function get_old_value(prefix, key)
    local pre_key = prefix .. '_' .. ngx.md5(key)
    local idx = hash_key(pre_key) + 1
    --local idx = self:fnv1a_hash_key(pre_key)
    local old_value = servers[idx]:get(pre_key)
    return pre_key, idx, old_value
end

-- get old domain that has been in redis
local function get_old_domain(prefix, key)
    local domain = util.get_domain_from_url(key)
    local subdomain = util.get_subdomain(domain, key)
    return domain, subdomain, get_old_value(prefix, domain)
end

R.redis_status = function()
    logger:log("test", "come in mem_usage")
    local tb = {}
    for i,s in pairs(servers) do
        local info = s:info()
        local db0 = info.keyspace.db0
        local keys_num = 0
        for k,_ in pairs(db0) do
            local x,y = find(k, ("%d+"))
            local num = tonumber(sub(k, x, y)) or 0
            keys_num = keys_num + num
        end
        local result = {}
        result['id'] = i
        result['status'] = s:ping() and 'Live' or 'Dead'
        result['ip'] = redis_list[i]['opt']['host']
        result['port'] = redis_list[i]['opt']['port'] 
        result['mem_all'] = redis_list[i]['opt']['volume'] or 8053804
        result['mem_used'] = tonumber(info.memory.used_memory)
        result['keys_num'] = keys_num
        result['last_save_time'] = tonumber(info.persistence.rdb_last_save_time)
        insert(tb, result)
    end
    return tb
end

R.key_location = function(key, type)
    if not KEY_TYPE[type] then return false end
    local key_in_redis, idx, value = nil, nil, nil
    if KEY_TYPE[type] == 'domain' then
        _,_, key_in_redis, idx, value = get_old_domain(type, key)
    else
        key_in_redis, idx, value = get_old_value(type, key)
    end
    if not value then return false end
    local result = {['key'] = key_in_redis, 
                    ['location'] = {['ip'] = redis_list[idx].opt.host,
                                    ['port'] = redis_list[idx].opt.port
                                },
                    ['value'] = cjson.decode(value)
                }
    return result
end

local op_list = {
    ["redis_status"] = R.redis_status,
    ["key_location"] = R.key_location,
    ["check_upload"] = R.check_upload,
}


function R:handle(ngx)
    local args = ngx.var.args
    local param = ngx.decode_args(args, 0)
    logger:log("test","param:%s",cjson.encode(param))    
    local op = param.op
    if not op then return ngx.say(cjson.encode(nil)) end
    local key, type = param.key, param.type
    local strjson
    if op == "key_location" then
        strjson = op_list[op](key, type)
    else 
        strjson = op_list[op] and op_list[op]() or nil
    end
    ngx.header['Content-Type'] = 'application/json' 
    ngx.say(cjson.encode(strjson))
end

return R
