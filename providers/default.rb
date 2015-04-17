#
# Cookbook Name:: firewalldconfig
# Provider:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

action :create do
  current = firewalldconfig_readconf(new_resource.file_path)
  current ||= {
    cleanup_on_exit: true,
    default_zone:    'public',
    ipv6_rpfilter:   true,
    lockdown:        false,
    minimal_mark:    100
  } if current.nil?
  new_resource.updated_by_last_action(update_config(current, :create))
end

action :create_if_missing do
  if ::File.file? new_resaurce.file_path
    Chef::Log.debug("firewalld already configured at #{new_resource.file_path}")
    new_resource.updated_by_last_action(false)
  else
    action_create
  end
end

action :merge do
  current = firewalldconfig_readconf(new_resource.file_path)
  if current.nil?
    action_create
  else
    new_resource.updated_by_last_action(update_config(current, :merge))
  end
end

def build_config(current)
  config = current.clone
  [:cleanup_on_exit, :default_zone, :ipv6_rpfilter, :lockdown, :minimal_mark
  ].each do |attr|
    val = new_resource.method(attr).call
    next if val.nil?
    config[attr] = val
  end
  config
end

def update_config(current, action)
  config = build_config current
  if config == current
    Chef::Log.debug(
      "#{action} #{new_resource.file_path} already as specified."
    )
    return false
  else
    converge_config(config, action)
    return true
  end
end

def converge_config(config, action)
  converge_by "#{action} firewalld conf #{new_resource.file_path}" do
    firewalldconfig_writeconf(config, new_resource.file_path)
    new_resource.updated_by_last_action(true)
  end
end
