# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 linux-mod

DESCRIPTION="The out-of-tree driver for the Linux Intel SGX software stack"
HOMEPAGE="https://github.com/intel/linux-sgx-driver"
EGIT_REPO_URI="https://github.com/intel/linux-sgx-driver.git"

LICENSE="|| ( GPL-2 BSD )"
SLOT="0"
IUSE=""
KEYWORDS="~amd64"

MODULE_NAMES="isgx(kernel/drivers/intel/sgx)"
BUILD_TARGETS="default"
