# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# @ECLASS: tomcat.eclass
# @MAINTAINER: jakub@jirutka.cz
# @BLURB: TODO
# @DESCRIPTION:
# TODO


# @ECLASS-VARIABLE: TOMCAT_INSTANCE
# @DEFAULT: ${PN}
# @DESCRIPTION:
# Name of the Tomcat instance to create for this package, typically same as the
# package name.

# @ECLASS-VARIABLE: TOMCAT_HOME
# @DEFAULT: /usr/share/tomcat-${TOMCAT_SLOT}
# @DESCRIPTION:
# Directory path where are Tomcat shared files installed (ie. CATALINA_HOME).

# @ECLASS-VARIABLE: TOMCAT_BASE
# @DEFAULT: /opt/${TOMCAT_INSTANCE}
# @DESCRIPTION: TODO

# @ECLASS-VARIABLE: TOMCAT_CONF
# @DEFAULT: /etc/${TOMCAT_INSTANCE}
# @DESCRIPTION:
# Directory path where to install configuration files.

# @ECLASS-VARIABLE: TOMCAT_LOGS
# @DEFAULT: /var/log/${TOMCAT_INSTANCE}
# @DESCRIPTION:
# Directory path to create for log files.

# @ECLASS-VARIABLE: TOMCAT_TEMP
# @DEFAULT: /var/tmp/${TOMCAT_INSTANCE}
# @DESCRIPTION:
# Directory path to create for temporary files.

# @ECLASS-VARIABLE: TOMCAT_WEBAPPS
# @DEFAULT: ${TOMCAT_BASE}/webapps
# @DESCRIPTION:
# Directory path where actual web application(s) will be installed.

# @ECLASS-VARIABLE: TOMCAT_USER
# @DEFAULT: tomcat
# @DESCRIPTION: 
# User that will be owner of the webapp's files and will run the Tomcat 
# instance. It will be created if no exists yet.

# @ECLASS-VARIABLE: TOMCAT_GROUP
# @DEFAULT: ${TOMCAT_USER}
# @DESCRIPTION: TODO

# @ECLASS-VARIABLE: TOMCAT_EXPAND_WAR
# @DEFAULT: yes
# @DESCRIPTION: 
# If set to 'yes' then deployed WARs will be unpacked.

# @ECLASS-VARIABLE: TOMCAT_COPY_DEFAULT_CONFS
# @DEFAULT: yes
# @DESCRIPTION: 
# If set to 'yes' then 'tomcat_prepare' function will copy default config files
# for Tomcat; server.xml, web.xml and logging.properties.


TOMCAT_SLOT="7"
TOMCAT_DEFAULT_INITD="/usr/share/tomcat-scripts/runscript-simple.sh"
TOMCAT_DEFAULT_CONFD="/usr/share/tomcat-scripts/runscript.conf"

DEPEND="
	>=virtual/jre-1.6
	app-arch/unzip
	>=www-servers/tomcat-7.0.29
	dev-java/tomcat-scripts"
RDEPEND="
	>=virtual/jdk-1.6"


EXPORT_FUNCTIONS pkg_setup pkg_preinst pkg_postinst


###############################################################################
#                             PUBLIC FUNCTIONS
#

#------------------------------------------------------------------------------
# @FUNCTION: tomcat_prepare
# @DESCRIPTION:
# Creates all directories needed for Tomcat. If 'TOMCAT_COPY_DEFAULT_CONFS'
# is 'yes' then it also copies default server.xml, web.xml and
# logging.properties.
#------------------------------------------------------------------------------
tomcat_prepare() {
	debug-print-function ${FUNCNAME} $*

	tomcat_init_vars_

	diropts -m755
	dodir ${TOMCAT_CONF}

	diropts -m755 -o ${TOMCAT_USER} -g ${TOMCAT_GROUP}
	dodir ${TOMCAT_BASE}
	dodir ${TOMCAT_WEBAPPS}
	keepdir ${TOMCAT_LOGS}

	diropts -m750 -o root -g ${TOMCAT_GROUP}
	dodir ${TOMCAT_CONF}/Catalina/localhost

	diropts -m700 -o ${TOMCAT_USER} -g ${TOMCAT_GROUP}
	keepdir ${TOMCAT_BASE}/work
	keepdir ${TOMCAT_TEMP}

	# webapps expects these dirs so make symlinks
	dosym ${TOMCAT_CONF} ${TOMCAT_BASE}/conf
	dosym ${TOMCAT_LOGS} ${TOMCAT_BASE}/logs

	if [[ "${TOMCAT_COPY_DEFAULT_CONFS}" = 'yes' ]]; then
		doconf ${TOMCAT_HOME}/conf/{server.xml,logging.properties}

		# in most cases web.xml don't need any changes so just link it
		dosym ${TOMCAT_HOME}/conf/web.xml ${TOMCAT_CONF}/web.xml
	fi

	# set to default
	diropts -m755
}

#------------------------------------------------------------------------------
# @FUNCTION: dowar
# @USAGE: dowar [war|dir]*
# @DESCRIPTION:
# Installs WAR file/s or directory/is (expanded WAR) into ${TOMCAT_WEBAPPS}.
# See newwar() for more details.
#------------------------------------------------------------------------------
dowar() {
	debug-print-function ${FUNCNAME} $*
	[[ $# -lt 1 ]] && die "At least one argument needed"

	local war; for war in $* ; do
		newwar ${war} $(basename ${war})
	done
}

#------------------------------------------------------------------------------
# @FUNCTION: newwar
# @USAGE: newwar <war> <new name>
# @DESCRIPTION:
# Installs WAR file or directory (expanded WAR) into ${TOMCAT_WEBAPPS} under
# new name. If 'TOMCAT_EXPAND_WAR' is 'yes' then it also unpacks WAR file/s.
# Installed files will be owned by ${TOMCAT_USER}:${TOMCAT_GROUP} 
# with chmod 755/644.
#------------------------------------------------------------------------------
newwar() {
	# doins is slow for huge number of files therefore used plain cp.
	debug-print-function ${FUNCNAME} $*

	local src_path="${1}"
	[[ -z ${src_path} ]] && die "must specify a war or dir to install"
	[[ ! -e ${src_path} ]] && die "${src_path} does not exist!"

	local dest_name="${2}"
	[[ -z ${dest_name} ]] && die "must specify a target war or dir name"

	local dest_path="${D}/${TOMCAT_WEBAPPS}/${dest_name}"

	if [[ ${TOMCAT_EXPAND_WAR} = 'yes' && -f ${src_path} ]]; then
		dest_path="${dest_path%.*}"  # strip suffix if any
		mkdir -p ${dest_path}
		unzip -d ${dest_path} ${src_path} \
			|| die "failed to unpack ${src_path} to ${dest_path}"

	elif [[ -d ${src_path} ]]; then
		mkdir -p ${dest_path}
		cp -rl ${src_path}/* ${dest_path} \
			|| die "failed to copy ${src_path} to ${dest_path}"

	else
		cp -l ${src_path} ${dest_path} \
			|| die "failed to copy ${src_path} to ${dest_path}"
	fi

	# fix permissions
	find ${dest_path} -type d -exec chmod 755 {} + \
		&& find ${dest_path} -type f -exec chmod 644 {} + \
		|| die "failed to change perms on ${dest_path}"
	chown -R ${TOMCAT_USER}:${TOMCAT_GROUP} ${dest_path} \
		|| die "failed to change owner of ${dest_path}"
}


confinto() {
	debug-print-function ${FUNCNAME} $*
	
	# is path absolute?
	if [[ ${1} == /* ]]; then
		TOMCAT_CONFDEST="${1}"
	else
		TOMCAT_CONFDEST="${TOMCAT_CONF}/${1}"
	fi
}

confopts() {
	debug-print-function ${FUNCNAME} $*
	
	TOMCAT_CONFOPTS="${1}"
}

doconf() {
	debug-print-function ${FUNCNAME} $*
	[[ $# -lt 1 ]] && die "At least one argument needed"

	local conf; for conf in $* ; do
		INSOPTIONS="${TOMCAT_CONFOPTS}" \
			INSDESTTREE="${TOMCAT_CONFDEST}" \
			doins ${conf}
	done
}

newconf() {
	debug-print-function ${FUNCNAME} $*

	local original_conf="${1}"
	[[ -z ${original_conf} ]] && die "must specify config file to install"
	[[ ! -f ${original_conf} ]] \
		&& die "${original_conf} does not exist or not a file!"

	local new_conf="${2}"
	[[ -z ${new_conf} ]] && die "must specify new config file name"
	
	INSOPTIONS="${TOMCAT_CONFOPTS}" \
		INSDESTTREE="${TOMCAT_CONFDEST}" \
		newins ${original_conf} ${new_conf}
}


tomcat_doinitd() {
	debug-print-function ${FUNCNAME} $*

	initd_file=${1:-${TOMCAT_DEFAULT_INITD}}

	local filtered="${T}/`basename ${initd_file}`"
	tomcat_filter_config_ ${initd_file} ${filtered}

	newinitd ${filtered} ${TOMCAT_INSTANCE}
}

tomcat_doconfd() {
	debug-print-function ${FUNCNAME} $*

	confd_file=${1:-${TOMCAT_DEFAULT_CONFD}}

	local filtered="${T}/`basename ${confd_file}`"
	tomcat_filter_config_ ${confd_file} ${filtered}

	newconfd ${filtered} ${TOMCAT_INSTANCE}
}

tomcat_pkg_setup() {
	tomcat_init_vars_

	enewgroup ${TOMCAT_GROUP}
	enewuser ${TOMCAT_USER} -1 /bin/sh -1 ${TOMCAT_GROUP}
}

tomcat_pkg_preinst() {
	elog "Replacing default server shutdown password with random ..."

	local server_xml="${D}/${TOMCAT_CONF}/server.xml"
	local randpw=$(echo ${RANDOM}|md5sum|cut -c 1-15)

	sed -i \
		-e "/<Server/,/>/ s/\(shutdown=[\"']\)[^\"']*/\1${randpw}/" \
		${server_xml} || die "failed to replace shutdown password in server.xml"
	chmod 640 ${server_xml}
}

tomcat_pkg_postinst() {
	einfo
	einfo "A separate instance of Tomcat ${TOMCAT_SLOT} servlet container was created" \ 
	einfo "for ${PN}. Check ${TOMCAT_CONF}/server.xml and change a server" 
	einfo "and connector port if default ones are not suitable for you."
	einfo "You might also want to tune memory parameters for JVM in"
	einfo "/etc/conf.d/${TOMCAT_INSTANCE}."
}


###############################################################################
#                            PRIVATE FUNCTIONS
#

tomcat_init_vars_() {
	: ${TOMCAT_INSTANCE:="${PN}"}
	: ${TOMCAT_HOME:="/usr/share/tomcat-${TOMCAT_SLOT}"}
	: ${TOMCAT_BASE:="/opt/${TOMCAT_INSTANCE}"}
	: ${TOMCAT_CONF:="/etc/${TOMCAT_INSTANCE}"}
	: ${TOMCAT_LOGS:="/var/log/${TOMCAT_INSTANCE}"}
	: ${TOMCAT_TEMP:="/var/tmp/${TOMCAT_INSTANCE}"}
	: ${TOMCAT_WEBAPPS:="${TOMCAT_BASE}/webapps"}
	: ${TOMCAT_USER:="tomcat"}
	: ${TOMCAT_GROUP:="${TOMCAT_USER}"}
	: ${TOMCAT_EXPAND_WAR:="yes"}
	: ${TOMCAT_COPY_DEFAULT_CONFS:="yes"}

	TOMCAT_CONFDEST="${TOMCAT_CONF}"
	TOMCAT_CONFOPTS="-m644 -g ${TOMCAT_GROUP}"
}

tomcat_filter_config_() {
	debug-print-function ${FUNCNAME} $*
	[[ $# -ne 2 ]] && die "Two arguments needed"

	if [[ -f ${1} ]]; then
		local origo_file="${1}"
	elif [[ -f ${FILESDIR}/${1} ]]; then
		local origo_file="${FILESDIR}/${1}"
	else
		die "${1} does not exist or not a file!"
	fi

	local new_file="${2}"

	# don't copy when origo and new are the same files
	if [[ ! ${origo_file} -ef ${new_file} ]]; then
		cp ${origo_file} ${new_file} \
			|| die "failed to copy ${origo_file} to ${new_file}"
	fi

	sed -i \
		-e "/^#*catalina_home=/ s|=.*|=\"${TOMCAT_HOME}\"|" \
		-e "/^#*catalina_base=/ s|=.*|=\"${TOMCAT_BASE}\"|" \
		-e "/^#*catalina_temp=/ s|=.*|=\"${TOMCAT_TEMP}\"|" \
		-e "/^#*tomcat_user=/ s|=.*|=\"${TOMCAT_USER}\"|" \
		-e "/^#*tomcat_group=/ s|=.*|=\"${TOMCAT_GROUP}\"|" \
		${new_file} || die "failed to filter ${new_file}"
}
