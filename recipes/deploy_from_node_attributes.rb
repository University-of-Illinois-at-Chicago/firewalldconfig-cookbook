#
# Cookbook Name:: firewalldconfig
# Recipe:: deploy_from_node_attributes
#
# Copyright:: 2015, The University of Illinois at Chicago

include_recipe 'firewalldconfig'

firewalldconfig 'firewalld.conf' do
  action :merge
  notifies :run, 'execute[firewalld-reload]'
  node['firewalld'].each do |k, v|
    next if v.is_a?(Hash) || v.is_a?(Array)
    method(k).call v
  end
end

node['firewalld']['services'].each do |name, settings|
  firewalldconfig_service name do
    action :create
    notifies :run, 'execute[firewalld-reload]'
    SymbolizeHelper.symbolize_recursive(settings).each do |k, v|
      method(k).call v
    end
  end
end

node['firewalld']['zones'].each do |name, settings|
  firewalldconfig_zone name do
    action :create
    notifies :run, 'execute[firewalld-reload]'
    SymbolizeHelper.symbolize_recursive(settings).each do |k, v|
      method(k).call v
    end
  end
end
