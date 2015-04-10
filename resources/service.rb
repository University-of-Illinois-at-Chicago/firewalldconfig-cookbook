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
attribute :name, :kind_of => String, :name_attribute => true

# Optional attributes
attribute :description, :kind_of => String, :default => nil
attribute :ports, :kind_of => Array, :default => [], :callbacks => {
  "must be an array of strings with the format portid[-portid]/protocol" => lambda { |ports|
    for port in ports
      unless port.is_a?(String) and /^\d+(-\d+)?\/(tcp|udp)$/.match(port)
        return false
      end
    end
    return true
  }
}
attribute :short, :kind_of => String, :default => nil
