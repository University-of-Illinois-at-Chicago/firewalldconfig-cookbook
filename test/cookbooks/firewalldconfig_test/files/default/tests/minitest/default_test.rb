require 'minitest/spec'

describe_recipe 'firewalldconfig::default' do
  it 'configures /etc/firewalld/firewalld.conf' do
    file('/etc/firewalld/firewalld.conf').must_exist
  end
end
