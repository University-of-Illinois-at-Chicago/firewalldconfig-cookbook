#
# Cookbook Name:: firewalldconfig
# Recipe:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

package 'firewalldconfig'

service "firewalld" do
  action [:enable, :start]
end

firewalldconfig "/etc/firewalld/firewalld.conf" do
  notifies :reload, "service[firewalld]"
end
