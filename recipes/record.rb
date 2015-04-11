#
# Cookbook Name:: firewalldconfig
# Recipe:: record
#
# Copyright:: 2015, The University of Illinois at Chicago

firewalldconfig_readconf.each do |k,v|
  node.set[:firewalld][k] = v
end

node.set[:firewalld][:services] = {}
firewalldconfig_configured_services.each do |service|
  node.set[:firewalld][:services][service] = firewalldconfig_readservice(service)
end

node.set[:firewalld][:zones] = {}
firewalldconfig_configured_zones.each do |zone|
  node.set[:firewalld][:zones][zone] = firewalldconfig_readzone(zone)
end

node.save
