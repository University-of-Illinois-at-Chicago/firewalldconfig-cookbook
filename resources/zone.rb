#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, Johnathan Kupferer

# List of all actions supported by provider
actions :configure

# Make push the default action
default_action :configure

# Validator stuff. Externalize checks like this to validate options whether
# the are passed individually or part of :settings hash.
target_validator_text = "must be one of 'default', 'ACCEPT', 'DROP', '%%REJECT%%'" 
target_validator = lambda { |i|
  v = ( i.is_a?(Hash) ? i[:target]: i )
  v = ( i.is_a?(Hash) ? i[:target]: i )
  ['default','ACCEPT','DROP','%%REJECT%%',nil].include? v
}

interfaces_validator_text = "must be an array of network interface names"
interfaces_validator = lambda { |i|
  if i.is_a?(Hash)
    if i.has_key?(:interfaces)
      v = i[:interfaces]
    else
      return true
    end
  else
    v = i
  end

  for n in v
    unless n.is_a?(String)
      return false
    end
  end

  return true
}


ports_validator_text = "must be an array of hashes containing protocol and port number"
ports_validator = lambda { |i|
  if i.is_a?(Hash)
    if i.has_key?(:ports)
      v = i[:ports]
    else
      return true
    end
  else
    v = i
  end

  for port in v
    unless port.is_a?(Hash) and port[:port].is_a?(Integer) and [:tcp,:udp].include? port[:protocol]
      return false
    end
  end

  return true
}

rules_validator_text = "must be an array of rich rule definitions"
rules_validator = lambda { |i|
  if i.is_a?(Hash)
    if i.has_key?(:rules)
      rules = i[:rules]
    else
      return true
    end
  else
    rules = i
  end

  for rule in rules
    #  family: ipv4 ipv6
    unless [:ipv4,:ipv6,nil].include? rule[:family]
      return false
    end

    #  source: ipv4 or ipv6 address to match family
    if rule[:source]
      case rule[:family]
      when :ipv4
        unless /^\d+\.\d+\.\d+\.\d+(\/\d+)$/.match( rule[:source] )
          return false
        end
      when :ipv6
        unless /^[\da-fA-F:]+(\/\d+)$/.match( rule[:source] )
          return false
        end
      else
        return false
      end
    end

    if rule.has_key?(:source_invert)
      unless [TrueClass,FalseClass].include? rule[:source_invert].class
        return false
      end
    end

    #  destination: ipv4 or ipv6 address to match family
    if rule[:destination]
      case rule[:family]
      when :ipv4
        unless /^\d+\.\d+\.\d+\.\d+(\/\d+)$/.match( rule[:destination] )
          return false
        end
      when :ipv6
        unless /^[\da-fA-F:]+(\/\d+)$/.match( rule[:destination] )
          return false
        end
      else
        return false
      end
    end

    if rule.has_key?(:destination_invert)
      unless [TrueClass,FalseClass].include? rule[:destination_invert].class
        return false
      end
    end

    if rule.has_key?(:service)
      # service - string
      # FIXME
    elsif rule.has_key?(:port)
      # port - string \d+(-\d+)?/(tcp|udp)
      # FIXME
    elsif rule.has_key?(:protocol)
      # protocol - string
      # FIXME
    elsif rule.has_key?(:icmp_block)
      # icmp-block - string, one of firewall-cmd --get-icmptypes
      if rule.has_key?(:action)
        return false
      end
      # FIXME
    elsif rule.has_key?(:masquerade)
      # masquerade - boolean
      if rule.has_key?(:action)
        return false
      end
      # FIXME
    elsif rule.has_key?(:forward_port)
      # forward_port - hash with keys:
      #   port - string \d+(-\d+)?/(tcp|udp)
      #   to_addr - ip address string
      #   to_port - \d+(-\d+)?
      if rule.has_key?(:action)
        return false
      end
      # FIXME
    end

    if rule.has_key?(:log)
      #  log - hash with keys
      #    prefix - string
      #    level - "emerg", "alert", "crit", "error", "warning", "notice", "info" or "debug"
      #    limit - \d+/[smhd]
      # FIXME
    end

    if rule.has_key?(:audit)
      #  audit - boolean
      # FIXME
      unless [TrueClass,FalseClass].include? rule[:audit].class
        return false
      end
    end
  
    if rule.has_key?(:action)
      unless [:accept,:reject,:drop].include? rule[:action]
        return false
      end
    end
  
    if rule.has_key?(:reject_with)
      unless rule[:action] == :reject
        return false
      end
  
      case rule[:family]
      when :ipv4
        unless [:icmp_net_unreachable,:icmp_host_unreachable,:icmp_port_unreachable,:icmp_proto_unreachable,:icmp_net_prohibited,:icmp_host_prohibited,:icmp_admin_prohibited,:tcp_reset].include? rule[:reject_with]
          return false
        end
      when :ipv6
        unless [:icmp6_no_route,:no_route,:icmp6_adm_prohibited,:adm_prohibited,:icmp6_addr_unreachable,:addr_unreach,:icmp6_port_unreachable,:tcp_reset].include? rule[:reject_with]
          return false
        end
      else
        return false
      end
    end

  end

  return true
}

services_validator_text = "must be an array of service names defined for firewalld"
services_validator = lambda { |i|
  if i.is_a?(Hash)
    if i.has_key?(:services)
      v = i[:services]
    else
      return true
    end
  else
    v = i
  end

  unless v.is_a?(Array)
    return false
  end

  for n in v
    unless n.is_a?(String)
      return false
    end
    # FIXME? - Check for valid service?
  end

  return true
}

sources_validator_text = "must be an array of network subnets in CIDR format"
sources_validator = lambda { |i|
  if i.is_a?(Hash)
    if i.has_key?(:sources)
      v = i[:sources]
    else
      return true
    end
  else
    v = i
  end

  unless v.is_a?(Array)
    return false
  end

  for source in v
    unless source.is_a?(String)
      return false
    end
    # FIXME? - Check for valid ipv4, ipv6 format?
  end

  return true
}

# Required attributes
attribute :name, :kind_of => String, :name_attribute => true

# Optional attributes
attribute :settings, :kind_of => Hash, :default => {}, :callbacks => {
  target_validator_text => target_validator,
  interfaces_validator_text => interfaces_validator,
  ports_validator_text => ports_validator,
  rules_validator_text => rules_validator,
  services_validator_text => services_validator,
  sources_validator_text => sources_validator,
}
attribute :description, :kind_of => String, :default => nil
attribute :interfaces, :kind_of => Array, :default => nil, :callbacks => {
  interfaces_validator_text => interfaces_validator,
}
attribute :ports, :kind_of => Array, :default => nil, :callbacks => {
  ports_validator_text => ports_validator,
}
attribute :rules, :kind_of => Array, :default => nil, :callbacks => {
  rules_validator_text => rules_validator,
}
attribute :short, :kind_of => String, :default => nil
attribute :services, :kind_of => Array, :default => nil, :callbacks => {
  services_validator_text => services_validator,
}
attribute :sources, :kind_of => Array, :default => nil, :callbacks => {
  sources_validator_text => sources_validator,
}
attribute :target, :kind_of => String, :default => nil, :callbacks => {
  target_validator_text => target_validator,
}
