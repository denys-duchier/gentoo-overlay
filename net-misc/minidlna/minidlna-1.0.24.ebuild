# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/minidlna/minidlna-1.0.24.ebuild,v 1.2 2012/05/05 03:20:42 jdhore Exp $

EAPI=4

inherit eutils toolchain-funcs

DESCRIPTION="Server software with the aim of being fully compliant with DLNA/UPnP-AV clients"
HOMEPAGE="http://minidlna.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${PN}_${PV}_src.tar.gz"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""

CACHE_DIR="/var/cache/${PN}"
LOG_DIR="/var/log/${PN}"
PID_DIR="/var/run/${PN}"

RDEPEND="dev-db/sqlite
	media-libs/flac
	media-libs/libexif
	media-libs/libid3tag
	media-libs/libogg
	media-libs/libvorbis
	virtual/ffmpeg
	virtual/jpeg"
DEPEND="${RDEPEND}
	virtual/pkgconfig"


pkg_setup() {
	enewgroup dlna 130 || die "Unable to create jboss group"
	enewuser dlna 130 -1 -1 dlna \
		|| die  "Unable to create dlna user"
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.0.18-Makefile.patch
}

src_configure() {
	./genconfig.sh || die
}

src_compile() {
	emake CC="$(tc-getCC)"
}

src_install() {
	emake DESTDIR="${D}" install

	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	newinitd "${FILESDIR}"/${PN}.initd ${PN}

	insinto "/etc"
	doins "${FILESDIR}/${PN}.conf"

	dodoc README TODO NEWS

	diropts -m700 -o dlna -g dlna
	dodir "${CACHE_DIR}"
	dodir "${PID_DIR}"

	diropts -m755 -o dlna -g dlna
	dodir "${LOG_DIR}"
}

pkg_postinst() {
	ewarn "MiniDLNA no longer runs as root:root, per bug 394373."
	ewarn "Please add to your /etc/sysctl.conf:"
	ewarn "    fs.inotify.max_user_watches = 65536"
}
