if defined?(ChefSpec)
  def create_firewalldconfig(path)
    ChefSpec::Matchers::ResourceMatcher.new(:firewalldconfig, :create, path)
  end

  def merge_firewalldconfig(path)
    ChefSpec::Matchers::ResourceMatcher.new(:firewalldconfig, :merge, path)
  end

  def create_firewalldconfig_service(name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :firewalldconfig_service, :create, name
    )
  end

  def create_firewalldconfig_zone(name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :firewalldconfig_zone, :create, name
    )
  end
end
