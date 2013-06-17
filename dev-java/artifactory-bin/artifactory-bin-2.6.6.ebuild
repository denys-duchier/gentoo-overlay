# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

# Mainteiner notes:
# - This ebuild supports Tomcat only for now.

inherit eutils

MY_PN="artifactory"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Artifactory Maven Artifact Server"
HOMEPAGE="http://www.jfrog.com/home/v_artifactory_opensource_overview"
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}.zip"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="postgres +tomcat"
REQUIRED_USE="tomcat" # see notes

TOMCAT_SLOT="7"

DEPEND="
	app-arch/unzip
	tomcat? ( >=www-servers/tomcat-7.0.29 )"
RDEPEND="
	>=virtual/jre-1.5
	>=virtual/jdk-1.5
	postgres? ( dev-java/jdbc-postgresql )"

S="${WORKDIR}/${MY_P}"

MERGE_TYPE="binary"

TOMCAT_HOME="/usr/share/tomcat-${TOMCAT_SLOT}"

MY_USER="artifact"
MY_GROUP="artifact"

INST_DIR="/usr/share/java/${MY_PN}"
HOME_DIR="/var/lib/${MY_PN}"
CONF_DIR="/etc/${MY_PN}"
LOGS_DIR="/var/log/${MY_PN}"
TEMP_DIR="/var/tmp/${MY_PN}"

pkg_setup() {
	enewgroup ${MY_GROUP}
	enewuser ${MY_USER} -1 /bin/sh -1 ${MY_GROUP}
}

src_install() {

    ### Prepare directories ###

	diropts -m700
	dodir ${TEMP_DIR}

	diropts -m750
	keepdir ${HOME_DIR}/{data,backup}
	dodir ${HOME_DIR}/work

	diropts -m755
	keepdir ${CONF_DIR} ${LOGS_DIR}


	### Install Tomcat instance ###

	insopts -m644
	insinto ${CONF_DIR}

	## server.xml ##

	local tfile="server.xml"
	local randpw=$(echo ${RANDOM}|md5sum|cut -c 1-15)

	cp ${FILESDIR}/${tfile} ${T} || die
	sed -i -e "s|@SHUTDOWN@|${randpw}|" \
		${T}/${tfile} || die "failed to filter ${tfile}"
	
	doins ${T}/${tfile}

	## tomcat-logging.properties ##

	doins ${FILESDIR}/tomcat-logging.properties

	## context.xml ##

	local tfile="context.xml"

	cp ${FILESDIR}/${tfile} ${T} || die
	sed -i -e "s|@DOC_BASE@|${INST_DIR}/lib/artifactory.war|" \
		${T}/${tfile} || die "failed to filter ${tfile}"
	
	insinto ${CONF_DIR}/Catalina/localhost
	newins ${T}/${tfile} ROOT.xml

	## make symlinks ##

	dosym ${TOMCAT_HOME}/conf/web.xml ${CONF_DIR}/web.xml
	dosym ${CONF_DIR} ${HOME_DIR}/etc
	dosym ${CONF_DIR} ${HOME_DIR}/conf
	dosym ${LOGS_DIR} ${HOME_DIR}/logs


	## Install Artifactory ##

	## install WAR and libs ##

	insinto ${INST_DIR}/lib
	doins webapps/artifactory.war
	
	insinto ${INST_DIR}/lib/cli
	doins clilib/*.jar

	## install CLI ##

	insinto ${INST_DIR}/bin
	doins artifactory.jar

	local tfile="artadmin"
	cp ${FILESDIR}/${tfile} ${T} || die
	sed -i \
		-e "s|@CLI_JAR@|${INST_DIR}/bin/artifactory.jar|" \
		-e "s|@LIB_DIR@|${INST_DIR}/lib/cli|" \
		${T}/${tfile} || die "failed to filter ${tfile}"

	exeinto /usr/bin
	doexe ${T}/${tfile}

	## artifactory configs ##

	insinto ${CONF_DIR}

	local tfile=etc/artifactory.system.properties
	sed -i \
		-e 's|#*\(artifactory.jcr.configDir=\).*|\1repo|' \
		${tfile} || die "failed to filter ${tfile}"
	doins ${tfile}

	doins etc/{artifactory.config,logback,mimetypes}.xml

	## repository configs ##

	insinto ${CONF_DIR}/repo

	if use postgres; then
		local extra_jars="jdbc-postgresql"

		local tfile=etc/repo/filesystem-postgresql/repo.xml
		local range='/<DataSource.*>/,/<\/DataSource>/'
		sed -i \
			-e "${range} s|artifactory_user|artifactory|" \
			-e "${range} s|<!--.*validationQuery.*|<param name=\"validationQuery\" value=\"select 1\"/>|" \
			-e "${range} s|<!--.*maxPoolSize.*|<param name=\"maxPoolSize\" value=\"25\"/>|" \
			${tfile} || die "failed to filter repo.xml"
		doins ${tfile}

		newins etc/repo/filesystem-derby/repo.xml repo.xml.derby
	else
		doins etc/repo/filesystem-derby/repo.xml
	fi

	## increase limit for number of open files ##

	echo "${MY_USER} hard nofile 32000" > ${T}/limits
	insinto /etc/security/limits.d
	newins ${T}/limits ${MY_PN}.conf


	### Fix permissions ####

	fowners -R ${MY_USER}:${MY_GROUP} ${HOME_DIR} ${CONF_DIR} ${TEMP_DIR} ${LOGS_DIR}

	fperms 640 ${CONF_DIR}/server.xml
	fperms 640 ${CONF_DIR}/repo/repo.xml


	### RC scripts ###

	local path; for path in ${FILESDIR}/${MY_PN}-tc.*; do
		cp ${path} ${T} || die
		local tfile=${T}/`basename ${path}`
		sed -i \
			-e "s|@ARTIFACTORY_HOME@|${HOME_DIR}|" \
			-e "s|@TOMCAT_SLOT@|${TOMCAT_SLOT}|" \
			-e "s|@CATALINA_HOME@|${TOMCAT_HOME}|" \
			-e "s|@CATALINA_BASE@|${HOME_DIR}|" \
			-e "s|@EXTRA_JARS@|${extra_jars}|" \
			-e "s|@TEMP_DIR@|${TEMP_DIR}|" \
			-e "s|@CONF_DIR@|${CONF_DIR}|" \
			-e "s|@USER@|${MY_USER}|" \
			-e "s|@GROUP@|${MY_GROUP}|" \
			-e "s|@NAME@|Artifactory|" \
			${tfile} \
			|| die "failed to filter `basename ${path}`"
	done

	newinitd ${T}/${MY_PN}-tc.init ${MY_PN}
	newconfd ${T}/${MY_PN}-tc.conf ${MY_PN}
}

pkg_postinst() {
	ewarn "Cleaning ${HOME_DIR}/work ..."
	rm -Rf "${HOME_DIR}"/work/* 2>/dev/null

	elog "Artifactory uses SQL database to store metadata and file system" 
	elog "storage for binary files. These will be stored in"
	elog "'${HOME_DIR}', ensure that there is enough space."
	elog

	if use postgres; then
		elog "To use PostgreSQL as your database storage, edit DataSource settings"
		elog "in '${CONF_DIR}/repo/repo.xml' and then create role and database for"
		elog "your Artifactory instance."
		elog
		elog "If you have local PostgreSQL running, you can just copy&run:"
		elog "    su postgres"
		elog "    psql -c \"CREATE ROLE ${MY_PN} PASSWORD 'password' \\"
		elog "        NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;\""
		elog "    createdb -E UTF-8 -O ${MY_PN} ${MY_PN}"
		elog "Note: You should change your password to something more random..."
	else
		elog "Derby database is already preconfigured for you. If you want to see"
		elog "config anyway, it's in '${CONF_DIR}/repo/repo.xml'."
	fi

	elog
	elog "The default password for user 'admin' is 'password'."
}
