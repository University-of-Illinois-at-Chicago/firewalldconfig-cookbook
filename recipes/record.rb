#
# Cookbook Name:: firewalldconfig
# Recipe:: record
#
# Copyright:: 2015, The University of Illinois at Chicago

node.set[:firewalld][:services] = {}
firewalldconfig_custom_services.each do |service|
  node.set[:firewalld][:services][service] = firewalldconfig_readservice(service)
end

node.set[:firewalld][:zones] = {}
firewalldconfig_custom_zones.each do |zone|
  node.set[:firewalld][:zones][zone] = firewalldconfig_readzone(zone)
end

node.save
