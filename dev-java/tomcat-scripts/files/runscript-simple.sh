#!/sbin/runscript
# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

source /usr/share/tomcat-scripts/runscript.sh

catalina_home=
catalina_base=
catalina_temp=

depend() {
	use net
}
