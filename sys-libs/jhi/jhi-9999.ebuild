# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 cmake-utils

DESCRIPTION="Intel Dynamic Application Loader Host Interface"
HOMEPAGE="https://github.com/intel/dynamic-application-loader-host-interface"
EGIT_REPO_URI="https://github.com/intel/dynamic-application-loader-host-interface.git"

LICENSE="|| ( GPL-3 LGPL-3 )"
SLOT="0"
IUSE="systemd"
KEYWORDS="~amd64"

DEPEND="
	sys-apps/util-linux
	dev-libs/libxml2
	systemd? ( sys-apps/systemd )
"
BDEPEND="
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}/${P}-remove-app_repo_dir.patch"
)

src_configure() {
	CMAKE_BUILD_TYPE="Release"
	mycmakeargs=()
	if ! use systemd; then
		mycmakeargs+="-DINIT_SYSTEM=SysVinit"
	fi

	cmake-utils_src_configure
}
