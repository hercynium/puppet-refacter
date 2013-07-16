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

Just configure whatever resource makes the "offending" system changes notify this
resource, and if the facts this resource is configured to check have changed,
it will cause your puppet run to restart, reloading all facts, recompiling your
manifests with the new facts, and restarting the application of the catalog.


Please note: *this has only been tested in local mode*. If it doesn't work in
client-server mode, *patches welcome*.

--
Stephen R. Scaffidi | stephen@scaffidi.net
Just Another (Perl|Python|Puppet) Hacker
