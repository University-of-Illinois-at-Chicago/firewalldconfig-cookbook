#
# Cookbook Name:: firewalldconfig
# Provider:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

# List of all actions supported by provider
actions :configure

# Make push the default action
default_action :configure

# Required attributes
attribute :file_path, :kind_of => String, :name_attribute => true

# Optional attributes
attribute :cleanup_on_exit, :kind_of => [TrueClass, FalseClass], :default => true
attribute :default_zone,    :kind_of => String,                  :default => 'public'
attribute :ipv6_rpfilter,   :kind_of => [TrueClass, FalseClass], :default => true
attribute :lockdown,        :kind_of => [TrueClass, FalseClass], :default => false
attribute :minimal_mark,    :kind_of => [Integer],               :default => 100
