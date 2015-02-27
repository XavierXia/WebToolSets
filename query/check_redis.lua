local ngx = ngx
local redis = require 'redis'
local cjson = require 'cjson.safe'
local util = require 'shared.util'
local insert = table.insert
local find, sub, byte = string.find, string.sub, string.byte
require 'redis_conf'

local redis_list = REDIS_SERVER
local KEY_TYPE = {['i']='ip', ['d']='domain', ['u']='url'}

local servers = {}

for k, v in pairs(redis_list) do
    insert(servers, redis.connect(v.opt.host, v.opt.port))
end

local R = {}

function R:hash_key(key)
    local len = #key
    return (byte(key, 1) + byte(key, 2) + byte(key, len) + byte(key, len-1)) % #servers
end

-- get old domain that has been in redis
function R:get_old_domain(prefix, key)
    local domain = util.get_domain_from_url(key)
    local subdomain = util.get_subdomain(domain, key)
    return domain, subdomain, R:get_old_value(prefix, domain)
end

-- get data that has been in redis
function R:get_old_value(prefix, key)
    local pre_key = prefix .. '_' .. ngx.md5(key)
    local idx = R:hash_key(pre_key) + 1
    --local idx = self:fnv1a_hash_key(pre_key)
    local old_value = servers[idx]:get(pre_key)
    return pre_key, idx, old_value
end

function R:ping()
    for _,s in pairs(servers) do
        if not s:ping() then
            return false
        end
    end
    return true
end

function R:mem_balance()
    local balance = {}
    local result = {['average_key'] = 0, ['average_mem'] = 0}
    for i,s in pairs(servers) do
        local info = s:info()
        result[i] = {}
        local db0 = info.keyspace.db0
        local keys_num = 0
        for k,_ in pairs(db0) do
            local x,y = find(k, ("%d+"))
            local num = tonumber(sub(k, x, y)) or 0
            keys_num = keys_num + num
        end
        result[i]['keys_num'] = keys_num
        result[i]['mem_used'] = info.memory.used_memory
        result['average_key'] = result['average_key'] + result[i]['keys_num']
        result['average_mem'] = result['average_mem'] + result[i]['mem_used']
    end
    result['average_key'] = result['average_key']/#servers
    result['average_mem'] = result['average_mem']/#servers
    return cjson.encode(result)
end

function R:check_key(ngx)
    local args = ngx.var.args
    local param = ngx.decode_args(args, 0)
    local key = param.key
    local type = param.type
    if not KEY_TYPE[type] then return false end
    local key_in_redis, idx, value = nil, nil, nil
    if KEY_TYPE[type] == 'domain' then
        _,_, key_in_redis, idx, value = R:get_old_domain(type, key)
    else
        key_in_redis, idx, value = R:get_old_value(type, key)
    end
    if not value then return false end
    local result = {['key'] = key_in_redis, 
                    ['location'] = {['ip'] = redis_list[idx].opt.host,
                                    ['port'] = redis_list[idx].opt.port
                                },
                    ['value'] = cjson.decode(value)
                }
    return cjson.encode(result)
end

return R
