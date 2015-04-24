#
# Cookbook Name:: firewalldconfig
# Spec:: deploy_from_node_attributes
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require 'spec_helper'
require 'tmpdir'
require 'nokogiri'
require 'fileutils'

describe 'firewalldconfig::deploy_from_node_attributes' do
  before(:all) do
    etc_dir = Dir.mktmpdir
    Dir.mkdir "#{etc_dir}/zones"
    Dir.mkdir "#{etc_dir}/services"
    Chef::Provider::Firewalldconfig.etc_dir = "#{etc_dir}"
    Chef::Provider::Firewalldconfig.lib_dir = "#{File.dirname(__FILE__)}/lib"
  end

  after(:all) do
    # FileUtils.rm_r Chef::Provider::Firewalldconfig.etc_dir
  end

  before(:each) do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe)
      .with('xml::ruby').and_return(false)
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe)
      .with('firewalldconfig').and_call_original
  end

  context 'With firewall attributes set.' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(
        platform: 'centos', version: '7.0',
        step_into: %w(
          firewalldconfig firewalldconfig_service firewalldconfig_zone
        )
      ) do |node|
        node.set['firewalld'] = {
          'cleanup_on_exit' => true,
          'default_zone'    => 'public',
          'ipv6_rpfilter'   => true,
          'lockdown'        => false,
          'minimal_mark'    => 100,
          'services' => {
            'nrpe' => {
              'short' => 'NRPE',
              'description' => 'Nagios Remote Plugin Executor',
              'ports' => %w(5666/tcp)
            }
          },
          'zones' => {
            'home' => {
              'services' => %w(ssh mdns samba-client dhcpv6-client)
            },
            'public' => {
              'ports' => %w(8080/tcp 8443/tcp),
              'services' => %w(http https),
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
                  'source' => '128.248.155.93',
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
            }
          }
        }
      end.converge(described_recipe)
    end

    it 'converges successfully' do
      chef_run # This should not raise an error
    end

    it 'installs firewalld' do
      expect(chef_run).to install_package('firewalld')
    end

    it 'enables firewalld' do
      expect(chef_run).to enable_service('firewalld')
    end

    it 'starts firewalld' do
      expect(chef_run).to start_service('firewalld')
    end

    it 'merges firewalld.conf' do
      expect(chef_run).to(
        merge_firewalldconfig('firewalld.conf').with(
          cleanup_on_exit: true,
          default_zone:    'public',
          ipv6_rpfilter:   true,
          lockdown:        false,
          minimal_mark:    100
        )
      )
    end

    it 'writes firewalld.conf' do
      expect(File).to exist(
        "#{Chef::Provider::Firewalldconfig.etc_dir}/firewalld.conf"
      )
    end

    it 'has correct content in firewalld.conf' do
      lines = ::File.open(
        "#{Chef::Provider::Firewalldconfig.etc_dir}/firewalld.conf"
      ).readlines
      expect(lines).to include("CleanupOnExit=true\n")
      expect(lines).to include("DefaultZone=public\n")
      expect(lines).to include("IPv6_rpfilter=true\n")
      expect(lines).to include("Lockdown=false\n")
      expect(lines).to include("MinimalMark=100\n")
    end

    it 'creates nrpe service' do
      expect(chef_run).to create_firewalldconfig_service('nrpe').with(
        short:       'NRPE',
        description: 'Nagios Remote Plugin Executor',
        ports:       %w(5666/tcp)
      )
    end

    it 'writes services/nrpe.xml' do
      expect(File).to exist(
        "#{Chef::Provider::Firewalldconfig.etc_dir}/services/nrpe.xml"
      )
    end

    it 'has correct content for services/nrpe.xml' do
      doc = Nokogiri::XML(::File.open(
        "#{Chef::Provider::Firewalldconfig.etc_dir}/services/nrpe.xml"
      )) { |x| x.noblanks }
      expect(doc.at_css('/service/short').content).to eq('NRPE')
      expect(doc.at_css('/service/description').content).to eq(
        'Nagios Remote Plugin Executor'
      )
      expect(doc.at_css('/service/port[port="5666"][protocol="tcp"]')).to be
    end

    it 'creates public zone' do
      expect(chef_run).to create_firewalldconfig_zone('public').with(
        ports:    %w(8080/tcp 8443/tcp),
        services: %w(http https)
      )
    end

    it 'writes zones/public.xml' do
      expect(File).to exist(
        "#{Chef::Provider::Firewalldconfig.etc_dir}/zones/public.xml"
      )
    end

    it 'has correct content for zones/public.xml' do
      doc = Nokogiri::XML(::File.open(
        "#{Chef::Provider::Firewalldconfig.etc_dir}/zones/public.xml"
      )) { |x| x.noblanks }
      expect(doc.at_css('/zone/short').content).to eq('Public')
      expect(doc.at_css('/zone/description').content).to eq(
        'For use in public areas. You do not trust the other computers on '\
        'networks to not harm your computer. Only selected incoming '\
        'connections are accepted.'
      )
      expect(doc.css('/zone/port').length).to eq 2
      expect(doc.at_css('/zone/port[port="8080"][protocol="tcp"]')).to be
      expect(doc.at_css('/zone/port[port="8443"][protocol="tcp"]')).to be

      expect(doc.css('/zone/service').length).to eq 2
      expect(doc.at_css('/zone/service[name="http"]')).to be
      expect(doc.at_css('/zone/service[name="https"]')).to be

      expect(doc.css('/zone/rule').length).to eq 3

      rule_element = doc.css('/zone/rule')[0]
      expect(rule_element['family']).to eq 'ipv4'
      expect(rule_element.at_css(
        '/source[address="128.248.0.0/16"][invert="True"]'
      )).to be
      expect(rule_element.at_css('/service[name="mysql"]')).to be
      expect(rule_element.at_css('/reject[type="icmp-port-unreachable"]')).to be
      expect(rule_element.children.length).to eq 3

      rule_element = doc.css('/zone/rule')[1]
      expect(rule_element['family']).to eq 'ipv4'
      expect(rule_element.at_css('/source[address="128.248.155.93"]'))
        .to be
      expect(rule_element.at_css('/service[name="mysql"]')).to be
      expect(rule_element.at_css('/accept')).to be
      expect(rule_element.children.length).to eq 3

      rule_element = doc.css('/zone/rule')[2]
      expect(rule_element['family']).to eq 'ipv4'
      expect(rule_element.at_css('/source[address="131.193.99.88"]'))
        .to be
      expect(rule_element.at_css('/port[port="8443"][protocol="tcp"]')).to be
      expect(rule_element.at_css('/accept')).to be
      expect(rule_element.children.length).to eq 3
    end

    it 'does not write zones/home.xml' do
      expect(File).to_not exist(
        "#{Chef::Provider::Firewalldconfig.etc_dir}/zones/home.xml"
      )
    end
  end
end
