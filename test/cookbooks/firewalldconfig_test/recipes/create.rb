#
# Cookbook Name:: firewalldconfig_test
# Recipe:: create
#
# Copyright:: 2015, The University of Illinois at Chicago

include_recipe 'firewalldconfig'

firewalldconfig 'firewalld.conf' do
  default_zone 'public'
  minimal_mark 200
  notifies :run, 'execute[firewalld-reload]'
end

firewalldconfig_service 'nrpe' do
  action :create
  short 'NRPE'
  description 'Nagios Remote Plugin Executor'
  ports %w(5666/tcp)
end

firewalldconfig_zone 'public' do
  action :create
  ports %w(8080/tcp 8443/tcp 7/udp)
  services %w(http https ssh)
  notifies :run, 'execute[firewalld-reload]'
end

firewalldconfig_zone 'campus' do
  action :create
  services %w(http https nrpe ssh)
  sources %w(128.248.0.0/16 131.193.0.0/16)
  notifies :run, 'execute[firewalld-reload]'
end
