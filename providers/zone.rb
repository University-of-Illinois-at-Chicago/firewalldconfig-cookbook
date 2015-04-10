#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago


action :create do

  current_zone = firewalldconfig_readzone( new_resource.name )

  if new_resource.description
    description = new_resource.description
  elsif new_resource.settings.has_key? :description
    description = new_resource.settings[:description]
  elsif current_zone and current_zone[:description]
    description = current_zone[:description]
  else
    description = "#{new_resource.name} firewall zone."
  end

  if new_resource.short
    short = new_resource.short
  elsif new_resource.settings.has_key? :short
    short = new_resource.settings[:short]
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
      :interfaces  => new_resource.interfaces || new_resource.settings[:interfaces] || [],
      :ports       => new_resource.ports      || new_resource.settings[:ports]      || [],
      :rules       => new_resource.rules      || new_resource.settings[:rules]      || [],
      :services    => new_resource.services   || new_resource.settings[:services]   || [],
      :short       => short,
      :sources     => new_resource.sources    || new_resource.settings[:sources]    || [],
      :target      => new_resource.target     || new_resource.settings[:target],
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
  elsif new_resource.settings.has_key? :description
    description = new_resource.settings[:description]
  elsif current_zone and current_zone[:description]
    description = current_zone[:description]
  else
    description = "#{new_resource.name} firewall zone."
  end

  interfaces = new_resource.interfaces || new_resource.settings[:interfaces] || []
  interfaces = (interfaces + current_zone[:interfaces]).uniq

  ports = new_resource.ports || new_resource.settings[:ports] || []
  ports = (ports + current_zone[:ports]).uniq

  rules = new_resource.rules || new_resource.settings[:rules] || []
  rules = (rules + current_zone[:rules]).uniq

  services = new_resource.services || new_resource.settings[:services] || []
  services = (services + current_zone[:services]).uniq

  if new_resource.short
    short = new_resource.short
  elsif new_resource.settings.has_key? :short
    short = new_resource.settings[:short]
  elsif current_zone and current_zone[:short]
    short = current_zone[:short]
  else
    short = new_resource.name
  end

  sources = new_resource.sources || new_resource.settings[:sources] || []
  sources = (sources + current_zone[:sources]).uniq

  target = new_resource.target || new_resource.settings[:target] || current_zone[:target]

  t = template "/etc/firewalld/zones/#{new_resource.name}.xml" do
    cookbook 'firewalldconfig'
    source 'zone.xml.erb'
    mode 0644
    variables({
      :description => description,
      :interfaces  => interfaces,
      :ports       => ports,
      :rules       => rules,
      :services    => services,
      :short       => short,
      :sources     => sources,
      :target      => target,
    })
  end

  new_resource.updated_by_last_action(t.updated_by_last_action?)

end
