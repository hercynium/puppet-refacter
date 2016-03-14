require 'spec_helper'
require 'tmpdir'

describe Puppet::Type.type(:refacter) do

  before do
    Puppet::Util::Storage.stubs(:store)
  end

  context "change facter value for foo" do
    before :each do
      @tmpdir = Dir.mktmpdir("refacter_run")
      Facter.add(:foo) {
        if File.exists?(@tmpdir)
          setcode  'bar'
        else
          setcode  'bleh'
        end
      }
    end

    after :each do
      Facter.clear
      Facter.clear_messages
      begin
        Dir.rmdir(@tmpdir)
      rescue
      end
    end

    it 'should return bar when change facter foo' do
      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource(Puppet::Type.type(:file).new(:name => @tmpdir, :ensure => 'absent'))
      catalog.apply
      expect(Facter.value(:foo)).to eq('bar')
    end

    it 'should return bleh when change facter foo using refacter' do
      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource(Puppet::Type.type(:file).new(:name => @tmpdir, :ensure => 'absent'))
      catalog.add_resource(Puppet::Type.type(:refacter).new(:name => "foo", :pattern => "foo",:require => "File[#{@tmpdir}]"))
      catalog.apply
      expect(Facter.value(:foo)).to eq('bleh')
    end
  end
end
