# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="The SDK for Intel Software Guard Extensions (SGX)"
HOMEPAGE="https://01.org/intel-softwareguard-extensions"
LICENSE="BSD"
SLOT="0"

DEPEND="
	dev-lang/ocaml
	dev-lang/python
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
"
BDEPEND="
	dev-ml/ocamlbuild
	sys-devel/automake
	sys-devel/autoconf
	sys-devel/libtool
"

IUSE="
	opt_libs
	libressl
"
KEYWORDS="~amd64"

DCAP_VER="1.2"
SRC_URI="
	https://github.com/intel/linux-sgx/archive/sgx_${PV}.tar.gz
	https://github.com/intel/SGXDataCenterAttestationPrimitives/archive/DCAP_${DCAP_VER}.tar.gz
	opt_libs? ( https://download.01.org/intel-sgx/linux-${PV}/optimized_libs_${PV}.tar.gz )
"
S="${WORKDIR}/linux-sgx-sgx_${PV}"

src_unpack() {
	unpack "sgx_${PV}.tar.gz"
	unpack "DCAP_${DCAP_VER}.tar.gz"
	rm -rf "${S}/external/dcap_source"
	mv "SGXDataCenterAttestationPrimitives-DCAP_${DCAP_VER}" "${S}/external/dcap_source"
	if use opt_libs; then
		cd "${S}";
		unpack "optimized_libs_${PV}.tar.gz"
	fi
}

src_prepare() {
	eapply_user
	find -type f -name "Makefile" -or -name "CMakeLists.txt" -exec sed -i 's/-Werror/-Wno-error/g' "{}" +;
}

# really messed up
INSTALLER_DIR="${S}/linux/installer/bin/"

src_compile() {
	cd sdk
	if use opt_libs; then
		emake USE_OPT_LIBS=1
	else
		emake USE_OPT_LIBS=0
	fi
	"${INSTALLER_DIR}build-installpkg.sh" sdk
}

src_install() {
	export SDK_INSTALLER=`find "${INSTALLER_DIR}" -name "sgx_linux_*sdk_${PV}*.bin"`
	printf "no\n${D}/opt/intel\n" | "${SDK_INSTALLER}"
	find "${D}/opt/intel/sgxsdk/pkgconfig" -type f -name "*.pc" -exec sed -i "s|${D}||g" "{}" +;
	rm "${D}/opt/intel/sgxsdk/environment" "${D}/opt/intel/sgxsdk/uninstall.sh" || true
	doenvd "${FILESDIR}/99${PN}"
}
