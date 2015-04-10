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

  return zone
end
