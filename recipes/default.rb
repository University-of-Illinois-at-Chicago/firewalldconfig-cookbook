#
# Cookbook Name:: firewalldconfig
# Recipe:: default
#
# Copyright (c) 2015 The University of Illinois at Chicago, All Rights Reserved.

package 'firewalldconfig'

service "firewalld" do
  action [:enable, :start]
end

firewalldconfig "/etc/firewalld/firewalld.conf" do
  notifies :reload, "service[firewalld]"
end
