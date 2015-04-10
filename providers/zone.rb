#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago

action :configure do

  t = template "/etc/firewalld/zones/#{new_resource.name}.xml" do
    cookbook 'firewalldconfig'
    source 'zone.xml.erb'
    mode 0644
    variables({
      :description => (
        new_resource.settings.has_key?(:description) ? new_resource.settings[:description] : new_resource.description || "#{new_resource.name} firewall zone"
      ),
      :interfaces => (
        new_resource.settings.has_key?(:interfaces) ? new_resource.settings[:interfaces] : new_resource.interfaces || []
      ),
      :ports => (
        new_resource.settings.has_key?(:ports) ? new_resource.settings[:ports] : new_resource.ports || []
      ),
      :rules => (
        new_resource.settings.has_key?(:rules) ? new_resource.settings[:rules] : new_resource.rules || []
      ),
      :services => (
        new_resource.settings.has_key?(:services) ? new_resource.settings[:services] : new_resource.services || []
      ),
      :short => (
        new_resource.settings.has_key?(:short) ? new_resource.settings[:short] : new_resource.short || new_resource.name
      ),
      :sources => (
        new_resource.settings.has_key?(:sources) ? new_resource.settings[:sources] : new_resource.sources || []
      ),
      :target => (
        new_resource.settings.has_key?(:target) ? new_resource.settings[:target] : new_resource.target
      ),
    })
    action :create
  end

  new_resource.updated_by_last_action(t.updated_by_last_action?)

end
