#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago

# List of all actions supported by provider
actions :create, :create_if_missing, :delete, :filter, :merge, :prune

# Make push the default action
default_action :merge

# Required attributes
attribute :name, :kind_of => String, :name_attribute => true

# Optional attributes
attribute :description, :kind_of => String, :default => nil

attribute :interfaces, :kind_of => Array, :default => nil, :callbacks => {
  "must be an array of network interface names" => lambda { |interfaces|
    for interface in interfaces
      unless interface.is_a?(String)
        return false
      end
    end
    return true
  }
}

attribute :ports, :kind_of => Array, :default => nil, :callbacks => {
  "must be an array of strings with the format portid[-portid]/protocol" => lambda { |ports|
    for port in ports
      unless port.is_a?(String) and /^\d+(-\d+)?\/(tcp|udp)$/.match(port)
        return false
      end
    end
    return true
  }
}

attribute :rules, :kind_of => Array, :default => nil, :callbacks => {
  "must be an array of rich rule definitions" => lambda { |rules|
    for rule in rules
      #  family: ipv4 ipv6
      unless [:ipv4,:ipv6,nil].include? rule[:family]
        warn "!! Rule has invalid family: #{family}"
        return false
      end

      #  source: ipv4 or ipv6 address to match family
      if rule[:source]
        case rule[:family]
        when :ipv4
          unless /^\d+\.\d+\.\d+\.\d+(\/\d+)?$/.match( rule[:source] )
            warn "!! Rule has invalid source ipv4 address: #{rule[:source]}";
            return false
          end
        when :ipv6
          unless /^[\da-fA-F:]+(\/\d+)$/.match( rule[:source] )
            warn "!! Rule has invalid source ipv6 address: #{rule[:source]}";
            return false
          end
        else
          warn "!! Rule has source address, #{rule[:source]}, but no family was specified.";
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
        return false unless firewalldconfig_service_exists? rule[:service]
      elsif rule.has_key?(:port)
        return false if rule[:port].match( /^\d+\/(tcp|udp)$/ ).nil?
      elsif rule.has_key?(:protocol)
        return false unless firewalldconfig_protocol_exists? rule[:protocol]
      elsif rule.has_key?(:icmp_block)
        # Actions not allowed with icmp-block
        if rule.has_key?(:action)
          return false
        end
        return false unless firewalldconfig_icmptype_exists? rule[:icmp_block]
      elsif rule.has_key?(:masquerade)
        # Actions not allowed with masquerade
        if rule.has_key?(:action)
          return false
        end
        # masquerade - boolean flag
        return false unless rule[:masquerade] == true
      elsif rule.has_key?(:forward_port)
        # Actions not allowed with forward-port
        if rule.has_key?(:action)
          return false
        end
        return false unless rule[:forward_port].is_a? Hash
        #   port - string representing a port or port range
        return false if rule[:forward_port][:port].match( /^\d+(-\d+)?\/(tcp|udp)$/ ).nil?
        #   to_addr, to_port, or both must be given
        return false unless rule[:forward_port].has_key?(:to_addr) or rule[:forward_port].has_key?(:to_port)
        if rule[:forward_port].has_key? :to_addr
          case rule[:family]
          when :ipv4
            unless /^\d+\.\d+\.\d+\.\d+(\/\d+)$/.match( rule[:forward_port][:to_addr] )
              return false
            end
          when :ipv6
            unless /^[\da-fA-F:]+(\/\d+)$/.match( rule[:forward_port][:to_addr] )
              return false
            end
          else
            return false
          end
        end
        if rule[:forward_port].has_key? :to_port
          return false if rule[:forward_port][:to_port].match( /^\d+(-\d+)$/ ).nil?
        end
      else
        # Must specify one of: service, port, protocol, icmp-block, masquerade, or forward-port
        return false
      end

      if rule.has_key?(:log)
        #  log - hash with keys
        #    prefix - string
        #    level - "emerg", "alert", "crit", "error", "warning", "notice", "info" or "debug"
        #    limit - \d+/[smhd]
        # FIXME
      end

      if rule.has_key?(:audit)
        #  audit - boolean flag
        return false unless rule[:audit] == true
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
          unless %w{icmp-net-unreachable icmp-host-unreachable icmp-port-unreachable icmp-proto-unreachable icmp-net-prohibited icmp-host-prohibited icmp-admin-prohibited tcp-reset}.include? rule[:reject_with]
            warn "!! Rule has invalid ipv4 reject type: #{rule[:reject_with]}";
            return false
          end
        when :ipv6
          unless %w{icmp6-no-route no-route icmp6-adm-prohibited adm-prohibited icmp6-addr-unreachable addr-unreach icmp6-port-unreachable tcp-reset}.include? rule[:reject_with]
            warn "!! Rule has invalid ipv6 reject type: #{rule[:reject_with]}";
            return false
          end
        else
          warn "!! Rule has invalid reject type, #{rule[:reject_with]}, but no address family.";
          return false
        end
      end

    end

    return true
  }
}

attribute :short, :kind_of => String, :default => nil

attribute :services, :kind_of => Array, :default => nil, :callbacks => {
  "must be an array of service names defined for firewalld" => lambda { |services|
    for service in services
      return false unless firewalldconfig_service_exists?(service)
    end
    return true
  }
}

attribute :sources, :kind_of => Array, :default => nil, :callbacks => {
  "must be an array of network subnets in CIDR format" => lambda { |sources|
    for source in sources
      unless source.is_a?(String)
        return false
      end
      # FIXME? - Check for valid ipv4, ipv6 format?
    end
    return true
  }
}

attribute :target, :kind_of => Symbol, :default => nil, :callbacks => {
  "must be one of :default, :accept, :drop, :reject" => lambda { |target|
    [:default,:accept,:drop,:reject].include? target
  }
}
