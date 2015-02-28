# WebToolSets
The  bidder web program

***********************************************************************************

# section bidder
可视化界面的items如下：

不用区分baidu/tanx/google/bidswitch平台，现在统一为single CMS


# 1. cms_conf (bidder服务器中提供)

       |-- info (直接显示)
       |-- global_blacklist 
       |-- global_whitelist
       |-- creatives
            |-- id
       |-- advertisers
            |-- id
       |-- campaigns
            |-- id
       |-- line_itmes
            |-- id
       |-- filter
       |-- all（令开启一个新网页打开）
       
接口：

host/query_cms_conf?op=info

host/query_cms_conf?op=global_blacklist

host/query_cms_conf?op=global_whitelist

host/query_cms_conf?op=creatives&id=100188

host/query_cms_conf?op=advertisers&id=100122

host/query_cms_conf?op=campaigns&id=100188

host/query_cms_conf?op=line_items&id=100188

host/query_cms_conf?op=filter

host/query_cms_conf?op=all


#2. cms_budget  (cms bidder服务器中提供)

(like: http://180.153.42.40/cms/index.php/budget_server/config)

       |-- campaigns
            |-- id
       |-- line_itmes
            |-- id
            
host/query_budget_conf?op=campaigns&id=100188

host/query_budget_conf?op=line_items&id=100188


# budget: server_info

（http://bidder.bilin2000.com/read_info，在bidder服务器中提供）

       |-- worker_id
       |-- campaigns
            |-- id
       |-- line_itmes
            |-- id
            
host/query_budget_server?op=worker_id

host/query_budget_server?op=campaigns&id=100188

host/query_budget_server?op=line_items&id=100188


# budget: client_info (在bidder服务器中提供)

       |-- line_itmes
            |-- id
            
host/query_budget_client?op=line_items&id=100188

# 3. bidder暂无

# 4. redis -- proxy

redis:

     |-- mem usage
     |-- key location    
       |-- key,type
     |-- redis ping
     |-- check_upload(允许提交文件)

接口：

host/query_redis?op=mem_usage

host/query_redis?op=key_location&key=12345&type=d

host/query_redis?op=redis_ping

host/query_redis?op=check_upload
