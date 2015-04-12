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

def firewalldconfig_writeservice(name,service)
  doc = Nokogiri::XML::Document.parse(<<EOF)
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short></short>
  <description></description>
</service>
EOF
  root = doc.at_xpath("/service");

  doc.at_xpath("/service/short").content = service[:short]
  doc.at_xpath("/service/description").content = service[:description]

  service[:ports].each do |port|
    (port,proto) = port.split('/')
    root.add_child doc.create_element "port", :protocol => proto, :port => port
  end

  fh = ::File.new("/etc/firewalld/services/#{name}.xml","w")
  doc.write_xml_to fh, :encoding => 'UTF-8'
  fh.close
end
