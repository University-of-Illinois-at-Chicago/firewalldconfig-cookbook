#
# Cookbook Name:: firewalldconfig
# Provider:: service
#
# Copyright:: 2015, The University of Illinois at Chicago

# List of all actions supported by provider
actions :create, :create_if_missing

# Make push the default action
default_action :create

# Required attributes
attribute :name, kind_of: String, name_attribute: true

# Optional attributes
attribute :description, kind_of: String
attribute :ports, kind_of: Array, callbacks: {
  'must be an array of strings with the format portid[-portid]/protocol' =>
    ->(ports) { validate_ports(ports) }
}
attribute :short, kind_of: String

private

def self.validate_ports(ports)
  ports.reject do |port|
    port.is_a?(String) && /^\d+(-\d+)?\/(tcp|udp)$/.match(port)
  end.empty?
end
