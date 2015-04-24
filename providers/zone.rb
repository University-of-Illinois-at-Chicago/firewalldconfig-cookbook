#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago

def whyrun_supported?
  true
end

action :create do
  new_resource.updated_by_last_action(merge_and_converge ->(_o, u) { u })
end

action :create_if_missing do
  if @current_resource.configured
    Chef::Log.debug "firewalld zone #{new_resource.name} already configured."
    new_resource.updated_by_last_action(false)
    next
  end

  action_create
end

action :delete do
  unless @current_resource.configured
    Chef::Log.debug(
      "firewalld zone #{new_resource.name} not configured"
    )
    new_resource.updated_by_last_action(false)
    next
  end

  converge_by(
    "remove firewalld zone #{new_resource.name} "\
    "from #{new_resource.file_path}"
  ) do
    ::File.unlink new_resource.file_path
    new_resource.updated_by_last_action(true)
  end
end

action :filter do
  unless @current_resource.exists
    Chef::Log.debug(
      "filter firewalld zone #{ new_resource.name } does not exist"
    )
    new_resource.updated_by_last_action(false)
    next
  end
  new_resource.updated_by_last_action(merge_and_converge ->(o, u) { o & u })
end

action :merge do
  new_resource.updated_by_last_action(merge_and_converge ->(o, u) { o + u })
end

action :prune do
  unless @current_resource.exists
    Chef::Log.debug(
      "prune firewalld zone #{ new_resource.name } does not exist"
    )
    new_resource.updated_by_last_action(false)
    next
  end
  new_resource.updated_by_last_action(merge_and_converge ->(o, u) { o - u })
end

def self.builtin
  ::Dir.entries(
    "#{Chef::Provider::Firewalldconfig.lib_dir}/zones"
  ).grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def self.configured
  ::Dir.entries(
    "#{Chef::Provider::Firewalldconfig.etc_dir}/zones"
  ).grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def self.read_configuration(name)
  doc = parse_configuration_xml name
  return nil if doc.nil?
  doc_to_attributes(doc)
end

def self.parse_configuration_xml(name)
  require 'nokogiri'
  [
    Chef::Provider::Firewalldconfig.etc_dir,
    Chef::Provider::Firewalldconfig.lib_dir
  ].each do |dir|
    xml_path = "#{dir}/zones/#{name}.xml"
    next unless ::File.file? xml_path
    return Nokogiri::XML(::File.open(xml_path))
  end
  nil
end

def self.doc_to_attributes(doc)
  attributes = doc_to_attributes_init(doc)
  doc_to_attributes_get_target(attributes, doc)
  doc_to_attributes_get_interfaces(attributes, doc)
  doc_to_attributes_get_ports(attributes, doc)
  doc_to_attributes_get_rules(attributes, doc)
  doc_to_attributes_get_services(attributes, doc)
  doc_to_attributes_get_sources(attributes, doc)
  standardize_attributes(attributes)
end

def self.doc_to_attributes_init(doc)
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

def self.doc_to_attributes_get_target(attributes, doc)
  case doc.root[:target]
  when 'ACCEPT'
    attributes[:target] = 'accept'
  when 'DROP'
    attributes[:target] = 'drop'
  when '%%REJECT%%'
    attributes[:target] = 'reject'
  end
end

def self.doc_to_attributes_get_interfaces(attributes, doc)
  doc.css('/zone/interface').each do |interface|
    attributes[:interfaces].push(interface['name'])
  end
end

def self.doc_to_attributes_get_ports(attributes, doc)
  doc.css('/zone/port').each do |port|
    attributes[:ports].push(port['port'] + '/' + port['protocol'])
  end
end

def self.doc_to_attributes_get_rules(attributes, doc)
  doc.css('/zone/rule').each do |element|
    attributes[:rules].push(doc_to_attributes_get_rule(element))
  end
end

def self.doc_to_attributes_get_rule(element)
  rule = {}
  doc_to_attributes_get_rule_family(rule, element)
  doc_to_attributes_get_rule_source(rule, element)
  doc_to_attributes_get_rule_destination(rule, element)
  doc_to_attributes_get_rule_service(rule, element)
  doc_to_attributes_get_rule_port(rule, element)
  doc_to_attributes_get_rule_protocol(rule, element)
  doc_to_attributes_get_rule_icmp_block(rule, element)
  doc_to_attributes_get_rule_masquerade(rule, element)
  doc_to_attributes_get_rule_forward_port(rule, element)
  doc_to_attributes_get_rule_log(rule, element)
  doc_to_attributes_get_rule_audit(rule, element)
  doc_to_attributes_get_rule_action(rule, element)
  rule
end

def self.doc_to_attributes_get_rule_family(rule, element)
  rule[:family] = element[:family] unless element[:family].nil?
end

def self.doc_to_attributes_get_rule_source(rule, element)
  source = element.at_css('/source')
  return unless source
  rule[:source] = source[:address]
  return unless source[:invert] && source[:invert] =~ /^(true|yes)$/i
  rule[:source_invert] = true
end

def self.doc_to_attributes_get_rule_service(rule, element)
  service = element.at_css('/service')
  return unless service
  rule[:service] = service[:name]
end

def self.doc_to_attributes_get_rule_port(rule, element)
  port = element.at_css('/port')
  return unless port
  rule[:port] = port['port'] + '/' + port['protocol']
end

def self.doc_to_attributes_get_rule_protocol(rule, element)
  protocol = element.at_css('/protocol')
  return unless protocol
  rule[:protocol] = protocol['value']
end

def self.doc_to_attributes_get_rule_icmp_block(rule, element)
  icmp_block = element.at_css('/icmp-block')
  return unless icmp_block
  rule[:icmp_block] = icmp_block['name']
end

def self.doc_to_attributes_get_rule_masquerade(rule, element)
  masquerade = element.at_css('/masquerade')
  return unless masquerade
  rule[:masquerade] = true
end

def self.doc_to_attributes_get_rule_forward_port(rule, element)
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

def self.doc_to_attributes_get_rule_log(rule, element)
  log = element.at_css('/log')
  return unless log
  rule[:log] = {}
  rule[:log][:prefix] = log['prefix'] if log['prefix']
  rule[:log][:level] = log['level'] if log['level']
  log_limit = log.at_css('/limit')
  return unless log_limit
  rule[:log][:limit] = log_limit['value']
end

def self.doc_to_attributes_get_rule_audit(rule, element)
  audit = element.at_css('/audit')
  return unless audit
  rule[:audit] = {}
  audit_limit = audit.at_css('/limit')
  return unless audit_limit
  rule[:audit][:limit] = audit_limit['value']
end

def self.doc_to_attributes_get_rule_action(rule, element)
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

def self.doc_to_attributes_get_rule_destination(rule, element)
  destination = element.at_css('/destination')
  return unless destination
  rule[:destination] = destination[:address]
  return unless destination[:invert] && destination[:invert] =~ /^(true|yes)$/i
  rule[:destination_invert] = true
end

def self.doc_to_attributes_get_services(attributes, doc)
  doc.css('/zone/service').each do |service|
    attributes[:services].push(service['name'])
  end
end

def self.doc_to_attributes_get_sources(attributes, doc)
  doc.css('/zone/source').each do |source|
    attributes[:sources].push(source['address'])
  end
end

def self.standardize_attributes(attributes)
  [:interfaces, :ports, :rules, :services, :sources].each do |k|
    attributes[k].sort! { |a, b| a.to_s <=> b.to_s }.uniq!
  end
  attributes
end

def load_current_resource
  @current_resource = Chef::Resource::FirewalldconfigZone.new(
    @new_resource.name
  )
  @current_resource.name(@new_resource.name)
  conf = self.class.read_configuration(@current_resource.name)
  if conf
    conf.each do |a, v|
      @current_resource.method(a).call(v)
    end
  else
    @current_resource.short(@new_resource.name)
    @current_resource.description("#{@new_resource.name} firewalld zone.")
    @current_resource.target('default')
    [:interfaces, :ports, :rules, :services, :sources].each do |attr|
      @current_resource.method(attr).call([])
    end
  end
end

def merge_current_into_new(array_merge)
  # Single attribute values.
  [:description, :short, :target].each do |attr|
    new_val = @new_resource.method(attr).call
    current_val = @current_resource.method(attr).call
    @new_resource.method(attr).call(current_val) if new_val.nil?
  end

  # Array attribute values.
  [:interfaces, :ports, :rules, :services, :sources].each do |attr|
    new_val = @new_resource.method(attr).call
    current_val = @current_resource.method(attr).call

    if new_val.nil?
      @new_resource.method(attr).call(current_val)
      next
    end

    @new_resource.method(attr).call(
      array_merge.call(current_val, new_val)
        .uniq.sort { |a, b| a.to_s <=> b.to_s }
    )
  end
end

def merge_and_converge(array_merge)
  # Fill out any missing values in @new_resource from @current_resource
  # and apply array_merge function on arrays attributes.
  merge_current_into_new array_merge

  if @new_resource == @current_resource
    Chef::Log.debug "#{action} #{ new_resource.name } already as specified."
    return false
  end

  converge_by(
    "#{action} firewalld zone #{new_resource.name} at #{new_resource.file_path}"
  ) do
    write_zone_xml
    new_resource.updated_by_last_action(true)
  end
  true
end

def write_zone_xml
  doc = zone_doc_init
  zone_doc_set_target(doc)
  zone_doc_add_interfaces(doc)
  zone_doc_add_ports(doc)
  zone_doc_add_rules(doc)
  zone_doc_add_services(doc)
  zone_doc_add_sources(doc)
  write_zone_doc(doc)
end

def write_zone_doc(doc)
  fh = ::File.new(new_resource.file_path, 'w')
  doc.write_xml_to fh, encoding: 'UTF-8', indent: 2
  fh.close
end

def zone_doc_init
  doc = Nokogiri::XML(<<EOF) { |x| x.noblanks }
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short></short>
  <description></description>
</zone>
EOF
  doc.at_css('/zone/short').content = @new_resource.short
  doc.at_css('/zone/description').content = @new_resource.description
  doc
end

def zone_doc_set_target(doc)
  case @new_resource.target
  when 'accept'
    doc.root[:target] = 'ACCEPT'
  when 'drop'
    doc.root[:target] = 'DROP'
  when 'reject'
    doc.root[:target] = '%%REJECT%%'
  end
end

def zone_doc_add_interfaces(doc)
  @new_resource.interfaces.each do |name|
    e = doc.create_element(
      'interface',
      name: name
    )
    doc.root.add_child e
  end
end

def zone_doc_add_ports(doc)
  @new_resource.ports.each do |port|
    (port, proto) = port.split('/')
    e = doc.create_element(
      'port',
      protocol: proto,
      port: port
    )
    doc.root.add_child e
  end
end

def zone_doc_add_rules(doc)
  @new_resource.rules.each do |rule|
    e = doc.create_element 'rule'
    zone_doc_rule_set(rule, e)
    doc.root.add_child e
  end
end

def zone_doc_rule_set(rule, element)
  zone_doc_rule_set_family(rule, element)
  zone_doc_rule_set_source(rule, element)
  zone_doc_rule_set_destination(rule, element)
  zone_doc_rule_set_service(rule, element)
  zone_doc_rule_set_port(rule, element)
  zone_doc_rule_set_protocol(rule, element)
  zone_doc_rule_set_icmp_block(rule, element)
  zone_doc_rule_set_masquerade(rule, element)
  zone_doc_rule_set_forward_port(rule, element)
  zone_doc_rule_set_log(rule, element)
  zone_doc_rule_set_audit(rule, element)
  zone_doc_rule_set_action(rule, element)
end

def zone_doc_rule_set_family(rule, element)
  return unless rule.key? :family
  element[:family] = rule[:family] if rule.key? :family
end

def zone_doc_rule_set_source(rule, element)
  return unless rule.key? :source
  e = element.document.create_element(
    'source',
    address: rule[:source]
  )
  e[:invert] = 'True' if rule[:source_invert]
  element.add_child e
end

def zone_doc_rule_set_destination(rule, element)
  return unless rule.key? :destination
  e = element.document.create_element(
    'destination',
    address: rule[:destination]
  )
  e[:invert] = 'True' if rule[:destination_invert]
  element.add_child e
end

def zone_doc_rule_set_service(rule, element)
  return unless rule.key? :service
  e = element.document.create_element(
    'service',
    name: rule[:service]
  )
  element.add_child e
end

def zone_doc_rule_set_port(rule, element)
  return unless rule.key? :port
  (port, proto) = rule[:port].split('/')
  e = element.document.create_element(
    'port',
    protocol: proto,
    port: port
  )
  element.add_child e
end

def zone_doc_rule_set_protocol(rule, element)
  return unless rule.key? :protocol
  e = element.document.create_element(
    'protocol',
    value: rule[:protocol]
  )
  element.add_child e
end

def zone_doc_rule_set_icmp_block(rule, element)
  return unless rule.key? :icmp_block
  e = element.document.create_element(
    'icmp-block',
    name: rule[:icmp_block]
  )
  element.add_child e
end

def zone_doc_rule_set_masquerade(rule, element)
  return unless rule.key? :masquerade
  return unless rule[:masquerade]
  e = element.document.create_element 'masquerade'
  element.add_child e
end

def zone_doc_rule_set_forward_port(rule, element)
  return unless rule.key? :forward_port
  e = element.document.create_element(
    'forward-port',
    port: rule[:forward_port][:port],
    protocol: rule[:forward_port][:protocol]
  )
  e['to-port'] = rule[:forward_port][:to_port] \
    if rule[:forward_port].key? :to_port
  e['to-addr'] = rule[:forward_port][:to_addr] \
    if rule[:forward_port].key? :to_addr
  element.add_child e
end

def zone_doc_rule_set_log(rule, element)
  return unless rule.key? :log
  e = element.document.create_element 'log'
  element.add_child e
  return unless rule[:log].is_a? Hash
  e[:prefix] = rule[:log][:prefix] if rule[:log].key? :prefix
  e[:level] = rule[:log][:level] if rule[:log].key? :level
  return unless rule[:log].key? :limit
  e.add_child e.document.create_element(
    'limit',
    value: rule[:log][:limit]
  )
end

def zone_doc_rule_set_audit(rule, element)
  return unless rule.key? :audit
  e = element.document.create_element 'audit'
  element.add_child e
  return unless rule[:audit].is_a? Hash
  return unless rule[:audit].key? :limit
  e.add_child e.document.create_element(
    'limit',
    value: rule[:audit][:limit]
  )
end

def zone_doc_rule_set_action(rule, element)
  return unless rule.key? :action
  e = element.document.create_element rule[:action]
  if rule[:action] == 'reject' && rule.key?(:reject_with)
    e[:type] = rule[:reject_with]
  end
  if rule.key? :limit
    e.add_child e.document.create_element(
      'limit',
      value: rule[:limit]
    )
  end
  element.add_child e
end

def zone_doc_add_services(doc)
  @new_resource.services.each do |name|
    e = doc.create_element(
      'service',
      name: name
    )
    doc.root.add_child e
  end
end

def zone_doc_add_sources(doc)
  @new_resource.sources.each do |addr|
    e = doc.create_element(
      'source',
      address: addr
    )
    doc.root.add_child e
  end
end
