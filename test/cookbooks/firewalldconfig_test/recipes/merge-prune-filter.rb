#
# Cookbook Name:: firewalldconfig_test
# Recipe:: merge-prune-filter
#
# Copyright:: 2015, The University of Illinois at Chicago

include_recipe 'firewalldconfig'

# Setup default zones to act upon...
{
  mergezone:  %w(10.93.0),
  prunezone:  %w(10.94.0 10.94.1),
  filterzone: %w(10.95.0 10.95.1)
}.each do |zone, subnets|
  execute "firewall-cmd --permanent --new-zone=#{zone}"
  execute "firewall-cmd --permanent --zone=#{zone} --add-service=http"
  execute "firewall-cmd --permanent --zone=#{zone} --add-service=https"
  execute "firewall-cmd --permanent --zone=#{zone} --add-service=ssh"
  execute "firewall-cmd --permanent --zone=#{zone} --add-port=8080/tcp"
  execute "firewall-cmd --permanent --zone=#{zone} --add-port=8443/tcp"
  subnets.each do |subnet|
    execute "firewall-cmd --permanent --zone=#{zone} "\
      "--add-rich-rule='rule family=ipv4 source address=#{subnet}.1 accept'"
    execute "firewall-cmd --permanent --zone=#{zone} "\
      "--add-rich-rule='rule family=ipv4 source address=#{subnet}.2 accept'"
    execute "firewall-cmd --permanent --zone=#{zone} "\
      "--add-source=#{subnet}.0/24"
  end
end

# Now the real stuff
firewalldconfig 'firewalld.conf' do
  default_zone 'public'
  notifies :run, 'execute[firewalld-reload]'
end

firewalldconfig_service 'nrpe' do
  action :create
  short 'NRPE'
  description 'Nagios Remote Plugin Executor'
  ports %w(5666/tcp)
end

firewalldconfig_zone 'mergezone' do
  action :merge
  ports %w(10443/tcp)
  rules [{ family: 'ipv4', source: '10.93.0.3', action: 'accept' }]
  services %w(nrpe)
  sources %w(10.93.1.0/24)
  notifies :run, 'execute[firewalld-reload]'
end

firewalldconfig_zone 'prunezone' do
  action :prune
  ports %w(8080/tcp)
  rules [{ family: 'ipv4', source: '10.94.0.2', action: 'accept' }]
  services %w(ssh)
  sources %w(10.94.1.0/24)
  notifies :run, 'execute[firewalld-reload]'
end

firewalldconfig_zone 'filterzone' do
  action :filter
  ports %w(8443/tcp)
  rules [{ family: 'ipv4', source: '10.95.0.1', action: 'accept' }]
  services %w(http https)
  sources %w(10.95.0.0/24)
  notifies :run, 'execute[firewalld-reload]'
end
