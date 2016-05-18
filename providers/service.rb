#
# Cookbook Name:: firewalldconfig
# Provider:: service
#
# Copyright:: 2015, The University of Illinois at Chicago

def whyrun_supported?
  true
end

action :create do
  new_resource.updated_by_last_action(merge_and_converge)
end

action :create_if_missing do
  if @current_resource.configured
    Chef::Log.debug "firewalld service #{new_resource.name} already configured."
    new_resource.updated_by_last_action(false)
    next
  end

  action_create
end

action :delete do
  unless @current_resource.configured
    Chef::Log.debug(
      "firewalld service #{new_resource.name} not configured"
    )
    new_resource.updated_by_last_action(false)
    next
  end

  converge_by(
    "remove firewalld service #{new_resource.name} "\
    "from #{new_resource.file_path}"
  ) do
    ::File.unlink new_resource.file_path
    new_resource.updated_by_last_action(true)
  end
end

def self.builtin
  ::Dir.entries(
    "#{FirewalldconfigUtil.lib_dir}/services"
  ).grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def self.configured
  ::Dir.entries(
    "#{FirewalldconfigUtil.etc_dir}/services"
  ).grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def load_current_resource
  @current_resource = Chef::Resource::FirewalldconfigService.new(
    @new_resource.name
  )
  @current_resource.name(@new_resource.name)
  conf = FirewalldconfigUtil.read_service_configuration(@current_resource.name)
  if conf
    conf.each do |a, v|
      @current_resource.method(a).call(v)
    end
  else
    @current_resource.short(@new_resource.name)
    @current_resource.description("#{@new_resource.name} firewalld service.")
    @current_resource.ports([])
  end
end

def merge_current_into_new
  @new_resource.description(
    @current_resource.description
  ) if @new_resource.description.nil?
  @new_resource.ports(
    @current_resource.ports.clone
  ) if @new_resource.ports.nil?
  @new_resource.short(
    @current_resource.short
  ) if @new_resource.short.nil?
end

def merge_and_converge
  # Add standard ports if new lacks them
  add_standard_service_ports if new_resource.ports.nil?

  # Fill out any missing values in @new_resource from @current_resource
  merge_current_into_new

  if @new_resource == @current_resource
    Chef::Log.debug "#{action} #{ new_resource.name } already as specified."
    return false
  end

  converge_by(
    "#{action} firewalld service #{new_resource.name} "\
    "at #{new_resource.file_path}"
  ) do
    write_service_xml
    new_resource.updated_by_last_action(true)
  end
  true
end

def add_standard_service_ports
  ports = []
  %w(tcp udp).each do |proto|
    port = Socket.getservbyname(new_resource.name, proto)
    ports.push "#{port}/#{proto}" unless port.nil?
  end
  if ports.empty?
    fail "Unable to determine ports for service #{new_resource.name}"
  end
  new_resource.ports(ports.uniq.sort)
end

def write_service_xml
  doc = service_doc_init
  service_doc_add_ports(doc)
  write_service_doc(doc)
end

def write_service_doc(doc)
  fh = ::File.new(new_resource.file_path, 'w')
  doc.write_xml_to fh, encoding: 'UTF-8'
  fh.close
end

def service_doc_init
  doc = Nokogiri::XML(<<EOF) { |x| x.noblanks }
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short></short>
  <description></description>
</service>
EOF
  doc.at_css('/service/short').content = @new_resource.short
  doc.at_css('/service/description').content = @new_resource.description
  doc
end

def service_doc_add_ports(doc)
  @new_resource.ports.each do |port|
    (port, proto) = port.split('/')
    e = doc.create_element(
      'port',
      protocol: proto,
      port: port
    )
    doc.root.add_child e
  end
end
