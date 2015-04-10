#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago


action :create do

  current_zone = firewalldconfig_readzone( new_resource.name )

  if new_resource.description
    description = new_resource.description
  elsif current_zone and current_zone[:description]
    description = current_zone[:description]
  else
    description = "#{new_resource.name} firewall zone."
  end

  if new_resource.short
    short = new_resource.short
  elsif current_zone and current_zone[:short]
    short = current_zone[:short]
  else
    short = new_resource.name
  end

  t = template "/etc/firewalld/zones/#{new_resource.name}.xml" do
    cookbook 'firewalldconfig'
    source 'zone.xml.erb'
    mode 0644
    variables({
      :description => description,
      :interfaces  => new_resource.interfaces.uniq.sort,
      :ports       => new_resource.ports.uniq.sort,
      :rules       => new_resource.rules.uniq.sort,
      :services    => new_resource.services.uniq.sort,
      :short       => short,
      :sources     => new_resource.sources.uniq.sort,
      :target      => new_resource.target,
    })
  end

  new_resource.updated_by_last_action(t.updated_by_last_action?)

end

action :create_if_missing do
  if ::File.exists? "/etc/firewalld/zones/#{new_resource.name}.xml"
    Chef::Log.debug("firewalld zone #{new_resource.zone} already customized, taking no action.")
    new_resource.updated_by_last_action( false )
  else
    new_resource.updated_by_last_action( true )
  end
end

action :delete do
  if ::File.exists? "/etc/firewalld/zones/#{new_resource.name}.xml"
    ::File.unlink "/etc/firewalld/zones/#{new_resource.name}.xml"
    new_resource.updated_by_last_action( true )
  else
    new_resource.updated_by_last_action( false )
  end
end

action :merge do

  current_zone = firewalldconfig_readzone( new_resource.name ) || { :interfaces => [], :ports => [], :rules => [], :services => [], :sources => [] }

  if new_resource.description
    description = new_resource.description
  elsif current_zone and current_zone[:description]
    description = current_zone[:description]
  else
    description = "#{new_resource.name} firewall zone."
  end

  if new_resource.short
    short = new_resource.short
  elsif current_zone and current_zone[:short]
    short = current_zone[:short]
  else
    short = new_resource.name
  end

  target = new_resource.target || current_zone[:target]

  t = template "/etc/firewalld/zones/#{new_resource.name}.xml" do
    cookbook 'firewalldconfig'
    source 'zone.xml.erb'
    mode 0644
    variables({
      :description => description,
      :interfaces  => (new_resource.interfaces + current_zone[:interfaces] ).uniq.sort,
      :ports       => (new_resource.ports      + current_zone[:ports]      ).uniq.sort,
      :rules       => (new_resource.rules      + current_zone[:rules]      ).uniq.sort,
      :services    => (new_resource.services   + current_zone[:services]   ).uniq.sort,
      :short       => short,
      :sources     => (new_resource.sources    + current_zone[:sources]    ).uniq.sort,
      :target      => target,
    })
  end

  new_resource.updated_by_last_action(t.updated_by_last_action?)

end
