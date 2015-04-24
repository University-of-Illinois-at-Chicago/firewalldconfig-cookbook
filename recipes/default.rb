#
# Cookbook Name:: firewalldconfig
# Recipe:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

# recipe xml::ruby fails if patch is not immediately available
package 'patch' do
  action :nothing
end.run_action(:install)

if node['platform_family'] == 'debian'
  package 'ufw' do
    action :remove
  end
  package 'firewall-applet'
end

package 'firewalld'

service 'firewalld' do
  action [:enable, :start]
end

# Use this for reload. At the moment, the firewalld service reload can
# crash firewalld! This is because the the firewalld reload sends a HUP
# signal and, at present, if it receives a second HUP before it finishes
# processing the first then it dies!
execute 'firewalld-reload' do
  command 'firewall-cmd --reload'
  action :nothing
end
