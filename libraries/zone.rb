def firewalldconfig_builtin_zones
  ::Dir.entries('/usr/lib/firewalld/zones/').grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def firewalldconfig_configured_zones
  ::Dir.entries('/etc/firewalld/zones/').grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def firewalldconfig_all_zones
  ( firewalld_bulitin_zones + firewalldconfig_configured_zones ).uniq
end

def firewalldconfig_readzone(name)
  require 'nokogiri'

  if ::File.exists? "/etc/firewalld/zones/#{name}.xml"
    zone_xml = "/etc/firewalld/zones/#{name}.xml"
  elsif ::File.exists? "/usr/lib/firewalld/zones/#{name}.xml"
    zone_xml = "/usr/lib/firewalld/zones/#{name}.xml"
  else
    return nil
  end

  doc = Nokogiri::XML( ::File.open(zone_xml) )
  zone = {
    :description => doc.at_xpath('/zone/description').content,
    :short => doc.at_xpath('/zone/short').content,
    :interfaces => [],
    :ports => [],
    :rules => [],
    :services => [],
    :sources => [],
  }

  case doc.root[:target]
  when 'ACCEPT'
    zone[:target] = :accept
  when 'DROP'
    zone[:target] = :drop
  when '%%REJECT%%'
    zone[:target] = :reject
  end

  doc.xpath('/zone/interface').each do |interface|
    zone[:interfaces].push( interface["name"] )
  end

  doc.xpath('/zone/port').each do |port|
    zone[:ports].push( port["port"]+'/'+port["protocol"] )
  end

  doc.xpath('/zone/rule').each do |rule|
    r = {}

    unless rule[:family].nil?
      r[:family] = rule[:family].to_sym
    end

    source = rule.at_xpath('./source')
    if source
      r[:source] = source[:address]
      if source[:invert] and source[:invert] =~ /^(true|yes)$/i
        r[:source_invert] = true
      end
    end

    destination = rule.at_xpath('./destination')
    if destination
      r[:destination] = destination["address"]
      if destination["invert"] and destination["invert"] =~ /^(True|yes)$/i
        r[:destination_invert] = true
      end
    end

    service = rule.at_xpath('./service')
    if service
      r[:service] = service["name"]
    end

    port = rule.at_xpath('./port')
    if port
      r[:port] = port["port"]+'/'+port["protocol"]
    end

    # FIXME protocol icmp_block masquerade forward-port log audit

    if rule.at_xpath('./accept')
      r[:action] = :accept
    elsif rule.at_xpath('./drop')
      r[:action] = :drop
    elsif rule.at_xpath('./reject')
      r[:action] = :reject
      if rule.at_xpath('./reject')["type"]
        r[:reject_with] = rule.at_xpath('./reject')["type"].to_sym
      end
    end

    zone[:rules].push( r )
  end

  doc.xpath('/zone/service').each do |service|
    zone[:services].push( service["name"] )
  end

  doc.xpath('/zone/source').each do |source|
    zone[:sources].push( source["address"] )
  end

  zone[:interfaces].sort!.uniq!
  zone[:ports].sort!.uniq!
  zone[:rules].sort!{|a,b| a.to_s <=> b.to_s}.uniq!
  zone[:services].sort!.uniq!
  zone[:sources].sort!.uniq!

  return zone
end

def firewalldconfig_writezone(name,zone)
  doc = Nokogiri::XML::Document.parse(<<EOF)
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short></short>
  <description></description>
</zone>
EOF
  root = doc.at_xpath("/zone");

  case zone[:target]
  when :accept
    root[:target] = 'ACCEPT'
  when :drop
    root[:target] = 'DROP'
  when :reject
    root[:target] = '%%REJECT%%'
  end

  doc.at_xpath("/zone/short").content = zone[:short]
  doc.at_xpath("/zone/description").content = zone[:description]

  zone[:interfaces].each do |name|
    node = doc.create_element "interface", :name => name
    root.add_child node
  end

  zone[:ports].each do |port|
    (port,proto) = port.split('/')
    root.add_child doc.create_element "port", :protocol => proto, :port => port
  end

  zone[:rules].each do |rule|
    rule_node = doc.create_element "rule"
    rule_node[:family] = rule[:family] if rule.has_key? :family
    if rule[:source]
      source = doc.create_element "source", :address => rule[:source]
      source[:invert] = "True" if rule[:source_invert]
      rule_node.add_child source
    end
    if rule[:destination]
      destination = doce.create_element "destination", :address => rule[:destination]
      destination[:invert] = "True" if rule[:destination_invert]
      rule_node.add_child destination
    end

    if rule[:service]
      rule_node.add_child doc.create_element "service", :name => rule[:service]
    end

    if rule[:port]
      (port,proto) = rule[:port].split('/')
      rule_node.add_child doc.create_element "port", :protocol => proto, :port => port
    end

    if rule[:action]
      action_node = doc.create_element rule[:action].to_s
      if rule[:action] == :reject and rule.has_key? :reject_with
        action_node[:type] = rule[:reject_with]
      end
      rule_node.add_child action_node
    end

    root.add_child rule_node
  end

  zone[:services].each do |name|
    root.add_child doc.create_element "service", :name => name
  end

  zone[:sources].each do |addr|
    root.add_child doc.create_element "source", :address => addr
  end

  fh = ::File.new("/etc/firewalld/zones/#{name}.xml","w")
  doc.write_xml_to fh, :encoding => 'UTF-8'
  fh.close
end

# Function to validate protocol names in rich rules. The protocol should
# be defined in /etc/protocols
def firewalldconfig_protocol_exists? (name)
  fh = ::File.open '/etc/protocols'
  found = false
  fh.each do |line|
    match = line.match(/^(\S+)/)
    if not match.nil? and name == match[1]
      found = true
      break
    end
  end
  return found
end

# Function to validate icmptype names for rich rules.
def firewalldconfig_icmptype_exists? (name)
  return `firewall-cmd --get-icmptypes`.split(' ').include? name
end
