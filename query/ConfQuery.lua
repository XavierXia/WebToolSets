Class = require 'shared.base.Class'
local logger = require 'shared.log'
local http = require 'resty.http'

ConfQuery = Class:new()
local insert = table.insert
local cjson = require 'cjson'
local pairs = pairs
local next = next

local allid = {
        ["line_items_allid"] = "line_items",
        ["creatives_allid"] = "creatives",
        ["campaigns_allid"] = "campaigns",
        ["advertisers_allid"] = "advertisers",
    }

local oplist = {
        ["worker_id"] = 1,
        ["info"] = 1,
        ["global_whitelist"] = 1,
        ["global_blacklist"] = 1,
    }

function ConfQuery:get_all(conf, op)
    local all_id, all = {},{}
    logger:log("test", "op, not id :%s", op)
    for k,v in pairs(conf[op] or {}) do
        insert(all_id, k)
        if not v['id'] then v['id'] = k end  
        insert(all, v)
    end
    return all_id, all
end

function ConfQuery:parse_conf(conf, op, id)
    if oplist[op] then return {conf[op]} end
    -- creatives, advertisers, campaigns, line_items has id
    if id then 
        if id == "all" then 
            local _, all = self:get_all(conf, op)  
            return all
        end
        --return conf and conf[op] and {conf[op][id]} or nil
        if conf and conf[op] and conf[op][id] then
            -- web interface need id
            conf[op][id]['id'] = id
            return {conf[op][id]}
        end
        return nil
    else
        if allid[op] then
            logger:log("test", "allid[op]:%s",tostring(allid[op]))
            local all_id, _ = self:get_all(conf, allid[op])
            return all_id
        end
    end
    return nil
end

function ConfQuery:_get_conf(url)
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        method = "GET",
    }) 
    local conf, err 
    if res.status == 200 and res.body then
        conf, err = cjson.decode(res.body)
        if not conf then 
            logger:log("test", 'decode cms data from proxy server, %s', err)
            return nil 
        end 
    else
        logger:log("test","get conf from proxy server error, %s", tostring(res.status))
    end
--    logger:log("test","conf:%s",cjson.encode(conf))
    return conf
end

function ConfQuery:_handle(ngx)
    local params = ngx.req.get_uri_args()
    local op, id = params.op, params.id
    if not op then return ngx.say(cjson.encode(nil)) end
    logger:log("test", "op:%s, id:%s",op,tostring(id))
    ngx.header['Content-Type'] = 'application/json'
    local conf = self:get_conf()
    logger:log("test", "conf:%s",cjson.encode(conf)) 
    if not next(conf) then 
        logger:log("test", "get %s from cms error!", op)    
        return ngx.say(cjson.encode(nil)) 
    end
    local strjson = self.__index:parse_conf(conf, op, id) or {}
    if not next(strjson) then strjson = nil end 
    ngx.say(cjson.encode(strjson))
end

return ConfQuery
