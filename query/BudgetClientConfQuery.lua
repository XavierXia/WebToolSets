local ConfQuery = require 'toolsets.ConfQuery'
local ts_budget_client_url = TS_BUDGET_CLIENT_URL

BudgetClientConfQuery = ConfQuery:new({__index = ConfQuery})

function BudgetClientConfQuery:get_conf()
    if not ts_budget_client_url then return {} end
    local conf = {nil}
    local newconf = self.__index:_get_conf(ts_budget_client_url)
    conf["line_items"] = newconf
    return conf
end

function BudgetClientConfQuery:handle(ngx)
    self:_handle(ngx)
end

return BudgetClientConfQuery
