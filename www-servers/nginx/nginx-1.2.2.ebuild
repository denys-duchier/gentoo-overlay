# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-servers/nginx/nginx-1.2.2.ebuild,v 1.3 2012/07/30 08:18:38 hollow Exp $

EAPI="4"

# Maintainer notes:
# - http_rewrite-independent pcre-support makes sense for matching locations without an actual rewrite
# - any http-module activates the main http-functionality and overrides USE=-http
# - keep the following requirements in mind before adding external modules:
#   * alive upstream
#   * sane packaging
#   * builds cleanly
#   * does not need a patch for nginx core
# - TODO: test the google-perftools module (included in vanilla tarball)
#
# Modified by jirutka:
# - added Passanger module
# - removed Passenger dependency on dev-ruby/fastthread
#     it was hack for MRI 1.8.6, for REE and MRI 1.9* useless and breaks build
# - added sticky module


# prevent perl-module from adding automagic perl DEPENDs
GENTOO_DEPEND_ON_PERL="no"

# ruby config for passenger module
USE_RUBY="ree18 ruby19"
RUBY_OPTIONAL="yes"

# devel_kit (https://github.com/simpl/ngx_devel_kit, BSD license)
DEVEL_KIT_MODULE_PV="0.2.17"
DEVEL_KIT_MODULE_P="ngx_devel_kit-${DEVEL_KIT_MODULE_PV}"
DEVEL_KIT_MODULE_SHA1="bc97eea"
DEVEL_KIT_MODULE_URI="https://github.com/simpl/ngx_devel_kit/tarball/v${DEVEL_KIT_MODULE_PV}"
DEVEL_KIT_MODULE_WD="${WORKDIR}/simpl-ngx_devel_kit-${DEVEL_KIT_MODULE_SHA1}"

# http_uploadprogress (https://github.com/masterzen/nginx-upload-progress-module, BSD-2 license)
HTTP_UPLOAD_PROGRESS_MODULE_PV="0.9.0"
HTTP_UPLOAD_PROGRESS_MODULE_P="ngx_http_upload_progress-${HTTP_UPLOAD_PROGRESS_MODULE_PV}"
HTTP_UPLOAD_PROGRESS_MODULE_SHA1="a788dea"
HTTP_UPLOAD_PROGRESS_MODULE_URI="http://github.com/masterzen/nginx-upload-progress-module/tarball/v${HTTP_UPLOAD_PROGRESS_MODULE_PV}"
HTTP_UPLOAD_PROGRESS_MODULE_WD="${WORKDIR}/masterzen-nginx-upload-progress-module-${HTTP_UPLOAD_PROGRESS_MODULE_SHA1}"

# http_headers_more (http://github.com/agentzh/headers-more-nginx-module, BSD license)
HTTP_HEADERS_MORE_MODULE_PV="0.17"
HTTP_HEADERS_MORE_MODULE_P="ngx_http_headers_more-${HTTP_HEADERS_MORE_MODULE_PV}"
HTTP_HEADERS_MORE_MODULE_SHA1="b7c8cfc"
HTTP_HEADERS_MORE_MODULE_URI="http://github.com/agentzh/headers-more-nginx-module/tarball/v${HTTP_HEADERS_MORE_MODULE_PV}"
HTTP_HEADERS_MORE_MODULE_WD="${WORKDIR}/agentzh-headers-more-nginx-module-${HTTP_HEADERS_MORE_MODULE_SHA1}"

# HTTP Passenger module
HTTP_PASSENGER_MODULE_PV="3.0.14"
HTTP_PASSENGER_MODULE_P="passenger-${HTTP_PASSENGER_MODULE_PV}"
HTTP_PASSENGER_MODULE_URI="mirror://rubyforge/passenger/${HTTP_PASSENGER_MODULE_P}.tar.gz"
HTTP_PASSENGER_MODULE_WD="${WORKDIR}/passenger-${HTTP_PASSENGER_MODULE_PV}"

# http_push (http://pushmodule.slact.net/, MIT license)
HTTP_PUSH_MODULE_PV="0.692"
HTTP_PUSH_MODULE_P="ngx_http_push-${HTTP_PUSH_MODULE_PV}"
HTTP_PUSH_MODULE_URI="http://pushmodule.slact.net/downloads/nginx_http_push_module-${HTTP_PUSH_MODULE_PV}.tar.gz"
HTTP_PUSH_MODULE_WD="${WORKDIR}/nginx_http_push_module-${HTTP_PUSH_MODULE_PV}"

# http_cache_purge (http://labs.frickle.com/nginx_ngx_cache_purge/, BSD-2 license)
HTTP_CACHE_PURGE_MODULE_PV="1.6"
HTTP_CACHE_PURGE_MODULE_P="ngx_http_cache_purge-${HTTP_CACHE_PURGE_MODULE_PV}"
HTTP_CACHE_PURGE_MODULE_URI="http://labs.frickle.com/files/ngx_cache_purge-${HTTP_CACHE_PURGE_MODULE_PV}.tar.gz"
HTTP_CACHE_PURGE_MODULE_WD="${WORKDIR}/ngx_cache_purge-${HTTP_CACHE_PURGE_MODULE_PV}"

# http_upload (http://www.grid.net.ru/nginx/upload.en.html, BSD license)
HTTP_UPLOAD_MODULE_PV="2.2.0"
HTTP_UPLOAD_MODULE_P="ngx_http_upload-${HTTP_UPLOAD_MODULE_PV}"
HTTP_UPLOAD_MODULE_URI="http://www.grid.net.ru/nginx/download/nginx_upload_module-${HTTP_UPLOAD_MODULE_PV}.tar.gz"
HTTP_UPLOAD_MODULE_WD="${WORKDIR}/nginx_upload_module-${HTTP_UPLOAD_MODULE_PV}"

# http_slowfs_cache (http://labs.frickle.com/nginx_ngx_slowfs_cache/, BSD-2 license)
HTTP_SLOWFS_CACHE_MODULE_PV="1.9"
HTTP_SLOWFS_CACHE_MODULE_P="ngx_http_slowfs_cache-${HTTP_SLOWFS_CACHE_MODULE_PV}"
HTTP_SLOWFS_CACHE_MODULE_URI="http://labs.frickle.com/files/ngx_slowfs_cache-${HTTP_SLOWFS_CACHE_MODULE_PV}.tar.gz"
HTTP_SLOWFS_CACHE_MODULE_WD="${WORKDIR}/ngx_slowfs_cache-${HTTP_SLOWFS_CACHE_MODULE_PV}"

# http_fancyindex (http://wiki.nginx.org/NgxFancyIndex, BSD license)
HTTP_FANCYINDEX_MODULE_PV="0.3.1"
HTTP_FANCYINDEX_MODULE_P="ngx_http_fancyindex-${HTTP_FANCYINDEX_MODULE_PV}"
HTTP_FANCYINDEX_MODULE_URI="http://gitorious.org/ngx-fancyindex/ngx-fancyindex/archive-tarball/v${HTTP_FANCYINDEX_MODULE_PV}"
HTTP_FANCYINDEX_MODULE_WD="${WORKDIR}/ngx-fancyindex-ngx-fancyindex"

# http_lua (https://github.com/chaoslawful/lua-nginx-module, BSD license)
HTTP_LUA_MODULE_PV="0.5.10"
HTTP_LUA_MODULE_P="ngx_http_lua-${HTTP_LUA_MODULE_PV}"
HTTP_LUA_MODULE_SHA1="db0bebe"
HTTP_LUA_MODULE_URI="https://github.com/chaoslawful/lua-nginx-module/tarball/v${HTTP_LUA_MODULE_PV}"
HTTP_LUA_MODULE_WD="${WORKDIR}/chaoslawful-lua-nginx-module-${HTTP_LUA_MODULE_SHA1}"

# http_sticky (http://code.google.com/p/nginx-sticky-module/, as-is)
HTTP_STICKY_MODULE_PV="1.1"
HTTP_STICKY_MODULE_P="nginx-sticky-module-${HTTP_STICKY_MODULE_PV}"
HTTP_STICKY_MODULE_URI="http://nginx-sticky-module.googlecode.com/files/${HTTP_STICKY_MODULE_P}.tar.gz"
HTTP_STICKY_MODULE_WD="${WORKDIR}/${HTTP_STICKY_MODULE_P}"


inherit eutils ssl-cert toolchain-funcs perl-module ruby-ng flag-o-matic user

DESCRIPTION="Robust, small and high performance http and reverse proxy server"
HOMEPAGE="http://nginx.org"
SRC_URI="http://nginx.org/download/${P}.tar.gz
	${DEVEL_KIT_MODULE_URI} -> ${DEVEL_KIT_MODULE_P}.tar.gz
	nginx_modules_http_upload_progress? ( ${HTTP_UPLOAD_PROGRESS_MODULE_URI} -> ${HTTP_UPLOAD_PROGRESS_MODULE_P}.tar.gz )
	nginx_modules_http_headers_more? ( ${HTTP_HEADERS_MORE_MODULE_URI} -> ${HTTP_HEADERS_MORE_MODULE_P}.tar.gz )
	nginx_modules_http_passenger? ( ${HTTP_PASSENGER_MODULE_URI} -> ${HTTP_PASSENGER_MODULE_P}.tar.gz )
	nginx_modules_http_push? ( ${HTTP_PUSH_MODULE_URI} )
	nginx_modules_http_cache_purge? ( ${HTTP_CACHE_PURGE_MODULE_URI} )
	nginx_modules_http_upload? ( ${HTTP_UPLOAD_MODULE_URI} )
	nginx_modules_http_slowfs_cache? ( ${HTTP_SLOWFS_CACHE_MODULE_URI} )
	nginx_modules_http_fancyindex? ( ${HTTP_FANCYINDEX_MODULE_URI} -> ${HTTP_FANCYINDEX_MODULE_P}.tar.gz )
	nginx_modules_http_lua? ( ${HTTP_LUA_MODULE_URI} -> ${HTTP_LUA_MODULE_P}.tar.gz )
	nginx_modules_http_sticky? ( ${HTTP_STICKY_MODULE_URI} -> ${HTTP_STICKY_MODULE_P}.tar.gz )"

LICENSE="as-is BSD BSD-2 GPL-2 MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux"

NGINX_MODULES_STD="access auth_basic autoindex browser charset empty_gif fastcgi
geo gzip limit_req limit_conn map memcached proxy referer rewrite scgi ssi
split_clients upstream_ip_hash userid uwsgi"
NGINX_MODULES_OPT="addition dav degradation flv geoip gzip_static image_filter
mp4 perl random_index realip secure_link stub_status sub xslt"
NGINX_MODULES_MAIL="imap pop3 smtp"
NGINX_MODULES_3RD="
	http_upload_progress
	http_headers_more
	http_passenger
	http_push
	http_cache_purge
	http_upload
	http_slowfs_cache
	http_fancyindex
	http_lua
	http_sticky"

IUSE="aio debug +http +http-cache ipv6 libatomic +pcre pcre-jit selinux ssl vim-syntax"

RUBY_S="${P}"
# return S to default after ruby-ng has modified it
S="${WORKDIR}/${RUBY_S}"

for mod in $NGINX_MODULES_STD; do
	IUSE="${IUSE} +nginx_modules_http_${mod}"
done

for mod in $NGINX_MODULES_OPT; do
	IUSE="${IUSE} nginx_modules_http_${mod}"
done

for mod in $NGINX_MODULES_MAIL; do
	IUSE="${IUSE} nginx_modules_mail_${mod}"
done

for mod in $NGINX_MODULES_3RD; do
	IUSE="${IUSE} nginx_modules_${mod}"
done

ruby_add_bdepend "nginx_modules_http_passenger? (
	>=dev-ruby/rubygems-0.9.0
	>=dev-ruby/rake-0.8.1
	>=dev-ruby/rack-1.0.0
	>=dev-ruby/daemon_controller-1.0.0 )"

CDEPEND="${DEPEND}
	pcre? ( >=dev-libs/libpcre-4.2 )
	pcre-jit? ( >=dev-libs/libpcre-8.20[jit] )
	selinux? ( sec-policy/selinux-nginx )
	ssl? ( dev-libs/openssl )
	http-cache? ( userland_GNU? ( dev-libs/openssl ) )
	nginx_modules_http_geo? ( dev-libs/geoip )
	nginx_modules_http_gzip? ( sys-libs/zlib )
	nginx_modules_http_gzip_static? ( sys-libs/zlib )
	nginx_modules_http_image_filter? ( media-libs/gd[jpeg,png] )
	nginx_modules_http_perl? ( >=dev-lang/perl-5.8 )
	nginx_modules_http_rewrite? ( >=dev-libs/libpcre-4.2 )
	nginx_modules_http_secure_link? ( userland_GNU? ( dev-libs/openssl ) )
	nginx_modules_http_xslt? ( dev-libs/libxml2 dev-libs/libxslt )
	nginx_modules_http_lua? ( || ( dev-lang/lua dev-lang/luajit ) )
	nginx_modules_http_passenger? ( 
		>=dev-libs/libev-3.90 
		ruby_targets_ree18? ( $(ruby_implementation_depend ree18)[ssl] )
		ruby_targets_ruby19? ( $(ruby_implementation_depend ruby19)[ssl] ) )"

RDEPEND="${CDEPEND}"
DEPEND="${CDEPEND}
	arm? ( dev-libs/libatomic_ops )
	libatomic? ( dev-libs/libatomic_ops )"
PDEPEND="vim-syntax? ( app-vim/nginx-syntax )"
REQUIRED_USE="
	pcre-jit? ( pcre )
	nginx_modules_http_passenger? ( || ( ruby_targets_ree18 ruby_targets_ruby19 ) )"


pkg_setup() {
	ebegin "Creating nginx user and group"
	enewgroup ${PN}
	enewuser ${PN} -1 -1 -1 ${PN}
	eend $?

	if use libatomic; then
		ewarn "GCC 4.1+ features built-in atomic operations."
		ewarn "Using libatomic_ops is only needed if using"
		ewarn "a different compiler or a GCC prior to 4.1"
	fi

	if [[ -n $NGINX_ADD_MODULES ]]; then
		ewarn "You are building custom modules via \$NGINX_ADD_MODULES!"
		ewarn "This nginx installation is not supported!"
		ewarn "Make sure you can reproduce the bug without those modules"
		ewarn "_before_ reporting bugs."
	fi

	if use !http; then
		ewarn "To actually disable all http-functionality you also have to disable"
		ewarn "all nginx http modules."
	fi

	if use nginx_modules_http_passenger; then
		ruby-ng_pkg_setup
		use debug && append-flags -DPASSENGER_DEBUG
	fi
}

src_unpack() {
	# prevent ruby-ng.eclass from messing with src_unpack
	default
}

src_prepare() {
	find auto/ -type f -print0 | xargs -0 sed -i 's:\&\& make:\&\& \\$(MAKE):' || die
	# We have config protection, don't rename etc files
	sed -i 's:.default::' auto/install || die
	# remove useless files
	sed -i -e '/koi-/d' -e '/win-/d' auto/install || die

	if use nginx_modules_http_passenger; then
		cd "${HTTP_PASSENGER_MODULE_WD}"
		epatch \
			"${FILESDIR}/passenger-3.0.14-ldflags.patch" \
			"${FILESDIR}/passenger-3.0.11-cflags.patch"

		sed -i \
			-e 's|/usr/lib/phusion-passenger/agents|/usr/libexec/passenger/agents|' \
			-e 's|/usr/share/phusion-passenger/helper-scripts|/usr/libexec/passenger/bin|' \
			-e "s|/usr/share/doc/phusion-passenger|/usr/share/doc/${PF}|" \
			lib/phusion_passenger.rb ext/common/ResourceLocator.h || die "sed failed"

		sed -i -e "s/gcc/$(tc-getCC)/" -e "s/g++/$(tc-getCXX)/" build/config.rb || die

		# Don't install a tool that won't work in our setup.
		sed -i -e '/passenger-install-apache2-module/d' lib/phusion_passenger/packaging.rb || die
		rm -f bin/passenger-install-apache2-module || die "Unable to remove unneeded install script."

		# Make sure we use the system-provided version.
		rm -rf ext/libev || die "Unable to remove vendored libev."
	fi
}

src_configure() {
	local myconf= http_enabled= mail_enabled=

	use aio       && myconf+=" --with-file-aio --with-aio_module"
	use debug     && myconf+=" --with-debug"
	use ipv6      && myconf+=" --with-ipv6"
	use libatomic && myconf+=" --with-libatomic"
	use pcre      && myconf+=" --with-pcre"
	use pcre-jit  && myconf+=" --with-pcre-jit"

	# HTTP modules
	for mod in $NGINX_MODULES_STD; do
		if use nginx_modules_http_${mod}; then
			http_enabled=1
		else
			myconf+=" --without-http_${mod}_module"
		fi
	done

	for mod in $NGINX_MODULES_OPT; do
		if use nginx_modules_http_${mod}; then
			http_enabled=1
			myconf+=" --with-http_${mod}_module"
		fi
	done

	if use nginx_modules_http_fastcgi; then
		myconf+=" --with-http_realip_module"
	fi

	# third-party modules
	if use nginx_modules_http_upload_progress; then
		http_enabled=1
		myconf+=" --add-module=${HTTP_UPLOAD_PROGRESS_MODULE_WD}"
	fi

	if use nginx_modules_http_headers_more; then
		http_enabled=1
		myconf+=" --add-module=${HTTP_HEADERS_MORE_MODULE_WD}"
	fi

	if use nginx_modules_http_passenger; then
		http_enabled=1
		myconf+=" --add-module=${HTTP_PASSENGER_MODULE_WD}/ext/nginx"
	fi

	if use nginx_modules_http_push; then
		http_enabled=1
		myconf+=" --add-module=${HTTP_PUSH_MODULE_WD}"
	fi

	if use nginx_modules_http_cache_purge; then
		http_enabled=1
		myconf+=" --add-module=${HTTP_CACHE_PURGE_MODULE_WD}"
	fi

	if use nginx_modules_http_upload; then
		http_enabled=1
		myconf+=" --add-module=${HTTP_UPLOAD_MODULE_WD}"
	fi

	if use nginx_modules_http_slowfs_cache; then
		http_enabled=1
		myconf+=" --add-module=${HTTP_SLOWFS_CACHE_MODULE_WD}"
	fi

	if use nginx_modules_http_fancyindex; then
		http_enabled=1
		myconf+=" --add-module=${HTTP_FANCYINDEX_MODULE_WD}"
	fi

	if use nginx_modules_http_lua; then
		http_enabled=1
		myconf+=" --add-module=${DEVEL_KIT_MODULE_WD}"
		myconf+=" --add-module=${HTTP_LUA_MODULE_WD}"
	fi

	if use nginx_modules_http_sticky; then
		http_enabled=1
		myconf+=" --add-module=${HTTP_STICKY_MODULE_WD}"
	fi

	if use http || use http-cache; then
		http_enabled=1
	fi

	if [ $http_enabled ]; then
		use http-cache || myconf+=" --without-http-cache"
		use ssl && myconf+=" --with-http_ssl_module"
	else
		myconf+=" --without-http --without-http-cache"
	fi

	# MAIL modules
	for mod in $NGINX_MODULES_MAIL; do
		if use nginx_modules_mail_${mod}; then
			mail_enabled=1
		else
			myconf+=" --without-mail_${mod}_module"
		fi
	done

	if [ $mail_enabled ]; then
		myconf+=" --with-mail"
		use ssl && myconf+=" --with-mail_ssl_module"
	fi

	# custom modules
	for mod in $NGINX_ADD_MODULES; do
		myconf+=" --add-module=${mod}"
	done

	# https://bugs.gentoo.org/286772
	export LANG=C LC_ALL=C
	tc-export CC

	if ! use prefix; then
		myconf+=" --user=${PN} --group=${PN}"
	fi

	./configure \
		--prefix="${EPREFIX}"/usr \
		--conf-path="${EPREFIX}"/etc/${PN}/${PN}.conf \
		--error-log-path="${EPREFIX}"/var/log/${PN}/error.log \
		--pid-path="${EPREFIX}"/var/run/${PN}.pid \
		--lock-path="${EPREFIX}"/var/lock/${PN}.lock \
		--with-cc-opt="-I${EROOT}usr/include" \
		--with-ld-opt="-L${EROOT}usr/lib" \
		--http-log-path="${EPREFIX}"/var/log/${PN}/access.log \
		--http-client-body-temp-path="${EPREFIX}"/var/tmp/${PN}/client \
		--http-proxy-temp-path="${EPREFIX}"/var/tmp/${PN}/proxy \
		--http-fastcgi-temp-path="${EPREFIX}"/var/tmp/${PN}/fastcgi \
		--http-scgi-temp-path="${EPREFIX}"/var/tmp/${PN}/scgi \
		--http-uwsgi-temp-path="${EPREFIX}"/var/tmp/${PN}/uwsgi \
		${myconf} || die "configure failed"
}

src_compile() {
	# https://bugs.gentoo.org/286772
	export LANG=C LC_ALL=C
	emake LINK="${CC} ${LDFLAGS}" OTHERLDFLAGS="${LDFLAGS}"
}

src_install() {
	emake DESTDIR="${D}" install
	cp "${FILESDIR}"/nginx.conf "${ED}"/etc/nginx/nginx.conf || die
	newinitd "${FILESDIR}"/nginx.initd nginx
	doman man/nginx.8
	dodoc CHANGES* README

	insinto /etc/nginx/sites
	doins "${FILESDIR}"/default.conf

	# Keepdir because these are hardcoded above
	keepdir /var/log/${PN} /var/tmp/${PN}/{client,proxy,fastcgi,scgi,uwsgi}
	keepdir /var/www/localhost/htdocs
	mv "${ED}"/usr/html "${ED}"/var/www/localhost/htdocs || die

	# logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/nginx.logrotate nginx

	if use nginx_modules_http_perl; then
		cd "${S}"/objs/src/http/modules/perl/
		einstall DESTDIR="${D}" INSTALLDIRS=vendor
		fixlocalpod
	fi

	if use nginx_modules_http_push; then
		docinto ${HTTP_PUSH_MODULE_P}
		dodoc "${HTTP_PUSH_MODULE_WD}"/{changelog.txt,protocol.txt,README}
	fi

	if use nginx_modules_http_cache_purge; then
		docinto ${HTTP_CACHE_PURGE_MODULE_P}
		dodoc "${HTTP_CACHE_PURGE_MODULE_WD}"/{CHANGES,README.md,TODO.md}
	fi

	if use nginx_modules_http_upload; then
		docinto ${HTTP_UPLOAD_MODULE_P}
		dodoc "${HTTP_UPLOAD_MODULE_WD}"/{Changelog,README}
	fi

	if use nginx_modules_http_slowfs_cache; then
		docinto ${HTTP_SLOWFS_CACHE_MODULE_P}
		dodoc "${HTTP_SLOWFS_CACHE_MODULE_WD}"/{CHANGES,README.md}
	fi

	if use nginx_modules_http_fancyindex; then
		docinto ${HTTP_FANCYINDEX_MODULE_P}
		dodoc "${HTTP_FANCYINDEX_MODULE_WD}"/README.rst
	fi

	if use nginx_modules_http_lua; then
		docinto ${HTTP_LUA_MODULE_P}
		dodoc "${HTTP_LUA_MODULE_WD}"/{Changes,README.markdown}
	fi

	if use nginx_modules_http_sticky; then
		docinto ${HTTP_STICKY_MODULE_P}
		dodoc "${HTTP_STICKY_MODULE_WD}"/README
	fi

	if use nginx_modules_http_passenger; then
		# passengers Rakefile is so horribly broken that we have to do it
		# manually
		cd "${HTTP_PASSENGER_MODULE_WD}"

		for target in $(ruby_get_use_implementations); do
			einfo "Install ${HTTP_PASSENGER_MODULE_P} for target ${target}"
			export RUBY="${target}"

			insinto $(ruby_rbconfig_value 'archdir')
			insopts -m 0755
			doins ext/ruby/*/passenger_native_support.so
			doruby -r lib/phusion_passenger lib/phusion_passenger.rb

			exeinto /usr/bin
			doexe bin/passenger-memory-stats bin/passenger-status

			exeinto /usr/libexec/passenger/bin
			doexe helper-scripts/passenger-spawn-server

			exeinto /usr/libexec/passenger/agents
			doexe agents/Passenger{LoggingAgent,Watchdog}

			exeinto /usr/libexec/passenger/agents/nginx
			doexe agents/nginx/PassengerHelperAgent

			# set correct paths to nginx.conf
			# note: passenger doesn't support multiple targets at one so only
			# first one will be used
			local ruby_bin=$(ruby_implementation_command ${RUBY})
			local sitelibdir=$(ruby_rbconfig_value 'sitelibdir')
			sed -i \
				-e "s|@PASSENGER_ROOT@|${sitelibdir}/phusion_passenger|" \
				-e "s|@RUBY_BIN@|${ruby_bin}|" \
				"${ED}"/etc/nginx/nginx.conf || die "failed to filter nginx.conf"
		done
	else
		# remove configuration for passanger if not USEd
		sed -i \
			-e "/passenger_/d" "${ED}"/etc/nginx/nginx.conf \
			|| die "failed to filter nginx.conf"
	fi
}

pkg_postinst() {
	if use ssl; then
		if [ ! -f "${EROOT}"/etc/ssl/${PN}/${PN}.key ]; then
			install_cert /etc/ssl/${PN}/${PN}
			use prefix || chown ${PN}:${PN} "${EROOT}"/etc/ssl/${PN}/${PN}.{crt,csr,key,pem}
		fi
	fi
}
