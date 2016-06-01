#
# Cookbook Name:: firewalldconfig
# Recipe:: record
#
# Copyright:: 2015, The University of Illinois at Chicago

ruby_block 'firewalldconfig-record' do

  # Serialize and standardize attributes from node and system using JSON.
  node_firewalld_attr = node['firewalld'].nil? ? {} : JSON.parse(node['firewalld'].inspect.gsub(/\=\>/,':'))
  system_firewalld_attr = JSON.parse(FirewalldconfigUtil.read_all_config().to_json)

  # Trigger record of node attributes if out of sync.
  if node_firewalld_attr == system_firewalld_attr
    # No need to update, node attributes already match system configuration.
    action :nothing
  else
    action :run
  end

  block do
    node.set['firewalld'] = FirewalldconfigUtil.read_all_config()
    node.save
  end

  # If firewalld-reload is called then update node attributes.
  subscribes :run, 'execute[firewalld-reload]'
end
