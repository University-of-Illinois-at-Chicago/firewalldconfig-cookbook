#
# Cookbook Name:: firewalldconfig
# Provider:: zone
#
# Copyright:: 2015, The University of Illinois at Chicago

action :create do
  current = firewalldconfig_read_zone_xml(new_resource.name)
  current = {
    short:       new_resource.name,
    description: "#{new_resource.name} firewalld zone.",
    interfaces:  [],
    ports:       [],
    rules:       [],
    services:    [],
    sources:     []
  } if current.nil?
  new_resource.updated_by_last_action(update_zone(current, ->(_o, u) { u }))
end

action :create_if_missing do
  if ::File.file? new_resource.file_path
    Chef::Log.debug "firewalld zone #{new_resource.name} already configured."
    new_resource.updated_by_last_action(false)
    next
  end

  action_create
end

action :delete do
  if ::File.file? new_resource.file_path
    converge_by(
      "remove firewalld zone #{new_resource.name} "\
      "from #{new_resource.file_path}"
    ) do
      ::File.unlink new_resource.file_path
      new_resource.updated_by_last_action(true)
    end
  else
    Chef::Log.debug "firewalld zone, #{new_resource.name} not configured"
    new_resource.updated_by_last_action(false)
  end
end

action :filter do
  current = firewalldconfig_read_zone_xml(new_resource.name)

  if current.nil?
    Chef::Log.debug "filter firewalld zone #{ new_resource.name } not defined"
    new_resource.updated_by_last_action(false)
    next
  end

  new_resource.updated_by_last_action(update_zone(current, ->(o, u) { o & u }))
end

action :merge do
  unless firewalldconfig_configured_zones.include? new_resource.name
    action_create
    next
  end
  current = firewalldconfig_read_zone_xml(new_resource.name)
  new_resource.updated_by_last_action(update_zone(current, ->(o, u) { o + u }))
end

action :prune do
  current = firewalldconfig_read_zone_xml(new_resource.name)

  if current.nil?
    Chef::Log.debug "Firewalld zone #{ new_resource.name } not defined."
    new_resource.updated_by_last_action(false)
    next
  end

  new_resource.updated_by_last_action(update_zone(current, ->(o, u) { o - u }))
end

def apply_single_attrs(zone)
  # Single attribute values.
  [:description, :short, :target].each do |attr|
    val = new_resource.method(attr).call
    next if val.nil?
    zone[attr] = val
  end
end

# # rubocop:disable MethodLength
# def attr_list_combine(zone, attr, val, action)
#   case action
#   when :create
#     zone[attr] = val
#   when :filter
#     zone[attr] &= val
#   when :merge
#     zone[attr] += val
#   when :prune
#     zone[attr] -= val
#   end
#   zone[attr].sort! { |a, b| a.to_s <=> b.to_s }
#   zone[attr].uniq!
# end
# # rubocop:enable MethodLength

def apply_plural_attrs(zone, array_merge)
  # Array attribute values.
  [:interfaces, :ports, :rules, :services, :sources].each do |attr|
    val = new_resource.method(attr).call
    next if val.nil?
    zone[attr] = array_merge.call zone[attr], val
    zone[attr].sort! { |a, b| a.to_s <=> b.to_s }.uniq!
  end
end

def build_zone(current_zone, array_merge)
  zone = current_zone.clone

  apply_single_attrs zone
  apply_plural_attrs zone, array_merge

  # Target :default means remove any special target.
  zone.delete(:target) if zone[:target] == :default

  zone
end

def update_zone(current_zone, array_merge)
  zone = build_zone current_zone, array_merge
  if zone == current_zone
    Chef::Log.debug "#{action} #{ new_resource.name } already as specified."
    return false
  else
    converge_zone(zone, action)
    return true
  end
end

def converge_zone(zone, action)
  converge_by(
    "#{action} firewalld zone #{new_resource.name} at #{new_resource.file_path}"
  ) do
    write_zone_xml zone
    new_resource.updated_by_last_action(true)
  end
end

def write_zone_xml(zone)
  doc = zone_doc_init(zone)
  zone_doc_set_target(zone, doc)
  zone_doc_add_interfaces(zone, doc)
  zone_doc_add_ports(zone, doc)
  zone_doc_add_rules(zone, doc)
  zone_doc_add_services(zone, doc)
  zone_doc_add_sources(zone, doc)
  write_zone_doc(doc)
end

def write_zone_doc(doc)
  fh = ::File.new(new_resource.file_path, 'w')
  doc.write_xml_to fh, encoding: 'UTF-8', indent: 2
  fh.close
end

def zone_doc_init(zone)
  doc = Nokogiri::XML(<<EOF) { |x| x.noblanks }
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short></short>
  <description></description>
</zone>
EOF
  doc.at_xpath('/zone/short').content = zone[:short]
  doc.at_xpath('/zone/description').content = zone[:description]
  doc
end

def zone_doc_set_target(zone, doc)
  case zone[:target]
  when :accept
    doc.root[:target] = 'ACCEPT'
  when :drop
    doc.root[:target] = 'DROP'
  when :reject
    doc.root[:target] = '%%REJECT%%'
  end
end

def zone_doc_add_interfaces(zone, doc)
  zone[:interfaces].each do |name|
    e = doc.create_element(
      'interface',
      name: name
    )
    doc.root.add_child e
  end
end

def zone_doc_add_ports(zone, doc)
  zone[:ports].each do |port|
    (port, proto) = port.split('/')
    e = doc.create_element(
      'port',
      protocol: proto,
      port: port
    )
    doc.root.add_child e
  end
end

def zone_doc_add_rules(zone, doc)
  zone[:rules].each do |rule|
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

def zone_doc_rule_set_action(rule, element)
  return unless rule.key? :action
  e = element.document.create_element rule[:action].to_s
  if rule[:action] == :reject && rule.key?(:reject_with)
    e[:type] = rule[:reject_with]
  end
  element.add_child e
end

def zone_doc_add_services(zone, doc)
  zone[:services].each do |name|
    e = doc.create_element(
      'service',
      name: name
    )
    doc.root.add_child e
  end
end

def zone_doc_add_sources(zone, doc)
  zone[:sources].each do |addr|
    e = doc.create_element(
      'source',
      address: addr
    )
    doc.root.add_child e
  end
end
