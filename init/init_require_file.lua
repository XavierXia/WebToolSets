-- require init file

require "conf.toolsets_conf"
require "conf.redis_conf"
logger = require "shared.log"
Class = require "shared.Class"
cjson = require "cjson.safe"
util = require "shared.util"
redis = require "resty.redis"
