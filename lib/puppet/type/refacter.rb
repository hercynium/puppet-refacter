Puppet::Type.newtype(:refacter) do
  desc <<-EOT
    Forces puppet to rerun facter to reload and refresh all facts, if any of
    the facts matching the given pattern changed.

    "Before" Example:

        # this resource sets up a new loopback disk device with
        # the specified file
        loopback_dev { "loopback-dev-test-1":
          path => "/path/to/loopback/dev/files/test-1.bin",
          size => "10M"
        }
        # This class uses facter facts to automatically mount all known
        # loopback disk devices. However, facter ran *before* the loopback
        # dev above was created, so it will take an *additional* run of
        # puppet apply to pick up the change to the system and get that
        # new device mounted.
        -> class { "automount::loopbackdisks": pattern => "blkid_dev" }

    "After" Example:

        loopback_dev { "loopback-dev-test-1":
          path => "/path/to/loopback/dev/files/test-1.bin",
          size => "10M"
        }
        # after creating the new dev, re-run facter to pick up info about
        # it so it will be mounted by the below class *during this run.*
        ~> refacter { "loopback-dev-test-1": }
        -> class { "automount::loopbackdisks": }
EOT

  require 'pp'

  ### TODO: make the refreshonly mechanism some sort of mixin?

  ### Code below copied from the exec type to support the "refreshonly" mechanism
  def self.newcheck(name, options = {}, &block)
    @checks ||= {}
    check = newparam(name, options, &block)
    @checks[name] = check
  end

  def self.checks
    @checks ||= {}
    @checks.keys
  end

  def refresh
    provider.run if check_all_attributes(true)
  end

  # Verify that we pass all of the checks.  The argument determines whether
  # we skip the :refreshonly check, which is necessary because we now check
  # within refresh
  def check_all_attributes(refreshing = false)
    self.class.checks.each do |check|
      next if refreshing && check == :refreshonly
      next unless @parameters.include?(check)
      val = @parameters[check].value
      val = [val] unless val.is_a? Array
      # return false if any check returns false
      val.each do |value|
        return false unless @parameters[check].check(value)
      end
    end
    # return true if everything was true
    true
  end
  ### Code above copied from the exec type to support the "refreshonly" mechanism

  newparam(:name, :namevar => true) do
    desc 'An arbitrary name used as the identity of the resource.'
  end

  newparam(:patterns) do
    desc 'only reload if facts whose names match these patterns changed'
    munge { |val| resource[:pattern] = val; nil }
    validate do |_val|
      raise ArgumentError,
            "Can not use both the 'pattern' and 'patterns' attributes " \
            'at the same time.' unless resource[:pattern].nil?
    end
  end

  newparam(:pattern) do
    desc 'only reload if facts whose names match this pattern changed'
    defaultto :undef
    validate do |val|
      if resource[:patterns].nil? && val == :undef
        raise ArgumentError, "Either 'pattern' or 'patterns' must be set."
      end
    end
    munge do |val|
      raise ArgumentError,
            "Can not use both the 'pattern' and 'patterns' attributes " \
            'at the same time.' unless resource[:patterns].nil?
      pats = val.is_a?(Array) ? val : [val]
      re = nil
      begin
        re = Regexp.new(pats.shift, Regexp::EXTENDED)
        re = re.union(pats) unless pats.empty?
      rescue => _details
        re = nil # make sure its nil
      end
      raise ArgumentError,
            'Could not compile one of the followine regexps: ' +
            pats.pretty_inspect if re.nil?
      return re
    end
  end

  newparam(:refreshonly) do
    desc 'only reload if this resource recieves a notification'
    newvalues :true, :false
    defaultto :true
    def check(value)
      # check should always fail if this param is true.
      # (this is what makes refreshonly work)
      value == :true ? false : true
    end
  end
end
