#!/bin/bash

host="183.56.131.131:2100"
##cms bidder conf
#curl $host"/query_cms_conf?op=info"
#curl $host"/query_cms_conf?op=global_whitelist"
#curl $host"/query_cms_conf?op=global_blacklist"
#curl $host"/query_cms_conf?op=creatives_allid"
#curl $host"/query_cms_conf?op=creatives&id=all"
#curl $host"/query_cms_conf?op=creatives&id=100583"
#curl $host"/query_cms_conf?op=advertisers&id=all"
#curl $host"/query_cms_conf?op=advertisers_allid"
#curl $host"/query_cms_conf?op=advertisers&id=1000"
#curl $host"/query_cms_conf?op=campaigns&id=all"
#curl $host"/query_cms_conf?op=campaigns_allid"
#curl $host"/query_cms_conf?op=campaigns&id=100242"
#curl $host"/query_cms_conf?op=line_items&id=all"
#curl $host"/query_cms_conf?op=line_items_allid"
#curl $host"/query_cms_conf?op=line_items&id=100295"
#
###cms_budget_conf
#curl $host"/query_budget_conf?op=line_items&id=all"
#curl $host"/query_budget_conf?op=line_items_allid"
#curl $host"/query_budget_conf?op=line_items&id=100261"
#curl $host"/query_budget_conf?op=campaigns&id=all"
#curl $host"/query_budget_conf?op=campaigns_allid"
#curl $host"/query_budget_conf?op=campaigns&id=100240"
#
##budget_server info
#curl $host"/query_budget_server?op=line_items&id=all"
#curl $host"/query_budget_server?op=line_items_allid"
#curl $host"/query_budget_server?op=line_items&id=100261"
#curl $host"/query_budget_server?op=worker_id"
#curl $host"/query_budget_server?op=campaigns&id=all"
#curl $host"/query_budget_server?op=campaigns_allid"
#curl $host"/query_budget_server?op=campaigns&id=100240"
#
###budget_client info
#curl $host"/query_budget_client?op=line_items_allid"
#curl $host"/query_budget_client?op=line_items&id=100295"
#curl $host"/query_budget_client?op=line_items&id=all"
#
##redis info
#curl $host"/query_redis?op=redis_status"
#curl $host"/query_redis?op=key_location&key=tvland.com&type=d"
curl $host"/query_redis?op=key_location&key=http://baidu.com&type=u"
#curl $host"/query_redis?op=redis_ping"

#while true; do
#    curl "180.153.42.40:2555/getconf?dc=cn&type=bidder"
#    echo `date`
#    sleep 1s
#done
