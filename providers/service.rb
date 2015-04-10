#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago

action :create do

  t = template "/etc/firewalld/services/#{new_resource.name}.xml" do
    cookbook 'firewalldconfig'
    source 'service.xml.erb'
    mode 0644
    variables({
      :description => (
        new_resource.settings.has_key?(:description) ? new_resource.settings[:description] : new_resource.description || "#{new_resource.name} firewall zone"
      ),
      :ports => (
        new_resource.settings.has_key?(:ports) ? new_resource.settings[:ports] : new_resource.ports || []
      ),
      :short => (
        new_resource.settings.has_key?(:short) ? new_resource.settings[:short] : new_resource.short || new_resource.name
      ),
    })
    action :create
  end

  new_resource.updated_by_last_action(t.updated_by_last_action?)

end
