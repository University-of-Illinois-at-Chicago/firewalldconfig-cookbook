#
# Cookbook Name:: firewalldconfig
# Provider:: service
#
# Copyright:: 2015, The University of Illinois at Chicago

action :create do

  current_service = firewalldconfig_readservice( new_resource.name )

  if new_resource.ports.nil?
    ports = []
    %w{tcp udp}.each do |proto|
      port = Socket::getservbyname( new_resource.name, proto )
      ports.push "#{port}/#{proto}" unless port.nil?
    end
    if ports.empty?
      raise "Unable to determine ports for service #{new_resource.name}"
    end
    new_resource.ports( ports )
  end

  if new_resource.description.nil?
    new_resource.description( new_resource.name )
  end

  service = {
    :description => new_resource.description,
    :ports       => new_resource.ports.uniq.sort,
    :short       => new_resource.short,
  }

  if service[:description].nil?
    if current_service and current_service.has_key? :description
      service[:description] = current_service[:description]
    else
      service[:description] = "#{new_resource.name} firewall service."
    end
  end

  if service[:short].nil?
    if current_service and current_service.has_key? :short
      service[:short] = current_service[:short]
    else
      service[:short] = new_resource.name
    end
  end

  if current_service and service == current_service
    Chef::Log.debug "Firewalld service #{ new_resource.name } already created as specified - nothing to do."
    new_resource.updated_by_last_action( false )
  else
    converge_by("Create firewalld service, #{ new_resource.name }, configuration at /etc/firewalld/services/#{new_resource.name}.xml") do
      firewalldconfig_writeservice( new_resource.name, service )
      new_resource.updated_by_last_action( true )
    end
  end

end

action :create_if_missing do
  if ::File.exists? "/etc/firewalld/service/#{new_resource.name}.xml"
    Chef::Log.debug("Firewalld service #{new_resource.name} already customized, taking no action.")
    new_resource.updated_by_last_action( false )
  else
    action_create
  end
end
