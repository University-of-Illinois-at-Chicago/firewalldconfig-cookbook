#
# Cookbook Name:: firewalldconfig
# Spec:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'firewalldconfig::default' do
  before do
    allow_any_instance_of(Chef::Recipe)
      .to receive(:include_recipe)
      .with('xml::ruby')
      .and_return(false)
  end

  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new
    runner.converge(described_recipe)
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
end
