#
# Cookbook Name:: firewalldconfig
# Provider:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

# List of all actions supported by provider
actions :create, :create_if_missing, :merge

# Make push the default action
default_action :merge

# Required attributes
attribute :file_path, :kind_of => String, :name_attribute => true

# Optional attributes
attribute :cleanup_on_exit, :kind_of => [TrueClass, FalseClass]
attribute :default_zone,    :kind_of => String
attribute :ipv6_rpfilter,   :kind_of => [TrueClass, FalseClass]
attribute :lockdown,        :kind_of => [TrueClass, FalseClass]
attribute :minimal_mark,    :kind_of => Integer
