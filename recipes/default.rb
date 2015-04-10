#
# Cookbook Name:: firewalldconfig
# Recipe:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

include_recipe "xml::ruby"

package 'firewalld'

service "firewalld" do
  action [:enable, :start]
end
