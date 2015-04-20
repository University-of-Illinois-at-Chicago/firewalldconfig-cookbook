#
# Cookbook Name:: firewalldconfig
# Recipe:: record
#
# Copyright:: 2015, The University of Illinois at Chicago

Chef::Provider::Firewalldconfig.read_conf.each do |k, v|
  node.set['firewalld'][k] = v
end

node.set['firewalld']['services'] = {}
Chef::Provider::FirewalldconfigService.configured.each do |name|
  node.set['firewalld']['services'][name] =
    Chef::Provider::FirewalldconfigService.read_configuration(name)
end

node.set['firewalld']['zones'] = {}
Chef::Provider::FirewalldconfigZone.configured.each do |name|
  node.set['firewalld']['zones'][name] =
    Chef::Provider::FirewalldconfigZone.read_configuration(name)
end

node.save
