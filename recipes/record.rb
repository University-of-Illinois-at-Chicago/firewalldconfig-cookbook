#
# Cookbook Name:: firewalldconfig
# Recipe:: record
#
# Copyright:: 2015, The University of Illinois at Chicago

ruby_block 'firewalldconfig-record' do
  # Trigger record of node attributes if out of sync.
  if JSON.parse(node['firewalld'].inspect.gsub(/\=\>/,':')) == JSON.parse(FirewalldconfigUtil.read_all_config().to_json)
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
