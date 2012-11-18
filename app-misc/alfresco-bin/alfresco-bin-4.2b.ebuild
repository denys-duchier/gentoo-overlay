# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
#
# Author: Jakub Jirutka <jakub@jirutka.cz>
#

EAPI="4"

inherit eutils

MY_PV="${PV%?}.${PV: -1}"  # ex. 4.2b -> 4.2.b
MY_P="alfresco-community-${MY_PV}"
MY_PN="alfresco"

DESCRIPTION="Alfresco Open Source Enterprise Content Management System"
HOMEPAGE="http://alfresco.com/"
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}.zip"

LICENSE="LGPL-3"
SLOT="4.2"
KEYWORDS="~x86 ~amd64"
IUSE="+postgres +imagemagick +share ooodirect"

TOMCAT_SLOT="7"

DEPEND="
	app-arch/unzip
	virtual/jre
	>=www-servers/tomcat-7.0.29"
RDEPEND="
	>=virtual/jdk-1.6
	postgres? ( dev-java/jdbc-postgresql )
	imagemagick? ( media-gfx/imagemagick[jpeg,png] )
	ooodirect? ( 
		|| ( app-office/libreoffice 
			app-office/libreoffice-bin 
			app-office/openoffice-bin ) )"

S="${WORKDIR}"

MY_NAME="${MY_PN}-${SLOT}"
MY_USER=${MY_PN}
MY_GROUP="${MY_PN}"

TOMCAT_HOME="/usr/share/tomcat-${TOMCAT_SLOT}"
DEST_DIR="/opt/${MY_NAME}"
CONF_DIR="/etc/${MY_NAME}"

pkg_setup() {
	ebegin "Creating alfresco user and group"
    enewgroup ${MY_GROUP} \
		|| die "Unable to create ${MY_GROUP} group"
    enewuser ${MY_USER} -1 /bin/sh "/opt/${MY_NAME}" ${MY_GROUP} \
		|| die "Unable to create ${MY_USER} user"
}

src_prepare() {
    # fix permissions
    chmod -R a-x,a+X bin web-server
}

src_install() {
	local conf="${CONF_DIR}"
	local dest="${DEST_DIR}"
	local logs="/var/log/${MY_NAME}"
	local temp="/var/tmp/${MY_NAME}"
	local data="${dest}"/data

	local user="${MY_USER}"
	local group="${MY_GROUP}"


	### Prepare directories ###

	diropts -m700
	keepdir "${data}"
	dodir "${temp}"

	diropts -m750
	dodir "${conf}"/Catalina/localhost
	dodir "${dest}"/work

	diropts -m755
	keepdir "${conf}" "${logs}" "${dest}"/amps

	dosym "${conf}" "${dest}"/conf
	dosym "${logs}" "${dest}"/logs
	dosym "${temp}" "${dest}"/temp


	### Copy files ###

	insinto "${dest}"/bin
	exeinto "${dest}"/bin

	doins bin/*.jar

	sed -i \
		-e "s|tomcat/temp/|${temp}/|g" \
		-e "s|tomcat/work/|${dest}/work/|g" \
		bin/clean_tomcat.sh \
		|| "failed to filter clean_tomcat.sh"
	doexe bin/clean_tomcat.sh

	cp "${FILESDIR}"/generate_keystores.sh "${T}" || die
	sed -i -e "s|@CONF_DIR@|${conf}|" \
		"${T}"/generate_keystores.sh \
		|| "failed to filter generate_keystores.sh"
	doexe "${T}"/generate_keystores.sh

	insinto "${dest}"
	doins -r web-server/{endorsed,shared}

	cd web-server || die


	### Deploy WARs ###

	local webapps="${WORKDIR}/web-server/webapps"

	# fix logs location inside WARs
	# it is shame that this cannot be configured externally...
	local war; for war in "${webapps}"/{alfresco.war,share.war}; do
		local tfile="WEB-INF/classes/log4j.properties"
		local key='log4j.appender.File.File'
		local prefix='${catalina.base}/logs/'

		echo -n "    Updating `basename ${war}` ..."

		cd "${T}"
		jar xf "${war}" "${tfile}" || die "failed to extract ${tfile}"
		sed -i \
			-e "s|\(${key}=\)\(.*/\)\?\([\w\.]*\)|\1${prefix}\3|" \
			${tfile} || die "failed to modify log4j.properties"
		jar uf "${war}" "${tfile}" || die "failed to update ${tfile}"

		rm -Rf "${tfile}"
		cd "${WORKDIR}"/web-server

		echo "done"
	done

	insinto "${dest}"/webapps
	doins webapps/alfresco.war
	if use share; then
		doins webapps/share.war
	fi

	## Copy default keystores from alfresco.war ##

	local _keystore="WEB-INF/classes/alfresco/keystore"

	cd "${T}"
	jar xf "${webapps}"/alfresco.war "$_keystore" \
		|| die "failed to extract $_keystore from alfresco.war"
	rm "$_keystore"/{CreateSSLKeystores.txt,generate_keystores.*}

	insinto "${conf}"/keystore
	doins "$_keystore"/*

	cd "${WORKDIR}"/web-server


	### Configs ###

	insinto "${conf}"

	## Filter and install catalina.properties ##

	local tfile="catalina.properties"

	cp "${TOMCAT_HOME}/conf/${tfile}" \
		"${T}" || die "failed to copy ${tfile} from ${TOMCAT_HOME}/conf"

	# add classpaths to shared classloader
	local path='${catalina.base}/shared/classes,${catalina.base}/shared/lib/\*\.jar'
	sed -i \
		-e "s|.*\(shared.loader=\).*|\1${path}|" \
		"${T}/${tfile}" \
		|| die "failed to filter ${tfile}"

	doins "${T}/${tfile}"
	
	## Filter and install tomcat-logging.properties ##

	local tfile="tomcat-logging.properties"

	cp "${FILESDIR}/${tfile}" "${T}" || die
	sed -i \
		-e "s|@LOG_DIR@|${logs}|" \
		"${T}/${tfile}" || die "failed to filter ${tfile}"

	doins "${T}/${tfile}"
	
    ## Filter and install server.xml ##

	local tfile="server.xml"
	local randpw=$(echo ${RANDOM}|md5sum|cut -c 1-15)

	cp "${FILESDIR}/${tfile}" "${T}" || die

	# replace the default password with a random one
	sed -i \
		-e "s|@SHUTDOWN@|${randpw}|" \
		-e "s|@LOG_DIR@|${logs}|" \
		"${T}/${tfile}" || die "failed to filter ${tfile}"
	
	doins "${T}/${tfile}"

	## Filter and install alfresco-global.properties ##

	local tfile="alfresco-global.properties"

	cp "${FILESDIR}/${tfile}" "${T}" || die

	sed -i \
		-e "s|@DATA_DIR@|${data}|" \
		-e "s|@CONF_DIR@|${conf}|" \
		"${T}/${tfile}" || die "failed to filter ${tfile}"

	# enable OOoDirect if USEd
	if use ooodirect; then
		sed -i -e "s|.*\(ooo.enabled=\).*|\1true|" \
			"${T}/${tfile}" \
			|| die "failed to filter ${tfile}"
	fi

	doins "${T}/${tfile}"

	## Install tomcat-users.xml ##

	doins "${FILESDIR}"/tomcat-users.xml

	## Filter and install alfresco-context.xml ##

	local tfile="alfresco-context.xml"

	if use postgres; then
		local db_driver="org.postgresql.Driver"
		local db_url="jdbc:postgresql://localhost:5432/alfresco"
		local db_test_query="select 1"
		local db_dialect="org.hibernate.dialect.PostgreSQLDialect"
		local db_subst="true TRUE, false FALSE"
		local jdbc_jar="jdbc-postgresql"
	fi

	cp "${FILESDIR}/${tfile}" "${T}" || die

	# unset hibernate.query.substitutions if $db_subst is empty
	if [ ! -n "${db_subst}" ]; then
		sed -i \
			-e 's|value="@DB_SUBST@"||' \
			"${T}/${tfile}" || "failed to filter ${tfile}"
	fi
	sed -i \
		-e "s|@DB_DRIVER@|${db_driver}|" \
		-e "s|@DB_URL@|${db_url}|" \
		-e "s|@DB_TEST_QUERY@|${db_test_query}|" \
		-e "s|@DB_DIALECT@|${db_dialect}|" \
		-e "s|@DB_SUBST@|${db_subst}|" \
		"${T}/${tfile}" || die "failed to filter ${tfile}"
	
	insinto "${conf}"/Catalina/localhost
	newins "${T}/${tfile}" alfresco.xml

	## Make symlinks ##

	dosym "${TOMCAT_HOME}"/conf/web.xml "${conf}"/web.xml
	dosym "${conf}"/alfresco-global.properties \
		"${dest}"/shared/classes/alfresco-global.properties
	dosym "${conf}"/Catalina/localhost/alfresco.xml "${conf}"/alfresco-context.xml


	### Fix permissions ###

	fowners -R ${user}:${group} "${dest}" "${conf}" "${temp}" "${logs}"
	fperms 640 "${conf}"/{server.xml,tomcat-users.xml,alfresco-global.properties}
	fperms 600 "${conf}"/keystore/ssl-{key,trust}store-passwords.properties


	### RC scripts ###

	cp "${FILESDIR}"/alfresco-tc.conf "${T}" || die
	local tfile="${T}"/alfresco-tc.conf

	local path; for path in "${FILESDIR}"/alfresco-tc.*; do
		cp "${path}" "${T}" || die
		local tfile="${T}"/`basename ${path}`
		sed -i \
			-e "s|@CATALINA_HOME@|${TOMCAT_HOME}|" \
			-e "s|@CATALINA_BASE@|${dest}|" \
			-e "s|@EXTRA_JARS@|${jdbc_jar}|" \
			-e "s|@TEMP_DIR@|${temp}|" \
			-e "s|@CONF_DIR@|${conf}|" \
			-e "s|@USER@|${user}|" \
			-e "s|@GROUP@|${group}|" \
			-e "s|@NAME@|Alfresco ${SLOT}|" \
			"${tfile}" \
			|| die "failed to filter `basename ${path}`"
	done

	newinitd "${T}"/alfresco-tc.init "${MY_NAME}"
	newconfd "${T}"/alfresco-tc.conf "${MY_NAME}"
}

pkg_postinst() {
	einfo "Removing old unpacked WARs"
	rm -Rf "${DEST_DIR}"/webapps/{alfresco,share} >/dev/null

	elog "Alfresco ${SLOT} requires a SQL database to run. You have to edit"
	elog "JDBC Data Source settings in '${CONF_DIR}/alfresco-context.xml' and then"
	elog "create role and database for your Alfresco instance."
	elog

	if use postgres; then
		elog "If you have local PostgreSQL running, you can just copy&run:"
		elog "    su postgres"
		elog "    psql -c \"CREATE ROLE alfresco PASSWORD 'alfresco' \\"
		elog "        NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;\""
		elog "    createdb -E UTF-8 -O alfresco alfresco"
		elog "Note: You should change your password to something more random..."
	else
		ewarn "Since you have not set any database USE flag, you need to install" 
		ewarn "an appropriate JDBC driver and add it to TOMCAT_EXTRA_JARS in"
		ewarn "'/etc/conf.d/${MY_NAME}'."
		ewarn
		ewarn "Do not forgot to change driverClassName, DB URL and Hibernate dialect"
		ewarn "in '${CONF_DIR}/alfresco-context.xml' as well."
	fi

	elog
    elog "Keystores in ${CONF_DIR}/keystore was populated with"
    elog "default certificates provided by Alfresco, Ltd. If you are going to" 
	elog "use SOLR, in production environment, you should generate your own"
	elog" certificates and keystores. You can use provided script:"
	elog "    ${DEST_DIR}/bin/generate_keystores.sh"
}
