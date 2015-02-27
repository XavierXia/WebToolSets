local ConfQuery = require 'toolsets.ConfQuery'
local logger = require "shared.log"

local ts_cms_bidder_url = TS_CMS_BIDDER_URL

CMSBidderConfQuery = ConfQuery:new({__index = ConfQuery})

function CMSBidderConfQuery:get_conf()
    if not ts_cms_bidder_url then return {} end
    return self.__index:_get_conf(ts_cms_bidder_url) or {}
end

function CMSBidderConfQuery:handle(ngx)
    self:_handle(ngx)
end

return CMSBidderConfQuery
