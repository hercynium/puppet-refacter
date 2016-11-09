require 'puppet/configurer'
require 'set'
require 'pp'

Puppet::Type.type(:refacter).provide(:ruby) do
  desc <<-END

  This provider handles rerunning facter to reload all the known facts
  for the refacter type.

  END

  def initialize(hash)
    debug 'init refacter, save Facter values'
    @facts = Facter.to_hash
    super
  end

  # actually perform the check and (optional) reload
  def run
    Puppet.debug('reloading facter to see if facts changed')
    pattern = resource[:pattern]
    pnode = Puppet[:node_name_value]
    pconf = Puppet::Configurer.new

    fact_diff_hash = reload_facts(pattern, pconf, pnode)
    if fact_diff_hash.empty?
      Puppet.debug('facts stayed the same after reloading facter')
      return
    else
      Puppet.notice('facts changed after reloading facter')
    end
    @refreshed = true
    Puppet.alert('reloading puppet to pick up new facts')
    Puppet::Application.restart!
    pconf.run
    # Puppet::Application.stop!
    Puppet.alert('finished reloading puppet to pick up new facts')
    true
  end

  def reload_facts(pattern, _pconf, pnode)
    old = get_matching_facts(@facts, pattern, pnode)
    new = get_matching_facts(refreshed_facts, pattern, pnode)
    diff = diff_hashes(old, new)
    diff
  end

  def get_matching_facts(fact_hash, pattern, _pnode)
    clean_facts = fact_hash.reject { |k, _v| !k.is_a?(String) || k[0..0] == '_' }
    matched_facts = pattern ? clean_facts.reject { |k, _v| !pattern.match(k) } : clean_facts
    matched_facts
  end

  # given two hashes, this returns a "diff hash" where only the keys and
  # values that differ between the given hashes are listed. All values
  # become two-element arrays where the first element is the value from
  # the first hash and the second is the value from the second hash. If
  # a key was missing from either hash its corresponding value will be
  # nil. This isn't perfect, but will do for now. Speed wins.
  def diff_hashes(h1, h2)
    both_keys = Set[h1.keys] | h2.keys
    diff_hash = both_keys.each_with_object({}) do |k, h|
      h[k] = [h1[k], h2[k]] if h1[k] != h2[k]; h
    end
    # pp h1, h2, diff_hash
    diff_hash
  end

  def loaded_facts(pnode)
    Puppet::Node::Facts.indirection.find(pnode).values
  end

  def refreshed_facts
    Facter.clear
    Facter.to_hash
  end
end
