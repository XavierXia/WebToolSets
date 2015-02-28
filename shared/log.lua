require 'conf.toolsets_conf'

local Class = require 'shared.Class'
local ffi = require('ffi')
local zlog = ffi.load('zlog')

local LOG_CAT = 'ts'

ffi.cdef[[
    void dzlog_fini(void);
    int dzlog_init(const char *confpath, const char *cname);
    int dzlog_set_category(const char *cname);
    void dzlog(const char *file, size_t filelen,
	const char *func, size_t funclen,
	long line, int level,const char *format, ...);
]]


logger = Class:new()
function logger:init()
    local log_filename = CONF_PATH .. 'zlog.conf'
    zlog.dzlog_init(log_filename, LOG_CAT)
end
function logger:debug(fmt, ...)
    zlog.dzlog('',0, '',0, 0,20, fmt, ...)
end
function logger:info(fmt, ...)
    zlog.dzlog('',0, '',0, 0,40, fmt, ...)
end
function logger:notice(fmt, ...)
    zlog.dzlog('',0, '',0, 0,60, fmt, ...)
end
function logger:warn(fmt, ...)
    zlog.dzlog('',0, '',0, 0,80, fmt, ...)
end
function logger:error(fmt, ...)
    zlog.dzlog('',0, '',0, 0,100, fmt, ...)
end
logger:init()

return logger
