Important
=========

  * These scripts are being ported to a fabfile
  * These scripts are really specific to our environment


TL;DR
=====

Scripts to pereodically build and run a randomly generated network containing
a random set of vulnerabilities for the purposes of practicing your hacking / 
scanning / pivoting skills. The vision is for this to be completely independent
of a puppet/razor environment - We intend to rescue this entire environment from
a set of scripts if need be.

Ghetto Shell Scripts
====================

This repository contains some scripts we use to build our virtualization lab 
automagically.

The idea: Create a pseudo-randomly-generated self-provisioning network,
complete with vlans, routers, as well as a wide range of applications for
the purposes of being attacked by hackers, bots, aliens and even time agents.

The randomly-generated services include anything from glutserFS to Apache 
servers; the goal is to create a large attack surface for hackers/the interested
to test their creativeness against; this attack surface representing 
a real corporate network, and not just a single host/set of hosts that were 
created to be hacked. Part of the process is for the builder to randomly
insert vulnerabilities (configuration-related or otherwise!!) into the
environment, so that even though two iterations may look the same, the attack
surface is drastically different.

This is not a CTF; it's a sandbox. Everything (and we mean everything) is
rebuilt from scratch every 6 hours - automatically and randomly (with some
templating, obviously.

It should be ready sometime in the beginning of next year.

So why is this on github?
=========================

Why not? We don't think this project in its entirety is useful to anyone but us,
but for endeavoring hackers it could provide some ideas or understanding on how
to set up a virtual environment without the puppet/chef hand-holding that is all
too prevalent these days. Bits and pieces, yo.


