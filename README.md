CVUT Gentoo overlay
===================

Gentoo overlay with some ebuilds created or modified on [CTU](http://www.cvut.cz/) and are not yet in the official repository.


List of ebuilds
---------------

* **app-misc/alfresco-bin** (4.2.b)
* **app-misc/alfresco-solr-bin** (4.2.b)
* **dev-java/jboss-as-bin** (7.1)
   * binary package, standalone mode only, proper init script included!
* **dev-java/oracle-jdk-bin** (1.7.0.6)
   * with automatic sources fetching (we all hate manual downloading all the time)
* **dev-util/sonar-bin** (3.2)
   * proper ebuild, much better than godin’s :)
* **media-gfx/swftools** (0.9.2)
   * with enabled pdf2swf without poppler (see [#412423](https://bugs.gentoo.org/show_bug.cgi?id=412423))
* **net-misc/minidlna** (1.0.24)
   * with improved ebuild and init script
* **www-apps/liferay-portal-bin** (6.1.1)
* **www-servers/nginx** (1.2.2)
   * with built-in Passenger module (for ree18 and ruby19), [sticky module](http://code.google.com/p/nginx-sticky-module/), [chunkin module](https://github.com/agentzh/chunkin-nginx-module) and customized config
* **www-servers/tomcat** (7.0.32)
   * customized Tomcat ebuild with improved tomcat-instances manager, config files and support for JMX

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
