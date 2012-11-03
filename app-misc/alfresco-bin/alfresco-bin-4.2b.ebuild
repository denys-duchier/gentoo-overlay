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

DESCRIPTION="Alfresco, Open Source Enterprise Content Management System (CMS)"
HOMEPAGE="http://alfresco.com/"
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}.zip"

LICENSE="LGPL-3"
SLOT="4.2"
KEYWORDS="~x86 ~amd64"
IUSE="postgres imagemagick"

TOMCAT_SLOT="7"

DEPEND="
	app-arch/unzip
	virtual/jre
	>=www-servers/tomcat-7.0.29"
RDEPEND="
	>=virtual/jdk-1.6
	postgres? ( dev-java/jdbc-postgresql )
	imagemagick? ( media-gfx/imagemagick[jpeg,png] )"

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

	# expand WARs
#	cd web-server/webapps
#	unzip -d alfresco alfresco.war
#	unzip -d share share.war
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

	diropts -m755
	keepdir "${conf}"

	diropts -m755 -o ${user} -g ${group}
	dodir "${dest}" "${dest}"/{webapps,bin,amps,amps_share}
	keepdir "${logs}"

	diropts -m750 -o ${user} -g ${group}
	dodir "${conf}"/Catalina/localhost
	dodir "${dest}"/work
	keepdir "${data}" "${data}"/keystore

	diropts -m700 -o ${user} -g ${group}
	dodir "${temp}"


	### Make symlinks ###

	dosym "${conf}" "${dest}"/conf
	dosym "${logs}" "${dest}"/logs
	dosym "${temp}" "${dest}"/temp


	### Copy files ###

	insinto "${dest}"/bin
	doins bin/*.jar

	exeinto "${dest}"/bin
	sed -i \
		-e "s|tomcat/temp/|/${temp}/|g" \
		-e "s|tomcat/work/|/${dest}/work/|g" \
		bin/clean_tomcat.sh \
		|| "failed to filter clean_tomcat.sh"
	doexe bin/clean_tomcat.sh

	cd web-server || die

	diropts -m755 -o ${user} -g ${group}
	insopts -m644 -o ${user} -g ${group}
	insinto "${dest}"
	doins -r endorsed shared


	### Deploy WARS ###

	# fix logs location inside WARs
	# it is shame that this cannot be configured externally...
	local webapps="${WORKDIR}/web-server/webapps"
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
	doins webapps/{alfresco.war,share.war}


	### Configs ###

	cp "${TOMCAT_HOME}"/conf/{catalina.policy,catalina.properties,context.xml,web.xml} \
		"${T}" || die "failed to copy configs from ${TOMCAT_HOME}/conf"
	
	# add classpaths to shared classloader
	local path='${catalina.base}/shared/classes,${catalina.base}/shared/lib/\*\.jar'
	sed -i \
		-e "s|.*\(shared.loader=\).*|\1${path}|" \
		"${T}"/catalina.properties \
		|| die "failed to filter catalina.properties"
	
	# filter logging.properties
	cp "${FILESDIR}"/logging.properties "${T}" || die
	sed -i \
		-e "s|@LOG_DIR@|${logs}|" "${T}"/logging.properties \
		|| die "failed to filter logging.properties"
	
    # filter server.xml
	# replace the default password with a random one
	cp "${FILESDIR}"/server.xml "${T}" || die
	local randpw=$(echo ${RANDOM}|md5sum|cut -c 1-15)
	sed -i \
		-e "s|@SHUTDOWN@|${randpw}|" \
		-e "s|@LOG_DIR@|${logs}|" \
		"${T}"/server.xml \
		|| die "failed to filter server.xml"

	# filter alfresco-global.properties
	cp "${FILESDIR}"/alfresco-global.properties "${T}" || die
	sed -i \
		-e "s|@DATA_DIR@|${data}|" \
		-e "s|@CONF_DIR@|${conf}|" \
		"${T}"/alfresco-global.properties \
		|| die "failed to filter alfresco-global.properties"


	### Configure database ###

	if use postgres; then
		local db_driver="org.postgresql.Driver"
		local db_url="jdbc:postgresql://localhost:5432/alfresco"
		local db_dialect="org.hibernate.dialect.PostgreSQLDialect"
		local db_subst="true TRUE, false FALSE"
		local jdbc_jar="jdbc-postgresql"
	fi

	cp "${FILESDIR}"/alfresco.xml "${T}" || die

	# unset hibernate.query.substitutions if $db_subst is empty
	if [ ! -n "${db_subst}" ]; then
		sed -i -e 's|value="@DB_SUBST@"||' "${T}"/alfresco.xml \
			|| "failed to filter alfresco.xml"
	fi
	sed -i \
		-e "s|@DB_DRIVER@|${db_driver}|" \
		-e "s|@DB_URL@|${db_url}|" \
		-e "s|@DB_DIALECT@|${db_dialect}|" \
		-e "s|@DB_SUBST@|${db_subst}|" \
		"${T}"/alfresco.xml \
		|| die "failed to filter alfresco.xml"
	

	### Copy configs ###

	insopts -m644 -o ${user} -g ${group}
	insinto "${conf}"
	doins "${T}"/{catalina.policy,catalina.properties,context.xml,web.xml,logging.properties}

	insopts -m640 -o ${user} -g ${group}
	doins "${T}"/{server.xml,alfresco-global.properties}

	diropts -m750 -o ${user} -g ${group}
	insinto "${conf}"/Catalina/localhost
	doins "${T}"/alfresco.xml

	# make symlinks
	dosym "${conf}"/alfresco-global.properties \
		"${dest}"/shared/classes/alfresco-global.properties
	dosym "${conf}"/Catalina/localhost/alfresco.xml "${conf}"/alfresco.xml


	### RC scripts ###

	cp "${FILESDIR}"/alfresco-tc.conf "${T}" || die
	local tfile="${T}"/alfresco-tc.conf

	local path; for path in "${FILESDIR}"/alfresco-tc.*; do
		cp "${path}" "${T}" || die
		local tfile="${T}"/`basename ${path}`
		sed -i \
			-e "s|@JDBC_JAR@|${jdbc_jar}|" \
			-e "s|@TOMCAT_HOME@|${TOMCAT_HOME}|" \
			-e "s|@DEST_DIR@|${dest}|" \
			-e "s|@TEMP_DIR@|${temp}|" \
			-e "s|@CONF_DIR@|${conf}|" \
			-e "s|@USER@|${user}|" \
			-e "s|@GROUP@|${group}|" \
			-e "s|@NAME@|Alfresco ${SLOT} in Tomcat-${TOMCAT_SLOT}|" \
			"${tfile}" \
			|| die "failed to filter `basename ${path}`"
	done

	newinitd "${T}"/alfresco-tc.init "${MY_NAME}-tc"
	newconfd "${T}"/alfresco-tc.conf "${MY_NAME}-tc"
}

pkg_postinst() {
	einfo "Removing old unpacked WARs"
	rm -Rf "${DEST_DIR}"/webapps/{alfresco,share} >/dev/null

	elog "Alfresco ${SLOT} requires a SQL database to run. You have to edit"
	elog "JDBC Data Source settings in '${CONF_DIR}/alfresco.xml' and then create" 
	elog "role and database for your Alfresco instance."
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
		ewarn "'/etc/conf.d/${MY_NAME}-tc'."
		ewarn
		ewarn "Do not forgot to change driverClassName, DB URL and Hibernate dialect"
		ewarn "in '${CONF_DIR}/alfresco.xml' as well."
	fi
}
