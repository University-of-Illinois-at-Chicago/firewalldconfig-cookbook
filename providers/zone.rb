#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago


action :create do

  current_zone = firewalldconfig_readzone( new_resource.name )
  zone = {
    :description => new_resource.description,
    :interfaces  => ( new_resource.interfaces || [] ).uniq.sort,
    :ports       => ( new_resource.ports      || [] ).uniq.sort,
    :rules       => ( new_resource.sources    || [] ).uniq.sort,
    :services    => ( new_resource.services   || [] ).uniq.sort,
    :short       => new_resource.short,
    :sources     => ( new_resource.sources    || [] ).uniq.sort,
  }

  if zone[:description].nil?
    if current_zone and current_zone.has_key? :description
      zone[:description] = current_zone[:description]
    else
      zone[:description] = "#{new_resource.name} firewall zone."
    end
  end

  if zone[:short].nil?
    if current_zone and current_zone.has_key? :short
      zone[:short] = current_zone[:short]
    else
      zone[:short] = new_resource.name
    end
  end

  zone[:target] = new_resource.target unless [:default,nil].include? new_resource.target

  if current_zone and zone == current_zone
    Chef::Log.debug "Firewalld zone #{ @new_resource } already created as specified - nothing to do."
    new_resource.updated_by_last_action( false )
  else
    converge_by("Create firewalld zone, #{new_resource.name}, configuration at /etc/firewalld/zones/#{new_resource.name}.xml") do
      firewalldconfig_writezone( new_resource.name, zone )
      new_resource.updated_by_last_action( true )
    end
  end

end

action :create_if_missing do
  if ::File.exists? "/etc/firewalld/zones/#{new_resource.name}.xml"
    Chef::Log.debug("firewalld zone, #{new_resource.name}, already configured at /etc/firewalld/zones/#{new_resource.name}.xml")
    new_resource.updated_by_last_action( false )
  else
    action_create
    new_resource.updated_by_last_action( true )
  end
end

action :delete do
  if ::File.exists? "/etc/firewalld/zones/#{new_resource.name}.xml"
    converge_by("Remove firewalld zone, #{new_resource.name}, configuration at /etc/firewalld/zones/#{new_resource.name}.xml") do
      ::File.unlink "/etc/firewalld/zones/#{new_resource.name}.xml"
      new_resource.updated_by_last_action( true )
    end
  else
    Chef::Log.debug("firewalld zone, #{new_resource.name}, not configured - nothing to do")
    new_resource.updated_by_last_action( false )
  end
end

action :merge do

  if firewalldconfig_configured_zones.include? new_resource.name
    current_zone = firewalldconfig_readzone( new_resource.name )
    zone = current_zone.clone

    zone[:description] = new_resource.description unless new_resource.description.nil?
    zone[:interfaces]  = ( new_resource.interfaces + current_zone[:interfaces] ).uniq.sort unless new_resource.interfaces.nil?
    zone[:ports]       = ( new_resource.ports      + current_zone[:ports]      ).uniq.sort unless new_resource.ports.nil?
    zone[:rules]       = ( new_resource.rules      + current_zone[:rules]      ).uniq.sort unless new_resource.rules.nil?
    zone[:services]    = ( new_resource.services   + current_zone[:services]   ).uniq.sort unless new_resource.services.nil?
    zone[:short]       = new_resource.short unless new_resource.short.nil?
    zone[:sources]     = ( new_resource.sources    + current_zone[:sources]    ).uniq.sort unless new_resource.sources.nil?

    # Target :default means remove any special target.
    if new_resource.target == :default
      zone.delete(:target)
    elsif not new_resource.target.nil?
      zone[:target] = new_resource.target
    end

    if zone == current_zone
      Chef::Log.debug "#{ @new_resource } already is as specified - nothing to do."
      new_resource.updated_by_last_action( false )
    else
      converge_by("Merge changes into firewalld zone, #{new_resource.name}, configuration at /etc/firewalld/zones/#{new_resource.name}.xml") do
        firewalldconfig_writezone( new_resource.name, zone )
        new_resource.updated_by_last_action( true )
      end
    end

  else

    action_create

  end

end
