# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/jdbc-oracle-bin/jdbc-oracle-bin-10.2.0.4.ebuild,v 1.2 2011/12/28 16:36:46 sera Exp $

inherit java-pkg-2

IUSE="debug dms doc examples nls"

file_main_orig="ojdbc7.jar"
file_main_dms_orig="ojdbc7dms.jar"
file_main_debug_orig="ojdbc7_g.jar"
file_main_dms_debug_orig="ojdbc7dms_g.jar"
file_doc_orig="javadoc.zip"
file_demo_orig="demo.tar"
file_nls_orig="orai18n.jar"

file_main="${P}-${file_main_orig}"
file_main_dms="${P}-${file_main_dms_orig}"
file_main_debug="${P}-${file_main_debug_orig}"
file_main_dms_debug="${P}-${file_main_dms_debug_orig}"
file_doc="${P}-${file_doc_orig}"
file_demo="${P}-${file_demo_orig}"
file_nls="${P}-${file_nls_orig}"

DESCRIPTION="Oracle JDBC 4.0 Drivers for use with JDK 7"
HOMEPAGE="http://www.oracle.com/technology/software/tech/java/sqlj_jdbc/index.html"
DOWNLOAD_PAGE="http://www.oracle.com/technetwork/database/features/jdbc/jdbc-drivers-12c-download-1958347.html"
SRC_URI="
	!dms? (
		!debug? ( ${file_main} )
		debug? ( ${file_main_debug} )
	)
	dms? (
		!debug? ( ${file_main_dms} )
		debug? ( ${file_main_dms_debug} )
	)
	doc? ( ${file_doc} )
	examples? ( ${file_demo} )
	nls? ( ${file_nls} )"
KEYWORDS="~amd64 ~x86"
LICENSE="oracle-jdbc"
SLOT="12.1"
DEPEND="doc? ( app-arch/unzip )"
RDEPEND=">=virtual/jre-1.7"
RESTRICT="fetch"

S="${WORKDIR}"

determine_files() {
	if use dms; then
		if use debug; then
			file_main_used=${file_main_dms_debug}
			file_main_used_orig=${file_main_dms_debug_orig}
		else
			file_main_used=${file_main_dms}
			file_main_used_orig=${file_main_dms_orig}
		fi
	else
		if use debug; then
			file_main_used=${file_main_debug}
			file_main_used_orig=${file_main_debug_orig}
		else
			file_main_used=${file_main}
			file_main_used_orig=${file_main_orig}
		fi
	fi
}

pkg_nofetch() {
	determine_files
	einfo
	einfo " Because of license terms and file name conventions, please:"
	einfo
	einfo " 1. Visit ${DOWNLOAD_PAGE}"
	einfo "    (you may need to create an account on Oracle's site)"
	einfo " 2. Download the appropriate files:"
	einfo "    - ${file_main_used_orig}"
	use doc && einfo "    - ${file_doc_orig}"
	use examples && einfo "    - ${file_demo_orig}"
	use nls && einfo "    - ${file_nls_orig}"
	einfo " 3. Rename the files:"
	einfo "    - ${file_main_used_orig} --> ${file_main_used}"
	use doc && einfo "    - ${file_doc_orig} --> ${file_doc}"
	use examples && einfo "    - ${file_demo_orig} --> ${file_demo}"
	use nls && einfo "    - ${file_nls_orig} --> ${file_nls}"
	einfo " 4. Place the files in ${DISTDIR}"
	einfo " 5. Resume the installation."
	einfo
}

src_unpack() {
	determine_files
	cp "${DISTDIR}/${file_main_used}" ${PN}.jar || die

	if use nls; then
		cp "${DISTDIR}/${file_nls}" ${file_nls_orig} || die
	fi

	if use doc; then
		mkdir "${S}/javadoc" && cd "${S}/javadoc"
		unpack ${file_doc}
	fi

	if use examples; then
		cd "${S}"
		unpack ${file_demo}
		mv Samples-Readme.txt samples/ || die
	fi
}

src_install() {
	java-pkg_dojar *.jar

	use doc && java-pkg_dojavadoc javadoc
	use examples && java-pkg_doexamples samples
}
