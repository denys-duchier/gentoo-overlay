My Gentoo overlay
=================

Gentoo overlay with some ebuilds that I modified or created and are not yet in the official repository.


Included ebuilds
----------------

* dev-java/jboss-as-bin-7.1 - for binary package, standalone mode only, proper init script included!
* dev-java/oracle-jdk-bin - with automatic sources fetching (I really hate manual downloading all the time)
* net-misc/minidlna - with improved ebuild and init script
* web-apps/dokuwiki - only bumped version number
* www-servers/nginx - with built-in Passenger module (for ree18 and ruby19)

Feel free to contribute!


Using with Layman
-----------------

Use layman to easily install and update overlays over time.

If you haven’t used layman yet, just run these commands:

	USE=git emerge -va layman
	echo PORTDIR_OVERLAY=\"\" > /var/lib/layman/make.conf
	echo "source /var/lib/layman/make.conf" >> /etc/make.conf


Then you can add this overlay wih:

	layman -o https://raw.github.com/jirutka/gentoo-overlay/master/overlay.xml -f -a jirutka

Keep the overlay up to date from Git:

	layman -s jirutka
