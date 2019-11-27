# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="The SDK for Intel Software Guard Extensions (SGX)"
HOMEPAGE="https://01.org/intel-softwareguard-extensions"
LICENSE="BSD"
SLOT="0"

RDEPEND="
	psw? (
		sys-libs/jhi
		acct-user/aesmd
		acct-group/aesmd )
	systemd? ( sys-apps/systemd )
"
DEPEND="
	dev-lang/ocaml
	dev-lang/python
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	${RDEPEND}
"
BDEPEND="
	dev-ml/ocamlbuild
	sys-devel/automake
	sys-devel/autoconf
	sys-devel/libtool
"

IUSE="
	opt_libs
	psw
	libressl
	systemd
"
KEYWORDS="~amd64"

DCAP_VER="1.2"
SRC_URI="
	https://github.com/intel/linux-sgx/archive/sgx_${PV}.tar.gz
	https://github.com/intel/SGXDataCenterAttestationPrimitives/archive/DCAP_${DCAP_VER}.tar.gz
	opt_libs? ( https://download.01.org/intel-sgx/linux-${PV}/optimized_libs_${PV}.tar.gz )
	psw? ( https://download.01.org/intel-sgx/linux-${PV}/prebuilt_ae_${PV}.tar.gz )
"
S="${WORKDIR}/linux-sgx-sgx_${PV}"

src_unpack() {
	unpack "sgx_${PV}.tar.gz"
	unpack "DCAP_${DCAP_VER}.tar.gz"
	rm -rf "${S}/external/dcap_source"
	mv "SGXDataCenterAttestationPrimitives-DCAP_${DCAP_VER}" "${S}/external/dcap_source"
	cd "${S}";
	if use opt_libs; then
		unpack "optimized_libs_${PV}.tar.gz"
	fi
	if use psw; then
		unpack "prebuilt_ae_${PV}.tar.gz"
	fi
}

src_prepare() {
	eapply "${FILESDIR}/${PN}-2.6-fix-gcc9.patch"
	eapply_user
	find "${S}" -type f \( -name "Makefile*" -or -name "CMakeLists.txt" -or -name "*.cmake" \) -exec sed -i 's/-Werror/-Wno-error/g' {} \;
	if use psw; then
		sed -i "s|/opt/intel/sgxpsw|${D}/opt/intel/sgxpsw|g" "${S}/linux/installer/bin/install-sgx-psw.bin.tmpl"
	fi
}

src_compile() {
	cd sdk
	if use opt_libs; then
		emake USE_OPT_LIBS=1
	else
		emake USE_OPT_LIBS=0
	fi

	if use psw; then
		cd "${S}/psw"
		emake
	fi
}

generate_pkgconfig_files() {
    local TEMPLATE_FOLDER=${SCRIPT_DIR}/pkgconfig/template
    local TARGET_FOLDER=${SCRIPT_DIR}/pkgconfig/${ARCH}
    local VERSION="$1"

    # Create pkgconfig folder for this architecture
    rm -fr ${TARGET_FOLDER}
    mkdir -p ${TARGET_FOLDER}

    # Copy the template files into the folder
    for pkgconfig_file in $(ls -1 ${TEMPLATE_FOLDER}); do
        sed -e "s:@LIB_FOLDER_NAME@:$LIB_DIR:" \
            -e "s:@SGX_VERSION@:$VERSION:" \
            ${TEMPLATE_FOLDER}/$pkgconfig_file > ${TARGET_FOLDER}/$pkgconfig_file
    done
}

src_install() {
	# adapted from linux/installer/common/{sdk,psw}/createTarball.sh
	SCRIPT_DIR="${S}/linux/installer/common/sdk"
	ARCH="x64"
	source "${SCRIPT_DIR}/installConfig.${ARCH}"

	SGX_VERSION=$(awk '/STRFILEVER/ {print $3}' ${S}/common/inc/internal/se_version.h|sed 's/^\"\(.*\)\"$/\1/')
	generate_pkgconfig_files ${SGX_VERSION}

	cp "${S}/linux/installer/common/gen_source/gen_source.py" ${SCRIPT_DIR}
	GEN_SOURCE="python ${SCRIPT_DIR}/gen_source.py"
	${GEN_SOURCE} --bom=BOMs/sdk_base.txt
	${GEN_SOURCE} --bom=BOMs/sdk_${ARCH}.txt --cleanup=false
	${GEN_SOURCE} --bom=../licenses/BOM_license.txt --cleanup=false

	mkdir -p "${D}/opt/intel/sgxsdk"
	cp -rf "${SCRIPT_DIR}/output/package/"* "${D}/opt/intel/sgxsdk"

	rm "${D}/opt/intel/sgxsdk/environment" "${D}/opt/intel/sgxsdk/uninstall.sh" || true
	doenvd "${FILESDIR}/99${PN}"

	if use psw; then
		SCRIPT_DIR="${S}/linux/installer/common/psw"
		cp "${S}/linux/installer/common/gen_source/gen_source.py" ${SCRIPT_DIR}
		GEN_SOURCE="python ${SCRIPT_DIR}/gen_source.py"
		${GEN_SOURCE} --bom=BOMs/psw_base.txt
		${GEN_SOURCE} --bom=BOMs/psw_${ARCH}.txt --cleanup=false
		${GEN_SOURCE} --bom=../licenses/BOM_license.txt --cleanup=false

		mkdir -p "${D}/opt/intel/sgxpsw"
		cp -rf "${SCRIPT_DIR}/output/package/"* "${D}/opt/intel/sgxpsw"

		mkdir -p /var/opt/aesmd
		mv -f "${D}/opt/intel/sgxpsw/aesm/data" "${D}/var/opt/aesmd/"
		mv -f "${D}/opt/intel/sgxpsw/aesm/conf/aesmd.conf" "${D}/etc/aesmd.conf"
		rm -rf "${D}/opt/intel/sgxpsw/conf"
		chmod 0644 "${D}/etc/aesmd.conf"
		chown -R aesmd:aesmd "${D}/var/opt/aesmd"
		chmod 0750 "${D}/var/opt/aesmd"

		if use systemd; then
			sed -e "s:@aesm_folder@:/opt/intel/sgxpsw/aesm:" "${D}/opt/intel/sgxpsw/aesm/aesmd.service" > "${D}/lib/systemd/system/aesmd.service"
			chmod 0644 "${D}/lib/systemd/system/aesmd.service"
		else
			doinitd "${FILESDIR}/aesmd"
		fi
		rm "${D}/opt/intel/sgxpsw/aesm/aesmd.service"
	fi
}
