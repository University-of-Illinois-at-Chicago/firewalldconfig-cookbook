#
# Cookbook Name:: firewalldconfig
# Provider:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

action :create do

  # Process defaults for create.
  conf = {
    :cleanup_on_exit => new_resource.cleanup_on_exit.nil? ? true    : new_resource.cleanup_on_exit,
    :default_zone    => new_resource.default_zone.nil?    ? 'public': new_resource.default_zone,
    :ipv6_rpfilter   => new_resource.ipv6_rpfilter.nil?   ? true    : new_resource.ipv6_rpfilter,
    :lockdown        => new_resource.lockdown.nil?        ? false   : new_resource.lockdown,
    :minimal_mark    => new_resource.minimal_mark.nil?    ? 100     : new_resource.minimal_mark,
  }

  current = firewalldconfig_readconf( new_resource.file_path )

  if current == conf
    Chef::Log.debug("firewalld already configured as specified at #{new_resource.file_path}")
    new_resource.updated_by_last_action( false )
  else
    converge_by("Write firewalld conf #{new_resource.file_path}") do
      firewalldconfig_writeconf( conf, new_resource.file_path )
      new_resource.updated_by_last_action( true )
    end
  end

end

action :create_if_missing do
  if ::File.exists? new_resaurce.file_path
    Chef::Log.debug("firewalld already configured at #{new_resource.file_path}")
    new_resource.updated_by_last_action( false )
  else
    action_create
    new_resource.updated_by_last_action( true )
  end
end

action :merge do

  current = firewalldconfig_readconf( new_resource.file_path )

  if current
    conf = current.clone
    conf[:cleanup_on_exit] = new_resource.cleanup_on_exit unless new_resource.cleanup_on_exit.nil?
    conf[:default_zone]    = new_resource.default_zone    unless new_resource.default_zone.nil?
    conf[:ipv6_rpfilter]   = new_resource.ipv6_rpfilter   unless new_resource.ipv6_rpfilter.nil?
    conf[:lockdown]        = new_resource.lockdown        unless new_resource.lockdown.nil?
    conf[:minimal_mark]    = new_resource.minimal_mark    unless new_resource.minimal_mark.nil?

    if current == conf
      Chef::Log.debug("firewalld already configured as specified at #{new_resource.file_path}")
      new_resource.updated_by_last_action( false )
    else
      raise current.to_s + " != " + conf.to_s
      converge_by("Merge changes into firewalld conf #{new_resource.file_path}") do
        firewalldconfig_writeconf( conf, new_resource.file_path )
        new_resource.updated_by_last_action( true )
      end
    end

  else
    action_create
  end

end
