#
# Cookbook Name:: firewalldconfig
# Provider:: service
#
# Copyright:: 2015, The University of Illinois at Chicago

action :create do

  current_service = firewalldconfig_readservice( new_resource.name )

  if new_resource.description
    description = new_resource.description
  elsif current_service and current_service[:description]
    description = current_service[:description]
  else
    description = "#{new_resource.name} service."
  end

  if new_resource.short
    short = new_resource.short
  elsif current_service and current_service[:short]
    short = current_service[:short]
  else
    short = new_resource.name
  end

  t = template "/etc/firewalld/services/#{new_resource.name}.xml" do
    cookbook 'firewalldconfig'
    source 'service.xml.erb'
    mode 0644
    variables({
      :description => description,
      :ports => new_resource.ports.uniq.sort,
      :short => short,
    })
    action :create
  end

  new_resource.updated_by_last_action(t.updated_by_last_action?)

end

action :create_if_missing do
  if ::File.exists? "/etc/firewalld/service/#{new_resource.name}.xml"
    Chef::Log.debug("firewalld service #{new_resource.zone} already customized, taking no action.")
    new_resource.updated_by_last_action( false )
  else
    new_resource.updated_by_last_action( true )
  end
end
