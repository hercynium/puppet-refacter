
Puppet::Type.type(:refacter).provide(:ruby) do
  desc <<-END

    This provider handles rerunning facter to reload all the known facts
    for the refacter type.

END
    require 'puppet/configurer'
    require 'set'
    require 'pp'

    # actually perform the check and (optional) reload
    def run
        Puppet.debug("reloading facter to see if facts changed")
        pattern = resource[:pattern]
        pnode = Puppet[:node_name_value]
        pconf = Puppet::Configurer.new()

        fact_diff_hash = reload_facts( pattern, pconf, pnode )
        if fact_diff_hash.empty?
            Puppet.debug("facts stayed the same after reloading facter")
            return
        else
            Puppet.notice("facts changed after reloading facter")
        end
        @refreshed = true
        Puppet.alert("reloading puppet to pick up new facts")
        Puppet::Application.restart!
        pconf.run
        Puppet.alert("finished reloading puppet to pick up new facts")
    end

    def reload_facts( pattern, pconf, pnode )
        old = get_matching_facts( pattern, pnode )
        pconf.facts_for_uploading()
        new = get_matching_facts( pattern, pnode )
        diff = diff_hashes( old, new ) 
        return diff
    end

    def get_matching_facts( pattern, pnode )
        fact_hash = Puppet::Node::Facts.indirection.find( pnode ).values()
        clean_facts = fact_hash.reject { |k,v| ( ! k.is_a?( String ) ) or k[0..0] == "_" }
        matched_facts = pattern ? clean_facts.reject { |k,v| ! pattern.match(k) } : clean_facts
        return matched_facts
    end

    # given two hashes, this returns a "diff hash" where only the keys and
    # values that differ between the given hashes are listed. All values
    # become two-element arrays where the first element is the value from
    # the first hash and the second is the value from the second hash. If
    # a key was missing from either hash its corresponding value will be
    # nil. This isn't perfect, but will do for now. Speed wins.
    def diff_hashes ( h1, h2 )
        both_keys = Set[ h1.keys ] | h2.keys
        diff_hash = both_keys.inject({}) do |h,k|
            h[k] = [ h1[k], h2[k] ] if h1[k] != h2[k]; h
        end
        #pp h1, h2, diff_hash
        return diff_hash
    end
end

# vi: set ts=4 sw=4 et :
