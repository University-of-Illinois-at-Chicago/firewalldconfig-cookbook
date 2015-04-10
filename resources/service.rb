#
# Cookbook Name:: firewalldconfig
# Provider:: service
#
# Copyright:: 2015, The University of Illinois at Chicago

# List of all actions supported by provider
actions :create

# Make push the default action
default_action :create

# Validator stuff. Externalize checks like this to validate options whether
# the are passed individually or part of :settings hash.
ports_validator_text = "must be an array of strings with the format portid[-portid]/protocol"
ports_validator = lambda { |i|
  if i.is_a?(Hash)
    if i.has_key?(:ports)
      ports = i[:ports]
    else
      return true
    end
  else
    ports = i
  end

  for port in ports
    unless port.is_a?(String) and /^\d+(-\d+)?\/(tcp|udp)$/.match(port)
      return false
    end
  end

  return true
}

# Required attributes
attribute :name, :kind_of => String, :name_attribute => true

# Optional attributes
attribute :settings, :kind_of => Hash, :default => {}, :callbacks => {
  ports_validator_text => ports_validator,
}
attribute :description, :kind_of => String, :default => nil
attribute :ports, :kind_of => Array, :default => nil, :callbacks => {
  ports_validator_text => ports_validator,
}
attribute :short, :kind_of => String, :default => nil
