local d_list = require 'shared.domain_list'
local find, sub, gsub, lower = string.find, string.sub, string.gsub, string.lower

local util = {}

--split s whit sep whitin n times      
function util.split(s, sep, n)
    if type(s) ~= 'string' then return {} end
    if not sep or sep == '' then 
        return {s}
    end  
    n=n or math.huge
    local t,c,p1,p2 = {},1,1
    while true do
        p2 = s:find(sep,p1,true)
        if p2 and c <= n then 
            t[#t+1] = s:sub(p1,p2-1)
            p1 = p2+#sep
            c = c+1
        else 
            t[#t+1] = s:sub(p1)
            return t
        end  
    end  
end

--* @function get_subdomain
--* @Synopsis get sub domain 
--* @parameter domain: baidu.com.cn, url: lu.baijia.baidu.com.cn/2we/deea/da.php
--* @return nil or sub_domain(like: "lu.baijia")
function util.get_subdomain(domain, url)
    local all_level_domain = util.get_domain_from_url(url, true)
    local subdomain = nil
    local l = find(all_level_domain, domain, 1, true)-2
    if l > 1 then
        subdomain = sub(all_level_domain, 1, l)
    end
    return subdomain
end

function util.get_domain_from_url(url, list_flag)
    if not url then return nil end
    local u = gsub(lower(url), "^https?[:%*]//", "")
    u = gsub(u, "^www%.", "")
    local _, _, match = find(u, "^([^/:]+)")
    if match then
        if list_flag then return match end
        local tb = util.split(match,'.')
        local top = tb[#tb]
        if #tb <= 1 then return nil end
        if d_list.TOP_LEVEL_DOMAINS[top] then
            local t = tb[#tb-1] ..'.'.. tb[#tb]
            local second = d_list.SECOND_LEVEL_DOMAINS[top]
                and d_list.SECOND_LEVEL_DOMAINS[top][t]
            if second then
                if #tb < 3 then return nil end
                return tb[#tb-2] ..'.'.. t
            end
            return t
        else
            return nil 
        end
    end
    return nil
end

return util
