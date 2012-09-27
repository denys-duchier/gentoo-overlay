# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

MY_PV="${PV/_alpha/M}"
MY_PV="${MY_PV/_rc/-RC}"
MY_P="sonar-${MY_PV}"

inherit eutils

DESCRIPTION="Sonar is an open platform to manage code quality."
HOMEPAGE="http://sonarsource.org/"
SRC_URI="http://dist.sonar.codehaus.org/${MY_P}.zip"

LICENSE="LGPL-3"
SLOT="3.2"
KEYWORDS="~x86 ~amd64"

IUSE=""
RESTRICT="mirror"

DEPEND="app-arch/unzip"
RDEPEND=">=virtual/jdk-1.5"

S="${WORKDIR}/${MY_P}"

MY_NAME="sonar"
MY_SLOTNAME="${MY_NAME}-${SLOT}"

INSTALL_DIR="/opt/${PN}-${SLOT}"
CLIB_DIR="${INSTALL_DIR}/clib"
CONF_DIR="/etc/${MY_SLOTNAME}"
LOG_DIR="/var/log/${MY_SLOTNAME}"
TEMP_DIR="/var/tmp/${MY_SLOTNAME}"
OWNERS="${MY_NAME}:${MY_NAME}"

pkg_setup() {
	ebegin "Creating sonar user and group"
    enewgroup ${MY_NAME} \
		|| die "Unable to create ${MY_NAME} group"
    enewuser ${MY_NAME} -1 /bin/sh ${INSTALL_DIR} ${MY_NAME} \
		|| die "Unable to create ${MY_NAME} user"
}

src_prepare() {
    # fix permissions
    chmod -R a-x,a+X conf data extensions extras lib war COPYING

    # fix EOL in configuration files
    for i in conf/* ; do
        awk '{ sub("\r$", ""); print }' $i > $i.new
        mv $i.new $i
    done

	# change file locations
	sed -i \
		-e "s|^\(wrapper.java.classpath.[1-9]=\)\.\./\.\.\(.*\)|\1${INSTALL_DIR}\2|" \
		-e "s|^\(wrapper.java.library.path.1=\).*|\1${CLIB_DIR}|" \
		-e "s|^\(wrapper.logfile=\).*|\1${LOG_DIR}/wrapper.log|" conf/wrapper.conf \
		|| die "Changing file locations in wrapper.conf failed"
	
	# add wrapper.syslog.ident property
	sed -i -e "/wrapper.syslog.loglevel/a \
		\\n# Specifiy the identity field used in syslog entries \
		\nwrapper.syslog.ident=sonar" conf/wrapper.conf \
		|| die "Adding new property to wrapper.conf failed"

    # remove useless Windows config sections
	sed -i \
		-e '/Wrapper Windows Properties/N;//,/^#\*\*/d' \
		-e '/Wrapper Windows NT/N;//,/^#\*\*/d' conf/wrapper.conf \
		|| die "Removing useless config sections in wrapper.conf failed"
	
	# change config files location
	for dir in bin/linux* ; do
		sed -i -e "s|^\(WRAPPER_CONF=\).*|\1${CONF_DIR}/wrapper.conf|" "$dir/sonar.sh" \
			|| die "Changing config files location in sonar.sh failed"
	done

	# change log files location
	sed -i -e "s|\${SONAR_HOME}/logs|${LOG_DIR}|" conf/logback.xml
}

src_install() {
	diropts -m755
	dodir "${INSTALL_DIR}"

	# copy war
	insinto "${INSTALL_DIR}/war"
	doins -r war/sonar-server
	fowners -R ${OWNERS} "${INSTALL_DIR}/war/sonar-server/deploy"

	# copy extensions and lib dirs
	insinto "${INSTALL_DIR}"
	doins -r extensions lib
	fowners -R ${OWNERS} "${INSTALL_DIR}/extensions"

	# copy wrapper bin and lib
	if use x86; then
		wrapper_bin="bin/linux-x86-32"
		wrapper_lib="${wrapper_bin}/lib"
	elif use amd64; then
		wrapper_bin="bin/linux-x86-64"
		wrapper_lib="${wrapper_bin}/lib"
	fi
	exeinto "${INSTALL_DIR}/bin"
	doexe ${wrapper_bin}/{sonar.sh,wrapper}
	exeinto "${CLIB_DIR}"
	doexe "${wrapper_lib}/libwrapper.so"

	# copy conf
	insinto "${CONF_DIR}"
	doins conf/*
	dosym "${CONF_DIR}" "${INSTALL_DIR}/conf"

	# prepare log, temp, data directories
	diropts -m750 -o ${MY_NAME} -g ${MY_NAME}
	keepdir "${LOG_DIR}"
	keepdir "${INSTALL_DIR}/data"

	diropts -m700 -o ${MY_NAME} -g ${MY_NAME}
	keepdir "${TEMP_DIR}"
	dosym "${TEMP_DIR}" "${INSTALL_DIR}/temp"

	# filter and copy init script
	cp "${FILESDIR}/sonar.init" "${T}"
	tfile="${T}/sonar.init"
	sed -i \
		-e "s|__SLOTNAME__|${MY_SLOTNAME}|g" \
		-e "s|__SONAR_VER__|${SLOT}|g" \
		-e "s|__BASE_DIR__|${INSTALL_DIR}|g" "${tfile}" \
		|| die "Filtering sonar.init failed"
	newinitd "${tfile}" ${MY_SLOTNAME}
}

pkg_postinst() {
	einfo "The embedded database H2 is used by default. However, it is"
	einfo "recommended for tests only, for production environment you must" 
	einfo "use an external database like PostgreSQL.\n"
	einfo "Sonar with embedded Jetty is listening on port 9000 by default.\n"
	einfo "All these settings you can configure in:"
	einfo "        /etc/${MY_SLOTNAME}/sonar.properties"

}
