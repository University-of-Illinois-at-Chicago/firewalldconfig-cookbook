#
# Cookbook Name:: firewalldconfig
# Spec:: record
#
# Copyright (c) 2015 The University of Illinois at Chicago

require 'spec_helper'

describe 'firewalldconfig::record' do
  before do
    allow_any_instance_of(Chef::Recipe)
      .to receive(:include_recipe)
      .with('xml::ruby')
      .and_return(false)
    allow_any_instance_of(Chef::Node)
      .to receive(:save)
      .and_return(true)
    Chef::Provider::Firewalldconfig.etc_dir = "#{File.dirname(__FILE__)}/etc"
    Chef::Provider::Firewalldconfig.lib_dir = "#{File.dirname(__FILE__)}/lib"
  end

  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new
    runner.converge(described_recipe)
  end

  it 'converges successfully' do
    chef_run # This should not raise an error
  end

  it 'should set correct node attributes' do
    # Have to force the ruby_block to run:
    # https://coderwall.com/p/afdnyw/testing-code-inside-ruby_block-with-chefspec
    chef_run.find_resources(:ruby_block).find do |r|
      r.name == 'firewalldconfig-record'
    end.old_run_action(:run)

    expect(chef_run.node['firewalld']['default_zone']).to eq 'public'

    expect(chef_run.node['firewalld']['services']['nrpe']).to eq(
      'short' => 'NRPE',
      'description' => 'Nagios Remote Plugin Executor',
      'ports' => %w(5666/tcp)
    )

    expect(chef_run.node['firewalld']['zones']['campus']).to eq(
      'short' => 'Campus',
      'description' => 'University campus networks.',
      'interfaces' => [],
      'sources' => %w(128.248.0.0/16 131.193.0.0/16),
      'services' => %w(http https ssh),
      'ports' => %w(10443/tcp),
      'rules' => [
        {
          'family' => 'ipv4',
          'source' => '128.248.0.0/16',
          'source_invert' => true,
          'service' => 'mysql',
          'action' => 'reject',
          'reject_with' => 'icmp-port-unreachable'
        },
        {
          'family' => 'ipv4',
          'source' => '128.248.155.0/24',
          'service' => 'mysql',
          'action' => 'accept'
        },
        {
          'family' => 'ipv4',
          'source' => '131.193.99.88',
          'port' => '8443/tcp',
          'action' => 'accept'
        }
      ]
    )
  end

  # it 'starts firewalld' do
  #   expect(chef_run).to start_service('firewalld')
  # end
end
