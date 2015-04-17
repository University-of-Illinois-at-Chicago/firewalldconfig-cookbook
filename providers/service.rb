#
# Cookbook Name:: firewalldconfig
# Provider:: service
#
# Copyright:: 2015, The University of Illinois at Chicago

action :create do
  current_service = firewalldconfig_read_service_xml(new_resource.name)
  current_service ||= {
    short:       new_resource.name,
    description: "#{new_resource.name} firewalld service.",
    ports:       []
  }
  new_resource.updated_by_last_action(update_service(current_service, :create))
end

action :create_if_missing do
  if ::File.file? service_xml
    Chef::Log.debug("service #{new_resource.name} already configured.")
    new_resource.updated_by_last_action(false)
    next
  end

  action_create
end

action :delete do
  if ::File.file? service_xml
    converge_by(
      "remove firewalld service #{new_resource.name} from #{service_xml}"
    ) do
      ::File.unlink service_xml
      new_resource.updated_by_last_action(true)
    end
  else
    Chef::Log.debug "firewalld service, #{new_resource.name} not configured"
    new_resource.updated_by_last_action(false)
  end
end

def use_standard_service_ports(service)
  ports = []
  %w(tcp udp).each do |proto|
    port = Socket.getservbyname(new_resource.name, proto)
    ports.push "#{port}/#{proto}" unless port.nil?
  end
  if ports.empty?
    fail "Unable to determine ports for service #{new_resource.name}"
  end
  service[:ports] = ports
end

def build_service(current_service)
  service = current_service.clone
  [:description, :short, :ports].each do |attr|
    val = new_resource.method(attr).call
    next if val.nil?
    service[attr] = val
  end
  use_standard_service_ports service if new_resource.ports.nil?
  service[:ports].sort!.uniq!
  service
end

def update_service(current_service, action)
  service = build_service current_service
  if service == current_service
    Chef::Log.debug "#{action} #{ new_resource.name } already as specified."
    return false
  else
    converge_service(service, action)
    return true
  end
end

def converge_service(service, action)
  converge_by(
    "#{action} firewalld service #{new_resource.name} at #{service_xml}"
  ) do
    write_service_xml(service)
    new_resource.updated_by_last_action(true)
  end
end

def service_xml
  "/etc/firewalld/services/#{new_resource.name}.xml"
end

def write_service_xml(service)
  doc = service_doc_init(service)
  service_doc_add_ports(service, doc)
  write_service_doc(doc)
end

def service_doc_init(service)
  doc = Nokogiri::XML::Document.parse(<<EOF)
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short></short>
  <description></description>
</service>
EOF
  doc.at_xpath('/service/short').content = service[:short]
  doc.at_xpath('/service/description').content = service[:description]
  doc
end

def service_doc_add_ports(service, doc)
  service[:ports].each do |port|
    (port, proto) = port.split('/')
    e = doc.create_element(
      'port',
      protocol: proto,
      port: port
    )
    doc.root.add_child e
  end
end

def write_service_doc(doc)
  fh = ::File.new(service_xml, 'w')
  doc.write_xml_to fh, encoding: 'UTF-8'
  fh.close
end
