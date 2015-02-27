local ConfQuery = require 'toolsets.ConfQuery'
local cjson = require 'cjson'
local ts_budget_server_url = TS_BUDGET_SERVER_URL

BudgetServerConfQuery = ConfQuery:new({__index = ConfQuery})


function BudgetServerConfQuery:get_conf()
    if not ts_budget_server_url then return {} end
    local newconf = {nil,nil,nil}
    local conf = self.__index:_get_conf(ts_budget_server_url)
    newconf["campaigns"] = conf and conf["campaign"] or nil
    newconf["line_items"] = conf and conf["line_item"] or nil
    newconf["worker_id"] = conf and conf["worker_id"] or nil
    conf = nil
    --logger:log('test','in parent, get conf:%s',cjson.encode(newconf))
    return newconf    
end

function BudgetServerConfQuery:handle(ngx)
    self:_handle(ngx)
end

return BudgetServerConfQuery
