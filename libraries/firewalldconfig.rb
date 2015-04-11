def firewalldconfig_readconf(path='/etc/firewalld/firewalld.conf')
  settings = {}
  ::File.open(path).each do |line|
    if /^(?<key>[a-zA-Z0-9]+)=(?<value>.*)/ =~ line
      case key
      when "DefaultZone"
        settings[:default_zone] = value
      when "MinimalMark"
        settings[:minimal_mark] = value.to_i
      when "CleanupOnExit"
        settings[:cleanup_on_exit] = /^(yes|true)/i.match(value) ? true : false
      when "Lockdown"
        settings[:lockdown] = /^(yes|true)/i.match(value) ? true : false
      end
    end
  end
  return settings
end

def firewalldconfig_builtin_services
  ::Dir.entries('/usr/lib/firewalld/services/').grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def firewalldconfig_configured_services
  ::Dir.entries('/etc/firewalld/services/').grep(/^[a-zA-Z].*\.xml$/).collect { |s| s[0..-5] }
end

def firewalldconfig_all_services
  ( firewalld_bulitin_services + firewalldconfig_configured_services ).uniq
end

def firewalldconfig_readservice(name)
  require 'nokogiri'

  if ::File.exists? "/etc/firewalld/services/#{name}.xml"
    service_xml = "/etc/firewalld/services/#{name}.xml"
  elsif ::File.exists? "/usr/lib/firewalld/services/#{name}.xml"
    service_xml = "/usr/lib/firewalld/services/#{name}.xml"
  else
    return nil
  end

  doc = Nokogiri::XML( File.open(service_xml) )

  service = {
    :description => doc.at_xpath('/service/description').content,
    :short => doc.at_xpath('/service/short').content,
    :ports => [],
  }

  doc.xpath('/service/port').each do |port|
    service[:ports].push( port["port"]+'/'+port["protocol"] )
  end

  return service
end

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

  doc = Nokogiri::XML( File.open(zone_xml) )
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

    if rule.has_key? "family"
      r[:family] = rule["family"].to_sym
    end

    source = rule.at_xpath('/source')
    if source
      r[:source] = source["address"]
      if source["invert"] and source["invert"] =~ /^(True|yes)$/i
        r[:source_invert] = true
      end
    end

    destination = rule.at_xpath('/destination')
    if destination
      r[:destination] = destination["address"]
      if destination["invert"] and destination["invert"] =~ /^(True|yes)$/i
        r[:destination_invert] = true
      end
    end

    service = rule.at_xpath('/service')
    if service
      r[:service] = service["name"]
    end

    port = rule.at_xpath('/port')
    if port
      r[:port] = port["port"]+'/'+port["protocol"]
    end

    # FIXME protocol icmp_block masquerade forward-port log audit

    if rule.at_xpath('/accept')
      r[:action] = :accept
    elsif rule.at_xpath('/drop')
      r[:action] = :drop
    elsif rule.at_xpath('/reject')
      r[:action] = :reject
      if rule.at_xpath('/reject')["type"]
        r[:reject_with] = rule.at_xpath('/reject')["type"].to_sym
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
  zone[:rules].sort!.uniq!
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
    node = doc.create_element "rule"
    node[:family] = rule[:family] if rule[:family]
    if rule[:source]
      source = doc.create_element "source", :address => rule[:source]
      source[:invert] = "True" if rule[:source_invert]
      node.add_child source
    end
    if rule[:destination]
      destination = doce.create_element "destination", :address => rule[:destination]
      destination[:invert] = "True" if rule[:destination_invert]
      node.add_child destination
    end
    
    if rule[:service]
      node.add_child doc.create_element "service", :name => rule[:service]
    end

    if rule[:port]
      (port,proto) = rule[:port].split('/')
      node.add_child doc.create_element "port", :protocol => proto, :port => port
    end

    if rule[:action]
      node.add_child doc.create_element rule[:action]
    end

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
