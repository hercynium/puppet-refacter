require 'spec_helper'

describe Puppet::Type.type(:refacter) do
  TEMPDIR = '/tmp/refacter_run'.freeze
  TESTDIR = '/tmp/refacter_test'.freeze

  before do
    allow(Puppet::Util::Storage).to receive(:store)
    # Uncomment next two lines if you want to see the puppet debug
    # Puppet::Util::Log.level = :debug
    # Puppet::Util::Log.newdestination(:console)
    allow(Puppet.settings).to receive(:[]).and_wrap_original do |m, *args|
      item = args.first
      case item
      when /.*dir/
        `pwd`
      when :classfile
        './.tmp/classes.txt'
      when :resourcefile
        './.tmp/resources.txt'
      when :transactionstorefile
        './.tmp/transactionstore.yaml'
      when :lastrunfile
        './.tmp/last_run_summary.yaml'
      else
        m.call(*args)
      end
    end
  end

  context 'changing facter value for uptime_seconds' do
    before do
      Dir.mkdir(TEMPDIR)
      Dir.rmdir(TESTDIR) if File.exist?(TESTDIR)
    end

    after do
      Facter.clear
      Facter.clear_messages
      Dir.rmdir(TEMPDIR) if File.exist?(TEMPDIR)
      Dir.rmdir(TESTDIR) if File.exist?(TESTDIR)
    end

    context 'no refacter type loaded' do
      it 'must return same fact value before and after puppet run' do
        current_update = Facter.value('uptime_seconds')
        sleep(1) # Make sure we have at least one second difference
        catalog = Puppet::Resource::Catalog.new
        catalog.add_resource(Puppet::Type.type(:file).new(:name => TEMPDIR, :ensure => 'absent', :force => true))
        catalog.add_resource(Puppet::Type.type(:refacter).new(:name => 'foo', :pattern => 'timezone', :require => "File[#{TEMPDIR}]"))
        catalog.apply
        expect(Facter.value('uptime_seconds')).to eq(current_update)
      end
    end

    context 'refacter class refeshed' do
      it 'must return different fact value before and after puppet run' do
        current_update = Facter.value('uptime_seconds')
        sleep(1) # Make sure we have at least one second difference
        catalog = Puppet::Resource::Catalog.new
        catalog.add_resource(Puppet::Type.type(:file).new(:name => TEMPDIR, :ensure => 'absent', :force => true))
        catalog.add_resource(Puppet::Type.type(:refacter).new(:name => 'foo', :pattern => 'uptime_seconds', :subscribe => "File[#{TEMPDIR}]"))
        catalog.apply
        expect(Facter.value('uptime_seconds')).not_to eq(current_update)
      end

      it 'must run the next resource in the catalog after refacter' do
        catalog = Puppet::Resource::Catalog.new
        catalog.add_resource(Puppet::Type.type(:file).new(:name => TEMPDIR, :ensure => 'absent', :force => true))
        catalog.add_resource(Puppet::Type.type(:refacter).new(:name => 'foo', :pattern => 'uptime_seconds', :subscribe => "File[#{TEMPDIR}]"))
        catalog.add_resource(Puppet::Type.type(:file).new(:name => TESTDIR, :ensure => 'directory', :require => 'Refacter[foo]'))
        catalog.apply
        expect(File.exist?(TESTDIR)).to eq(true)
      end
    end
  end
end
