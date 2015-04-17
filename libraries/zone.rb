def firewalldconfig_builtin_zones
  ::Dir.entries('/usr/lib/firewalld/zones/')
    .grep(/^[a-zA-Z].*\.xml$/)
    .collect { |s| s[0..-5] }
end

def firewalldconfig_configured_zones
  ::Dir.entries('/etc/firewalld/zones/')
    .grep(/^[a-zA-Z].*\.xml$/)
    .collect { |s| s[0..-5] }
end

def firewalldconfig_all_zones
  (firewalld_bulitin_zones + firewalldconfig_configured_zones).uniq
end

def firewalldconfig_read_zone_xml(name)
  doc = firewalldconfig_zone_xml_doc name
  return nil if doc.nil?
  zone = firewalldconfig_read_zone_doc_init(doc)
  firewalldconfig_read_zone_doc_target(zone, doc)
  firewalldconfig_read_zone_doc_interfaces(zone, doc)
  firewalldconfig_read_zone_doc_ports(zone, doc)
  firewalldconfig_read_zone_doc_rules(zone, doc)
  firewalldconfig_read_zone_doc_services(zone, doc)
  firewalldconfig_read_zone_doc_sources(zone, doc)
  firewalldconfig_standardize_zone_data(zone)
end

def firewalldconfig_zone_xml_doc(name)
  require 'nokogiri'

  ['/etc/firewalld', '/usr/lib/firewalld'].each do |dir|
    xml_path = "#{dir}/zones/#{name}.xml"
    next unless ::File.file? xml_path
    return Nokogiri::XML(::File.open(xml_path))
  end

  nil
end

def firewalldconfig_read_zone_doc_init(doc)
  {
    description: doc.at_xpath('/zone/description').content,
    short: doc.at_xpath('/zone/short').content,
    interfaces: [],
    ports: [],
    rules: [],
    services: [],
    sources: []
  }
end

def firewalldconfig_read_zone_doc_target(zone, doc)
  case doc.root[:target]
  when 'ACCEPT'
    zone[:target] = :accept
  when 'DROP'
    zone[:target] = :drop
  when '%%REJECT%%'
    zone[:target] = :reject
  end
end

def firewalldconfig_read_zone_doc_interfaces(zone, doc)
  doc.xpath('/zone/interface').each do |interface|
    zone[:interfaces].push(interface['name'])
  end
end

def firewalldconfig_read_zone_doc_ports(zone, doc)
  doc.xpath('/zone/port').each do |port|
    zone[:ports].push(port['port'] + '/' + port['protocol'])
  end
end

def firewalldconfig_read_zone_doc_rules(zone, doc)
  doc.xpath('/zone/rule').each do |rule|
    zone[:rules].push(firewalldconfig_read_zone_rule(rule))
  end
end

def firewalldconfig_read_zone_rule(element)
  rule = {}
  firewalldconfig_read_zone_rule_family(rule, element)
  firewalldconfig_read_zone_rule_source(rule, element)
  firewalldconfig_read_zone_rule_destination(rule, element)
  firewalldconfig_read_zone_rule_service(rule, element)
  # FIXME: protocol icmp_block masquerade forward-port log audit
  firewalldconfig_read_zone_rule_action(rule, element)
  rule
end

def firewalldconfig_read_zone_rule_family(rule, element)
  rule[:family] = element[:family].to_sym unless element[:family].nil?
end

def firewalldconfig_read_zone_rule_source(rule, element)
  source = element.at_xpath('./source')
  return unless source
  rule[:source] = source[:address]
  return unless source[:invert] && source[:invert] =~ /^(true|yes)$/i
  rule[:source_invert] = true
end

def firewalldconfig_read_zone_rule_service(rule, element)
  service = element.at_xpath('./service')
  return unless service
  rule[:service] = service[:name]
end

def firewalldconfig_read_zone_rule_port(rule, element)
  port = element.at_xpath('./port')
  return unless port
  rule[:port] = port['port'] + '/' + port['protocol']
end

def firewalldconfig_read_zone_rule_action(rule, element)
  if element.at_xpath('./accept')
    rule[:action] = :accept
  elsif element.at_xpath('./drop')
    rule[:action] = :drop
  elsif element.at_xpath('./reject')
    rule[:action] = :reject
    if element.at_xpath('./reject')['type']
      rule[:reject_with] = element.at_xpath('./reject')[:type].to_sym
    end
  end
end

def firewalldconfig_read_zone_rule_destination(rule, element)
  destination = element.at_xpath('./destination')
  return unless destination
  rule[:destination] = destination[:address]
  return unless destination[:invert] && destination[:invert] =~ /^(true|yes)$/i
  rule[:destination_invert] = true
end

def firewalldconfig_read_zone_doc_services(zone, doc)
  doc.xpath('/zone/service').each do |service|
    zone[:services].push(service['name'])
  end
end

def firewalldconfig_read_zone_doc_sources(zone, doc)
  doc.xpath('/zone/source').each do |source|
    zone[:sources].push(source['address'])
  end
end

def firewalldconfig_standardize_zone_data(zone)
  [:interfaces, :ports, :rules, :services, :sources].each do |k|
    zone[k].sort! { |a, b| a.to_s <=> b.to_s }.uniq!
  end
  zone
end
