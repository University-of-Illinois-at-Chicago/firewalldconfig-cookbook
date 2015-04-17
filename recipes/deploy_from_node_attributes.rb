#
# Cookbook Name:: firewalldconfig
# Recipe:: deploy_from_node_attributes
#
# Copyright:: 2015, The University of Illinois at Chicago

include_recipe 'firewalldconfig'

c = Chef::Resource::Firewalldconfig.new(
  '/etc/firewalld/firewalld.conf',
  run_context)
Chef::Resource::Firewalldconfig.state_attrs.each do |k|
  c.method(k).call(node['firewalld'][k]) if node['firewalld'].key? k
end
c.notifies_delayed(:reload, 'service[firewalld]')
c.run_action(:configure)

node['firewalld']['services'].each do |name, settings|
  s = Chef::Resource::FirewalldconfigService.new(name, run_context)
  settings.each do |k, v|
    s.method(k.to_sym).call(v)
  end
  s.notifies_delayed(:reload, 'service[firewalld]')
  s.run_action(:create)
end

node['firewalld']['zones'].each do |name, settings|
  z = Chef::Resource::FirewalldconfigZone.new(name, run_context)
  settings.each do |k, v|
    z.method(k.to_sym).call(v)
  end
  z.notifies_delayed(:reload, 'service[firewalld]')
  z.run_action(:create)
end
