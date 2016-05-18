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
    "#{FirewalldconfigUtil.lib_dir}/zones"
  ).grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def self.configured
  ::Dir.entries(
    "#{FirewalldconfigUtil.etc_dir}/zones"
  ).grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def load_current_resource
  @current_resource = Chef::Resource::FirewalldconfigZone.new(
    @new_resource.name
  )
  @current_resource.name(@new_resource.name)
  conf = FirewalldconfigUtil.read_zone_configuration(@current_resource.name)
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
    @new_resource.method(attr).call(current_val) if new_val.nil? and !current_val.nil?
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
