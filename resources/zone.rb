#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago

# List of all actions supported by provider
actions :create, :create_if_missing, :delete, :merge

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
}

attribute :short, :kind_of => String, :default => nil

attribute :services, :kind_of => Array, :default => nil, :callbacks => {
  "must be an array of service names defined for firewalld" => lambda { |services|
    for service in services
      unless service.is_a?(String)
        return false
      end
      # FIXME? - Check for valid service?
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
