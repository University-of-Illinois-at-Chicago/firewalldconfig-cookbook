#
# Cookbook Name:: firewalldconfig_test
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

firewalldconfig "#{ENV['TMPDIR']}/firewalld.conf" do
  action :create
  default_zone 'uic'
end
