require 'spec_helper'

describe 'firewalldconfig::default' do
  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html

  let(:chef_run) do
    ChefSpec::ChefRunner.new.converge(described_recipe)
  end

  it 'installs firewalld' do
    expect(chef_run).to install_package('firewalld')
  end

  it 'enables, and starts firewalld service' do
    expect(chef_run).to enable_service('firewalld')
    expect(chef_run).to start_service('firewalld')
  end
end
