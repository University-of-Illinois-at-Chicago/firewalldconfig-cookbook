#
# Cookbook Name:: firewalldconfig
# Provider:: service
#
# Copyright:: 2015, The University of Illinois at Chicago

actions :create, :create_if_missing, :delete
default_action :create

state_attrs :name,
            :description,
            :ports,
            :short

# Required attributes
attribute :name, kind_of: String, name_attribute: true

# Optional attributes
attribute :description, kind_of: String
attribute :ports, kind_of: Array, callbacks: {
  'must be an array of strings with the format portid[-portid]/protocol' =>
    ->(ports) { validate_ports(ports) }
}
attribute :short, kind_of: String

def ==(other)
  return false unless other.is_a? self.class
  self.class.state_attrs.each do |a|
    return false unless method(a).call == other.method(a).call
  end
  true
end

def file_path
  "#{FirewalldconfigUtil.etc_dir}/services/#{name}.xml"
end

def configured
  ::File.file? file_path
end

def exists
  return true if configured
  ::File.file? "#{FirewalldconfigUtil.lib_dir}/services/#{name}.xml"
end

private

def self.validate_ports(ports)
  ports.reject do |port|
    port.is_a?(String) && /^\d+(-\d+)?\/(tcp|udp)$/.match(port)
  end.empty?
end
