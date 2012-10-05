CVUT Gentoo overlay
===================

Gentoo overlay with some ebuilds created or modified on [CTU](http://www.cvut.cz/) and are not yet in the official repository.


List of ebuilds
---------------

* **dev-java/jboss-as-bin-7.1** - binary package, standalone mode only, proper init script included!
* **dev-java/oracle-jdk-bin** - with automatic sources fetching (we all hate manual downloading all the time)
* **dev-util/sonar-bin** - proper ebuild, much better than godin’s :)
* **net-misc/minidlna** - with improved ebuild and init script
* **www-servers/nginx** - with built-in Passenger module (for ree18 and ruby19)

Feel free to contribute!


Using with Layman
-----------------

Use layman to easily install and update overlays over time.

If you haven’t used layman yet, just run these commands:

	USE=git emerge -va layman
	echo PORTDIR_OVERLAY=\"\" > /var/lib/layman/make.conf
	echo "source /var/lib/layman/make.conf" >> /etc/make.conf


Then you can add this overlay wih:

	layman -o https://raw.github.com/cvut/gentoo-overlay/master/overlay.xml -f -a cvut

Keep the overlay up to date from Git:

	layman -s cvut


Maintainers
-----------

* [Jakub Jirutka](mailto:jirutjak@fit.cvut.cz)
