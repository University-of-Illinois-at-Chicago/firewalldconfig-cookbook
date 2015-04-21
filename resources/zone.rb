#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago

actions :create, :create_if_missing, :delete, :filter, :merge, :prune
default_action :merge

state_attrs :name,
            :description,
            :interfaces,
            :ports,
            :rules,
            :services,
            :short,
            :sources,
            :target

# Name attribute
attribute :name, kind_of: String, name_attribute: true

# Optional attributes
attribute :description, kind_of: String

attribute :interfaces, kind_of: Array, callbacks: {
  'must be an array of network interface names' =>
    ->(interfaces) { validate_interfaces(interfaces) }
}

attribute :ports, kind_of: Array, callbacks: {
  'must be an array of strings with the format portid[-portid]/protocol' =>
    ->(ports) { validate_ports(ports) }
}

attribute :rules, kind_of: Array, callbacks: {
  'has invalid family' =>
    ->(rules) { validate_rules_family(rules) },
  'has source but no family' =>
    ->(rules) { validate_rules_address_has_family(rules, :source) },
  'has invalid source address' =>
    ->(rules) { validate_rules_ip(rules, :source) },
  'has invalid source_invert' =>
    ->(rules) { validate_rules_invert(rules, :source, :source_invert) },
  'has destination but no family' =>
    ->(rules) { validate_rules_address_has_family(rules, :destination) },
  'has invalid destination address' =>
    ->(rules) { validate_rules_ip(rules, :destination) },
  'has invalid destination_invert' =>
    lambda do |rules|
      validate_rules_invert(rules, :destination, :destination_invert)
    end,
  'cannot have more than one of service, port, protocol, icmp_block, '\
  'masquerade, or forward_port' =>
    ->(rules) { validate_rules_single_element(rules) },
  'has invalid service value' =>
    ->(rules) { validate_rules_service(rules) },
  'has invalid port value' =>
    ->(rules) { validate_rules_port(rules) },
  'has invalid protocol value' =>
    ->(rules) { validate_rules_protocol(rules) },
  'has invalid icmp_block value' =>
    ->(rules) { validate_rules_icmp_block(rules) },
  'has invalid masquerade value' =>
    ->(rules) { validate_rules_is_true(rules, :masquerade) },

  # forward_port
  'forward_port must be a hash' =>
    ->(rules) { validate_rules_is_hash(rules, :forward_port) },
  'has invalid forward_port port value' =>
    ->(rules) { validate_rules_forward_has_port(rules) },
  'has invalid forward port value' =>
    ->(rules) { validate_rules_forward_port(rules, :port) },
  'has forward_port without to_addr or to_port' =>
    ->(rules) { validate_rules_forward_port_has_to_what(rules) },
  'has forward to_addr without family' =>
    ->(rules) { validate_rules_forward_to_addr_has_family(rules) },
  'has invalid forward to_port value' =>
    ->(rules) { validate_rules_forward_port(rules, :to_port) },
  'has invalid forward to_addr value' =>
    ->(rules) { validate_rules_forward_to_addr(rules) },

  # log
  'log must be a hash' =>
    ->(rules) { validate_rules_is_hash(rules, :log) },
  # FIXME: Validate more log stuff
  #    prefix - string
  #    level - %w(emerg alert crit error warning notice info debug)
  #    limit - \d+/[smhd]

  'has invalid audit value' =>
    ->(rules) { validate_rules_is_true(rules, :audit) },
  'action not allowed with icmp_block, masquerade, or forward_port' =>
    ->(rules) { validate_rules_no_action_allowed(rules) },
  'has invalid action' =>
    ->(rules) { validate_rules_action(rules) },
  'has invalid reject_with type' =>
    ->(rules) { validate_rules_reject_with(rules) }
}

attribute :services, kind_of: Array, callbacks: {
  'must be an array of service names defined for firewalld' =>
  lambda do |services|
    services.each do |service|
      # FIXME: It would be good if we could actually validate services, but the
      # problem is how to detect if another pending converge would add a missing
      # service we would detect here at compile time.
      return true if service.is_a? String
    end
    return true
  end
}

attribute :short, kind_of: String

attribute :sources, kind_of: Array, callbacks: {
  'must be an array of network subnets in CIDR format' =>
  lambda do |sources|
    sources.each do |source|
      return false unless source.is_a?(String)
      # FIXME? - Check for valid ipv4, ipv6 format?
    end
    return true
  end
}

attribute :target, kind_of: Symbol, callbacks: {
  'must be one of "default", "accept", "drop", "reject"' => lambda do |target|
    %w(default accept drop reject).include? target
  end
}

def ==(other)
  return false unless other.is_a? self.class
  self.class.state_attrs.each do |a|
    return false unless method(a).call == other.method(a).call
  end
  true
end

def file_path
  "#{Chef::Provider::Firewalldconfig.etc_dir}/zones/#{name}.xml"
end

def configured
  ::File.file? file_path
end

def exists
  return true if configured
  ::File.file? "#{Chef::Provider::Firewalldconfig.lib_dir}/zones/#{name}.xml"
end

private

VALID_ADDRESS_FAMILIES = %(ipv4 ipv6)
RICHRULE_SINGLE_ELEMENTS = [
  :service,
  :port,
  :protocol,
  :icmp_block,
  :masquerade,
  :forward_port
]
def self.firewalld_icmptypes
  cmd = Mixlib::ShellOut.new('firewall-cmd --get-icmptypes')
  cmd.run_command
  cmd.stdout.split(' ')
end
FIREWALLD_ICMP_TYPES = firewalld_icmptypes
IPV4_REJECT_TYPES = %w(
  icmp-net-unreachable
  icmp-host-unreachable
  icmp-port-unreachable
  icmp-proto-unreachable
  icmp-net-prohibited
  icmp-host-prohibited
  icmp-admin-prohibited
  tcp-reset
)
IPV6_REJECT_TYPES = %w(
  icmp6-no-route
  no-route
  icmp6-adm-prohibited
  adm-prohibited
  icmp6-addr-unreachable
  addr-unreach
  icmp6-port-unreachable
  tcp-reset
)

def self.validate_interfaces(interfaces)
  interfaces.reject do |interface|
    # FIXME: Is there a way to actually validate interface names? The trick
    # here is that some interfaces that may need to be handled may be software
    # interfaces and so may not be present...
    interface.is_a?(String)
  end.empty?
end

def self.validate_ports(ports)
  ports.reject do |port|
    port.is_a?(String) && /^\d+(-\d+)?\/(tcp|udp)$/.match(port)
  end.empty?
end

def self.validate_rules_family(rules)
  rules.reject do |rule|
    next true unless rule.key? :family
    VALID_ADDRESS_FAMILIES.include? rule[:family]
  end.empty?
end

def self.validate_rules_address_has_family(rules, attr)
  rules.reject do |rule|
    next true unless rule.key? attr
    rule.key? :family
  end.empty?
end

def self.validate_rules_ip(rules, attr)
  rules.reject do |rule|
    next true unless rule.key? attr
    Chef::Resource::FirewalldconfigZone.validate_ip_address(
      rule[attr], rule[:family]
    )
  end.empty?
end

def self.validate_ip_address(addr, family)
  case family
  when 'ipv4'
    return /^\d+\.\d+\.\d+\.\d+(\/\d+)?$/.match(addr)
  when 'ipv6'
    return /^[\da-fA-F:]+(\/\d+)$/.match(addr)
  else
    return false
  end
end

def self.validate_rules_invert(rules, addr_attr, invert_attr)
  rules.reject do |rule|
    next true unless rule.key? invert_attr
    next false unless rule.key? addr_attr
    rule[invert_attr] == true
  end.empty?
end

def self.validate_rules_single_element(rules)
  rules.reject do |rule|
    RICHRULE_SINGLE_ELEMENTS.collect { |e| rule.key? e }.length > 1
  end.empty?
end

def self.validate_rules_service(rules)
  rules.reject do |rule|
    next true unless rule.key? :service
    rule[:service].is_a? String
  end.empty?
end

def self.validate_rules_port(rules)
  rules.reject do |rule|
    next true unless rule.key? :port
    rule[:port].match(/^\d+(-\d+)?\/(tcp|udp)$/)
  end.empty?
end

def self.validate_rules_protocol(rules)
  rules.reject do |rule|
    next true unless rule.key? :protocol
    # Assume someing giving an numeric protocol number knows what they are
    # doing.
    next true if rule[:protocol].is_a? Integer
    validate_protocol_exists? rule[:protocol]
  end.empty?
end

def self.validate_protocol_exists?(proto)
  fh = ::File.open '/etc/protocols'
  fh.each do |line|
    match = line.match(/^(\S+)/)
    next if match.nil?
    return true if proto == match[1]
  end
  false
end

def self.validate_rules_icmp_block(rules)
  rules.reject do |rule|
    next true unless rule.key? :icmp_block
    FIREWALLD_ICMP_TYPES.include? name
  end.empty?
end

def self.validate_rules_is_hash(rules, which)
  rules.reject do |rule|
    next true unless rule.key? which
    rule[which].is_a? Hash
  end.empty?
end

def self.validate_rules_is_true(rules, which)
  rules.reject do |rule|
    next true unless rule.key? which
    rule[which] == true
  end.empty?
end

def self.validate_rules_forward_has_port(rules)
  rules.reject do |rule|
    next true unless rule.key? :forward_port
    rule[:forward_port].key? :port
  end.empty?
end

def self.validate_rules_forward_port(rules, which)
  rules.reject do |rule|
    next true unless rule.key? :forward_port
    next true unless rule[:forward_port].key? which
    rule[:forward_port][which].match(/^\d+(-\d+)?\/(tcp|udp)$/)
  end.empty?
end

def self.validate_rules_forward_port_has_to_what(rules)
  rules.reject do |rule|
    next true unless rule.key? :forward_port
    next true if rule[:forward_port].key? :to_addr
    next true if rule[:forward_port].key? :to_port
    false
  end.empty?
end

def self.validate_rules_forward_to_addr_has_family(rules)
  rules.reject do |rule|
    next true unless rule.key? :forward_port
    next true unless rule[:forward_port].key? :to_addr
    rule.key? :family
  end.empty?
end

def self.validate_rules_forward_to_addr(rules)
  rules.reject do |rule|
    next true unless rule.key? :forward_port
    next true unless rule[:forward_port].key? :to_addr
    Chef::Resource::FirewalldconfigZone.validate_ip_address(
      rule[:forward_port][:to_addr], rule[:family]
    )
  end.empty?
end

def self.validate_rules_no_action_allowed(rules)
  rules.reject do |rule|
    next true unless rule.key? :icmp_block
    next true unless rule.key? :masquerade
    next true unless rule.key? :forward_port
    !rule.key? :action
  end.empty?
end

def self.validate_rules_action(rules)
  rules.reject do |rule|
    next true unless rule.key? :action
    %w(accept reject drop).include? rule[:action]
  end.empty?
end

def self.validate_rules_reject_with(rules)
  rules.reject do |rule|
    next true unless rule.key? :reject_with
    validate_reject_type rule[:reject_with], rule[:family]
  end.empty?
end

def self.validate_reject_type(reject_type, family)
  case family
  when 'ipv4'
    IPV4_REJECT_TYPES.include? reject_type
  when 'ipv6'
    IPV6_REJECT_TYPES.include? reject_type
  else
    false
  end
end
