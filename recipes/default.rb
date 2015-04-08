#
# Cookbook Name:: firewalldconfig
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

package 'firewalldconfig'

service "firewalld" do
  action [:enable, :start]
end
