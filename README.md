My Gentoo overlay
=================

Gentoo overlay with some ebuilds that I modified or created and are not yet in the official repository.


Included ebuilds
----------------

* nginx with built-in Passenger module
* dokuwiki (up-to-date version)

Feel free to contribute!


Using with Layman
-----------------

Use layman to easily install and update overlays over time.

If you haven’t used layman yet, just run these commands:

	USE=git emerge -va layman
	echo PORTDIR_OVERLAY=\"\" > /var/lib/layman/make.conf
	echo "source /var/lib/layman/make.conf" >> /etc/make.conf


Then you can add this overlay wih:

	layman -o https://raw.github.com/jirutka/gentoo-overlay/master/overlay.xml -a jirutka

Keep the overlay up to date from Git:

	layman -s jirutka
