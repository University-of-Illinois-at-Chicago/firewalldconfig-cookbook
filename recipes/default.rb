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

# Make sure that iptables is stopped and disabled.
service 'iptables' do
  action [:disable, :stop]
end

# Mask iptables service so that it cannot be accidentally started.
#
# While I would like to implement this, it seems there is an SELinux bug
# that currently prevents masking iptables. :-/
#
# execute 'mask iptables.service' do
#   command 'systemctl mask iptables.service'
#   not_if do
#     iptables_service = '/etc/systemd/system/iptables.service'
#     ::File.symlink?(iptables_service) &&
#       ::File.readlink(iptables_service) == '/dev/null'
#   end
# end

# If firewalld is masked, we need to unmask it for actions enable and start
# to function.
execute 'unmask firewalld.service' do
  command 'systemctl unmask firewalld.service'
  only_if do
    firewalld_service = '/etc/systemd/system/firewalld.service'
    ::File.symlink?(firewalld_service) &&
      ::File.readlink(firewalld_service) == '/dev/null'
  end
end

service 'firewalld' do
  action [:enable, :start]
end

include_recipe 'xml::ruby'

# Use this for reload. At the moment, the firewalld service reload can
# crash firewalld! This is because the the firewalld reload sends a HUP
# signal and, at present, if it receives a second HUP before it finishes
# processing the first then it dies!
execute 'firewalld-reload' do
  command 'firewall-cmd --reload'
  action :nothing
end
