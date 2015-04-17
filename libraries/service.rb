def firewalldconfig_builtin_services
  ::Dir.entries('/usr/lib/firewalld/services/')
    .grep(/^[a-zA-Z].*\.xml$/)
    .collect { |s| s[0..-5] }
end

def firewalldconfig_configured_services
  ::Dir.entries('/etc/firewalld/services/')
    .grep(/^[a-zA-Z].*\.xml$/)
    .collect { |s| s[0..-5] }
end

def firewalldconfig_all_services
  (firewalld_bulitin_services + firewalldconfig_configured_services).uniq
end

def firewalldconfig_read_service_xml(name)
  doc = firewalldconfig_service_xml_doc name
  return nil if doc.nil?
  service = firewalldconfig_read_service_doc_init(doc)
  firewalldconfig_read_service_doc_ports(service, doc)
  service
end

def firewalldconfig_service_xml_doc(name)
  require 'nokogiri'

  ['/etc/firewalld', '/usr/lib/firewalld'].each do |dir|
    xml_path = "#{dir}/services/#{name}.xml"
    next unless ::File.file? xml_path
    return Nokogiri::XML(::File.open(xml_path))
  end

  nil
end

def firewalldconfig_read_service_doc_init(doc)
  {
    description: doc.at_xpath('/service/description').content,
    short: doc.at_xpath('/service/short').content,
    ports: []
  }
end

def firewalldconfig_read_service_doc_ports(service, doc)
  doc.xpath('/service/port').each do |port|
    service[:ports].push(port['port'] + '/' + port['protocol'])
  end
  service[:ports].sort!.uniq!
end
