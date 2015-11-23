#
# Cookbook Name:: firewalldconfig
# Provider:: default
#
# Copyright:: 2015, The University of Illinois at Chicago

actions :create, :create_if_missing, :merge
default_action :merge

state_attrs :file,
            :cleanup_on_exit,
            :default_zone,
            :ipv6_rpfilter,
            :lockdown,
            :minimal_mark

# Required attributes
attribute :file, kind_of: String, name_attribute: true

# Optional attributes
attribute :cleanup_on_exit, kind_of: [TrueClass, FalseClass]
attribute :default_zone,    kind_of: String
attribute :ipv6_rpfilter,   kind_of: [TrueClass, FalseClass]
attribute :lockdown,        kind_of: [TrueClass, FalseClass]
attribute :minimal_mark,    kind_of: Integer

def ==(other)
  return false unless other.is_a? self.class
  self.class.state_attrs.each do |a|
    return false unless method(a).call == other.method(a).call
  end
  true
end

def file_path
  return file if file[0] == '/'
  "#{FirewalldconfigUtil.etc_dir}/#{file}"
end

def exists
  ::File.file? file_path
end
