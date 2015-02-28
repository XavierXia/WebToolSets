local ConfQuery = require 'query.ConfQuery'
local logger = require 'shared.log'
local ts_cms_budget_url = TS_CMS_BUDGET_URL

CMSBudgetConfQuery = ConfQuery:new({__index = ConfQuery})

function CMSBudgetConfQuery:get_conf()
    if not ts_cms_budget_url then 
        logger:error("%s","ts_cms_budget_url is nil")
        return {}
    end
    return self.__index:_get_conf(ts_cms_budget_url) or {}
end

function CMSBudgetConfQuery:handle(ngx)
    self:_handle(ngx)
end

return CMSBudgetConfQuery
