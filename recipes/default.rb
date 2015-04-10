#
# Cookbook Name:: firewalldconfig
# Recipe:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

package 'firewalld'
chef_gem 'nokogiri' do
  compile_time false
end

service "firewalld" do
  action [:enable, :start]
end
