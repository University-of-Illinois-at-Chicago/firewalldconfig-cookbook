#
# Cookbook Name:: firewalldconfig
# Provider:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

action :configure do

  t = template '/etc/firewalld/firewalld.conf' do
    cookbook 'firewalldconfig'
    source 'firewalld.conf.erb'
    mode 0600
    variables({
      :default_zone => (
        new_resource.settings.has_key?(:default_zone) ? new_resource.settings[:default_zone] : new_resource.default_zone
      ),
      :cleanup_on_exit => (
        new_resource.settings.has_key?(:cleanup_on_exit) ? new_resource.settings[:cleanup_on_exit] : new_resource.cleanup_on_exit
      ),
      :ipv6_rpfilter => (
        new_resource.settings.has_key?(:ipv6_rpfilter) ? new_resource.settings[:ipv6_rpfilter] : new_resource.ipv6_rpfilter
      ),
      :lockdown => (
        new_resource.settings.has_key?(:lockdown) ? new_resource.settings[:lockdown] : new_resource.lockdown
      ),
      :minimal_mark => (
        new_resource.settings.has_key?(:minimal_mark) ? new_resource.settings[:minimal_mark] : new_resource.minimal_mark
      ),
    })
    action :create
  end

  new_resource.updated_by_last_action(t.updated_by_last_action?)

end
