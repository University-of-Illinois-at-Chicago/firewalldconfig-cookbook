class FirewalldconfigUtil
  @etc_dir = '/etc/firewalld'
  @lib_dir = '/usr/lib/firewalld'
  @CONFIG_OPT = {
    'CleanupOnExit' => {
      default: true,
      sym: :cleanup_on_exit,
      val: ->(s) { /^(yes|true)/i.match(s) ? true : false }
    },
    'DefaultZone'   => {
      default: 'public',
      sym: :default_zone,
      val: ->(s) { s }
    },
    'IPv6_rpfilter' => {
      default:   true,
      sym: :ipv6_rpfilter,
      val: ->(s) { /^(yes|true)/i.match(s) ? true : false }
    },
    'Lockdown'      => {
      default: false,
      sym: :lockdown,
      val: ->(s) { /^(yes|true)/i.match(s) ? true : false }
    },
    'MinimalMark'   => {
      default:    100,
      sym: :minimal_mark,
      val: ->(s) { s.to_i }
    }
  }

  class << self
    attr_accessor :etc_dir
    attr_accessor :lib_dir
    attr_accessor :CONFIG_OPT
  end 

  def self.read_all_config
    conf = FirewalldconfigUtil.read_conf

    conf['services'] = {}
    FirewalldconfigUtil.configured_service_names.each do |name|
      conf['services'][name] =
        FirewalldconfigUtil.read_service_configuration(name)
    end

    conf['zones'] = {}
    FirewalldconfigUtil.configured_zone_names.each do |name|
      conf['zones'][name] =
        FirewalldconfigUtil.read_zone_configuration(name)
    end

    return conf
  end

  def self.read_conf(path = nil)
    path = "#{FirewalldconfigUtil.etc_dir}/firewalld.conf" if path.nil?
    return {} unless ::File.file? path
    settings = {}
    ::File.open(path).each do |line|
      next unless /^(?<key>\w+)=(?<value>.*)/ =~ line
      opt = @CONFIG_OPT[key]
      next if opt.nil?
      settings[opt[:sym]] = opt[:val].call(value)
    end
    settings
  end

  def self.configured_zone_names
    ::Dir.entries(
      "#{FirewalldconfigUtil.etc_dir}/zones"
    ).grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
  end

  def self.read_zone_configuration(name)
    doc = parse_zone_configuration_xml name
    return nil if doc.nil?
    zone_doc_to_attributes(doc)
  end

  def self.parse_zone_configuration_xml(name)
    require 'nokogiri'
    [
      FirewalldconfigUtil.etc_dir,
      FirewalldconfigUtil.lib_dir
    ].each do |dir|
      xml_path = "#{dir}/zones/#{name}.xml"
      next unless ::File.file? xml_path
      return Nokogiri::XML(::File.open(xml_path))
    end
    nil
  end

  def self.zone_doc_to_attributes(doc)
    attributes = zone_doc_to_attributes_init(doc)
    zone_doc_to_attributes_get_target(attributes, doc)
    zone_doc_to_attributes_get_interfaces(attributes, doc)
    zone_doc_to_attributes_get_ports(attributes, doc)
    zone_doc_to_attributes_get_rules(attributes, doc)
    zone_doc_to_attributes_get_services(attributes, doc)
    zone_doc_to_attributes_get_sources(attributes, doc)
    standardize_zone_attributes(attributes)
  end

  def self.zone_doc_to_attributes_init(doc)
    d_elem = doc.at_css('/zone/description')
    s_elem = doc.at_css('/zone/short')
    {
      description: (d_elem ? d_elem.content : ''),
      short: (s_elem ? s_elem.content : ''),
      interfaces: [],
      ports: [],
      rules: [],
      services: [],
      sources: []
    }
  end

  def self.zone_doc_to_attributes_get_target(attributes, doc)
    case doc.root[:target]
    when 'ACCEPT'
      attributes[:target] = 'accept'
    when 'DROP'
      attributes[:target] = 'drop'
    when '%%REJECT%%'
      attributes[:target] = 'reject'
    end
  end

  def self.zone_doc_to_attributes_get_interfaces(attributes, doc)
    doc.css('/zone/interface').each do |interface|
      attributes[:interfaces].push(interface['name'])
    end
  end
  
  def self.zone_doc_to_attributes_get_ports(attributes, doc)
    doc.css('/zone/port').each do |port|
      attributes[:ports].push(port['port'] + '/' + port['protocol'])
    end
  end
  
  def self.zone_doc_to_attributes_get_rules(attributes, doc)
    doc.css('/zone/rule').each do |element|
      attributes[:rules].push(zone_doc_to_attributes_get_rule(element))
    end
  end

  def self.zone_doc_to_attributes_get_rule(element)
    rule = {}
    zone_doc_to_attributes_get_rule_family(rule, element)
    zone_doc_to_attributes_get_rule_source(rule, element)
    zone_doc_to_attributes_get_rule_destination(rule, element)
    zone_doc_to_attributes_get_rule_service(rule, element)
    zone_doc_to_attributes_get_rule_port(rule, element)
    zone_doc_to_attributes_get_rule_protocol(rule, element)
    zone_doc_to_attributes_get_rule_icmp_block(rule, element)
    zone_doc_to_attributes_get_rule_masquerade(rule, element)
    zone_doc_to_attributes_get_rule_forward_port(rule, element)
    zone_doc_to_attributes_get_rule_log(rule, element)
    zone_doc_to_attributes_get_rule_audit(rule, element)
    zone_doc_to_attributes_get_rule_action(rule, element)
    rule
  end
  
  def self.zone_doc_to_attributes_get_rule_family(rule, element)
    rule[:family] = element[:family] unless element[:family].nil?
  end
  
  def self.zone_doc_to_attributes_get_rule_source(rule, element)
    source = element.at_css('/source')
    return unless source
    rule[:source] = source[:address]
    return unless source[:invert] && source[:invert] =~ /^(true|yes)$/i
    rule[:source_invert] = true
  end
  
  def self.zone_doc_to_attributes_get_rule_service(rule, element)
    service = element.at_css('/service')
    return unless service
    rule[:service] = service[:name]
  end
  
  def self.zone_doc_to_attributes_get_rule_port(rule, element)
    port = element.at_css('/port')
    return unless port
    rule[:port] = port['port'] + '/' + port['protocol']
  end
  
  def self.zone_doc_to_attributes_get_rule_protocol(rule, element)
    protocol = element.at_css('/protocol')
    return unless protocol
    rule[:protocol] = protocol['value']
  end
  
  def self.zone_doc_to_attributes_get_rule_icmp_block(rule, element)
    icmp_block = element.at_css('/icmp-block')
    return unless icmp_block
    rule[:icmp_block] = icmp_block['name']
  end
  
  def self.zone_doc_to_attributes_get_rule_masquerade(rule, element)
    masquerade = element.at_css('/masquerade')
    return unless masquerade
    rule[:masquerade] = true
  end
  
  def self.zone_doc_to_attributes_get_rule_forward_port(rule, element)
    forward_port = element.at_css('/forward-port')
    return unless forward_port
    rule[:forward_port] = {
      port: forward_port['port'],
      protocol: forward_port['protocol']
    }
    rule[:forward_port][:to_port] =
      forward_port['to-port'] if forward_port['to-port']
    rule[:forward_port][:to_addr] =
      forward_port['to-addr'] if forward_port['to-addr']
  end
  
  def self.zone_doc_to_attributes_get_rule_log(rule, element)
    log = element.at_css('/log')
    return unless log
    rule[:log] = {}
    rule[:log][:prefix] = log['prefix'] if log['prefix']
    rule[:log][:level] = log['level'] if log['level']
    log_limit = log.at_css('/limit')
    return unless log_limit
    rule[:log][:limit] = log_limit['value']
  end
  
  def self.zone_doc_to_attributes_get_rule_audit(rule, element)
    audit = element.at_css('/audit')
    return unless audit
    rule[:audit] = {}
    audit_limit = audit.at_css('/limit')
    return unless audit_limit
    rule[:audit][:limit] = audit_limit['value']
  end
  
  def self.zone_doc_to_attributes_get_rule_action(rule, element)
    if element.at_css('/accept')
      rule[:action] = 'accept'
    elsif element.at_css('/drop')
      rule[:action] = 'drop'
    elsif element.at_css('/reject')
      rule[:action] = 'reject'
      if element.at_css('/reject')['type']
        rule[:reject_with] = element.at_css('/reject')['type']
      end
    end
    return unless rule[:action]
    limit = element.at_css("/#{rule[:action]}/limit")
    rule[:limit] = limit[:value] if limit
  end
  
  def self.zone_doc_to_attributes_get_rule_destination(rule, element)
    destination = element.at_css('/destination')
    return unless destination
    rule[:destination] = destination[:address]
    return unless destination[:invert] && destination[:invert] =~ /^(true|yes)$/i
    rule[:destination_invert] = true
  end
  
  def self.zone_doc_to_attributes_get_services(attributes, doc)
    doc.css('/zone/service').each do |service|
      attributes[:services].push(service['name'])
    end
  end
  
  def self.zone_doc_to_attributes_get_sources(attributes, doc)
    doc.css('/zone/source').each do |source|
      attributes[:sources].push(source['address'])
    end
  end
  
  def self.standardize_zone_attributes(attributes)
    [:interfaces, :ports, :rules, :services, :sources].each do |k|
      attributes[k].sort! { |a, b| a.to_s <=> b.to_s }.uniq!
    end
    attributes
  end

  def self.configured_service_names
    ::Dir.entries(
      "#{FirewalldconfigUtil.etc_dir}/services"
    ).grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
  end

  def self.read_service_configuration(name)
    doc = parse_service_configuration_xml name
    return nil if doc.nil?
    service_doc_to_attributes(doc)
  end

  def self.parse_service_configuration_xml(name)
    require 'nokogiri'
    [
      FirewalldconfigUtil.etc_dir,
      FirewalldconfigUtil.lib_dir
    ].each do |dir|
      xml_path = "#{dir}/services/#{name}.xml"
      next unless ::File.file? xml_path
      return Nokogiri::XML(::File.open(xml_path))
    end
    nil
  end

  def self.service_doc_to_attributes(doc)
    attributes = service_doc_to_attributes_init(doc)
    service_doc_to_attributes_get_ports(doc, attributes)
    attributes
  end

  def self.service_doc_to_attributes_init(doc)
    {
      description: doc.at_xpath('/service/description').content,
      short: doc.at_xpath('/service/short').content,
      ports: []
    }
  end

  def self.service_doc_to_attributes_get_ports(doc, attributes)
    doc.xpath('/service/port').each do |port|
      attributes[:ports].push(port['port'] + '/' + port['protocol'])
    end
    attributes[:ports].sort!.uniq!
  end
end
