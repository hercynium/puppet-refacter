puppet-refacter
===============

Puppet provider to refresh facter and automatically reload if specified facts changed

Sometimes applying resources while running puppet changes the system in such
a way that you need to *re-run puppet* to pick up new facts and finish making
changes.

That sucks.

Sure, the "correct" answer is probably to use an ENC or Hiera or Magic Unicorn Dust
or some other thing like that, but this puppet module solved the problem well enough
for me.

Just configure whatever resource makes the "offending" system changes to notify this
resource, and if the facts this resource is configured to check have changed,
it will cause your puppet run to restart, reloading all facts, recompiling your
manifests with the new facts, and restarting the application of the catalog.

For example:

    # make sure various nfs disks are mounted - does this
    # dynamically based on some sort of voodoo
    class { "nfs::mounts": notify => Refacter["check-mount-points"] }

    # we have a facter plugin that makes facts based on mounted filesystems
    # so if they changed, we would normally have to re-run puppet. *ick*
    # instead, we can use refacter...
    refacter { "check-mount-points": patterns => [ "^mount_point" ] }

    # if facts matching the given patterns changed, puppet will reload
    # automatically. if nothing changed, it will continue as normal.

Please note: ***this has only been tested in local mode***. If it doesn't work in
client-server mode, *patches welcome*.

--
Stephen R. Scaffidi | stephen@scaffidi.net | Just Another (Perl|Python|Puppet) Hacker
