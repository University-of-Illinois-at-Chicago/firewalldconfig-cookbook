#
# Cookbook Name:: firewalldconfig
# Recipe:: record
#
# Copyright:: 2015, The University of Illinois at Chicago

ruby_block 'firewalldconfig-record' do
  action :run
  block do
    FirewalldconfigUtil.read_conf.each do |k, v|
      node.set['firewalld'][k] = v
    end

    node.set['firewalld']['services'] = {}
    FirewalldconfigUtil.configured_service_names.each do |name|
      node.set['firewalld']['services'][name] =
        FirewalldconfigUtil.read_service_configuration(name)
    end

    node.set['firewalld']['zones'] = {}
    FirewalldconfigUtil.configured_zone_names.each do |name|
      node.set['firewalld']['zones'][name] =
        FirewalldconfigUtil.read_zone_configuration(name)
    end

    node.save
  end
end
