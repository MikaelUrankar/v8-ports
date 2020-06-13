# $FreeBSD$

PORTNAME=	v8
DISTVERSION=	8.5.145
CATEGORIES=	lang
MASTER_SITES=	http://mikael.urankar.free.fr/FreeBSD/v8/:build \
		http://mikael.urankar.free.fr/FreeBSD/v8/:buildtools \
		http://mikael.urankar.free.fr/FreeBSD/v8/:clang \
		http://mikael.urankar.free.fr/FreeBSD/v8/:common \
		http://mikael.urankar.free.fr/FreeBSD/v8/:gmock \
		http://mikael.urankar.free.fr/FreeBSD/v8/:icu \
		http://mikael.urankar.free.fr/FreeBSD/v8/:perfetto \
		http://mikael.urankar.free.fr/FreeBSD/v8/:zlib
# # XXX sha256 changes everytime you download the archive
#MASTER_SITES=	https://chromium.googlesource.com/chromium/src/build.git/+archive/:build \
#		https://chromium.googlesource.com/chromium/src/buildtools.git/+archive/:buildtools \
#		https://chromium.googlesource.com/chromium/src/tools/clang.git/+archive/:clang \
#		https://chromium.googlesource.com/chromium/src/base/trace_event/common.git/+archive/:common \
#		https://chromium.googlesource.com/external/github.com/google/googletest.git/+archive/:gmock \
#		https://chromium.googlesource.com/chromium/deps/icu.git/+archive/:icu \
#		https://android.googlesource.com/platform/external/perfetto.git/+archive/:perfetto \
#		https://chromium.googlesource.com/chromium/src/third_party/zlib.git/+archive/:zlib
DISTFILES=	build-${BUILD_REV}.tar.gz:build \
		buildtools-${BUILDTOOLS_REV}.tar.gz:buildtools \
		clang-${CLANG_REV}.tar.gz:clang \
		common-${COMMON_REV}.tar.gz:common \
		gmock-${GMOCK_REV}.tar.gz:gmock \
		icu-${ICU_REV}.tar.gz:icu \
		perfetto-${PERFETTO_REV}.tar.gz:perfetto \
		zlib-${ZLIB_REV}.tar.gz:zlib
EXTRACT_ONLY=	${DISTNAME}.tar.gz

MAINTAINER=	sunpoet@FreeBSD.org
COMMENT=	Open source JavaScript engine by Google

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

# clang10+ is required, hardcoded in files/patch-build_toolchain_gcc__toolchain.gni
BUILD_DEPENDS=	binutils>0:devel/binutils \
		gn:devel/chromium-gn \
		glib>0:devel/glib20 \
		${PYTHON_PKGNAMEPREFIX}Jinja2>0:devel/py-Jinja2@${PY_FLAVOR} \
		llvm10>0:devel/llvm10

USES=		pkgconfig ninja python:2.7,build tar:xz
USE_GITHUB=	yes
USE_LDCONFIG=	yes

# see ${WRKSRC}/DEPS
BUILD_REV=	8038ef2827d0bc23ac85450a91b0a2a413944a24
BUILDTOOLS_REV=	574cbd5df82c6ae48805b2aa8d75e0ef76aa15aa
CLANG_REV=	5e1d63a7e37e51596de0d3c01e239ff8919b5d6e
COMMON_REV=	ef3586804494b7e402b6c1791d5dccdf2971afff
GMOCK_REV=	4fe018038f87675c083d0cfb6a6b57c274fb1753
ICU_REV=	46f53dfc09c520b7c520a089ca473bb0ee29c07e
PERFETTO_REV=	ff70e0d273ed10995866c803f23e11250eb3dc52
ZLIB_REV=	a68151fd9b9f5ad11b96a3765f706361ff22dbc8

BUILDTYPE=	Release

BINARY_ALIAS=	python=${PYTHON_CMD}

# Run "gn args out/RELEASE --list" for all variables.
# Some parts don't have use_system_* flag, and can be turned on/off by using
# replace_gn_files.py script, some parts just turned on/off for target host
# OS "target_os == is_bsd", like libusb, libpci.
GN_ARGS+=	clang_use_chrome_plugins=false \
		is_clang=true \
		treat_warnings_as_errors=false \
		use_aura=true \
		use_lld=true \
		extra_cxxflags="${CXXFLAGS}" \
		extra_ldflags="${LDFLAGS}"

MAKE_ARGS=	-C out/${BUILDTYPE}

post-extract:
	${MKDIR} \
		${WRKSRC}/base/trace_event/common \
		${WRKSRC}/build \
		${WRKSRC}/buildtools \
		${WRKSRC}/third_party/googletest/src \
		${WRKSRC}/third_party/icu \
		${WRKSRC}/third_party/perfetto \
		${WRKSRC}/third_party/zlib \
		${WRKSRC}/tools/clang
	${TAR} -xf ${DISTDIR}/build-${BUILD_REV}.tar.gz  -C ${WRKSRC}/build
	${TAR} -xf ${DISTDIR}/buildtools-${BUILDTOOLS_REV}.tar.gz  -C ${WRKSRC}/buildtools
	${TAR} -xf ${DISTDIR}/clang-${CLANG_REV}.tar.gz  -C ${WRKSRC}/tools/clang
	${TAR} -xf ${DISTDIR}/common-${COMMON_REV}.tar.gz  -C ${WRKSRC}/base/trace_event/common
	${TAR} -xf ${DISTDIR}/gmock-${GMOCK_REV}.tar.gz  -C ${WRKSRC}/third_party/googletest/src
	${TAR} -xf ${DISTDIR}/icu-${ICU_REV}.tar.gz -C ${WRKSRC}/third_party/icu
	${TAR} -xf ${DISTDIR}/zlib-${ZLIB_REV}.tar.gz -C ${WRKSRC}/third_party/zlib

post-patch:
	${REINPLACE_CMD} "s|%%LOCALBASE%%|${LOCALBASE}|" \
		${WRKSRC}/build/toolchain/gcc_toolchain.gni
do-configure:
	@${ECHO_CMD} 'is_clang=true' > ${WRKSRC}/build/args/release.gn
	@${ECHO_CMD} 'treat_warnings_as_errors=false' >> ${WRKSRC}/build/args/release.gn
	@${ECHO_CMD} 'use_custom_libcxx=false' >> ${WRKSRC}/build/args/release.gn
	@${ECHO_CMD} 'use_lld=true' >> ${WRKSRC}/build/args/release.gn
	@${ECHO_CMD} 'extra_cxxflags="-I${PREFIX}/include"' >> ${WRKSRC}/build/args/release.gn
	@${ECHO_CMD} 'extra_ldflags="-L${PREFIX}/lib"' >> ${WRKSRC}/build/args/release.gn
	cd ${WRKSRC} && ${SETENV} ${CONFIGURE_ENV} gn gen out/${BUILDTYPE} \
		--args='import("//build/args/release.gn") ${GN_ARGS}'

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out/${BUILDTYPE}/d8 ${STAGEDIR}${PREFIX}/bin/d8
#	${INSTALL_PROGRAM} ${WRKSRC}/out/${BUILDTYPE}/d8 ${STAGEDIR}${PREFIX}/bin/cctest
#	${INSTALL_PROGRAM} ${WRKSRC}/out/${BUILDTYPE}/mksnapshot ${STAGEDIR}${PREFIX}/bin/mksnapshot
#	${INSTALL_PROGRAM} ${WRKSRC}/out/${BUILDTYPE}/mkgrokdump ${STAGEDIR}${PREFIX}/bin/mkgrokdump
	${INSTALL_LIB} ${WRKSRC}/out/${BUILDTYPE}/libv8.so ${STAGEDIR}${PREFIX}/lib/libv8.so
	${INSTALL_LIB} ${WRKSRC}/out/${BUILDTYPE}/libv8_libbase.so ${STAGEDIR}${PREFIX}/lib/libv8_libbase.so
	${INSTALL_LIB} ${WRKSRC}/out/${BUILDTYPE}/libv8_libplatform.so ${STAGEDIR}${PREFIX}/lib/libv8_libplatform.so

	${INSTALL_DATA} ${WRKSRC}/include/*.h ${STAGEDIR}${PREFIX}/include/
	${MKDIR} ${STAGEDIR}${PREFIX}/include/libplatform/
	${INSTALL_DATA} ${WRKSRC}/include/libplatform/*.h ${STAGEDIR}${PREFIX}/include/libplatform/
	${INSTALL_DATA} ${FILESDIR}/*.pc ${STAGEDIR}${PREFIX}/libdata/pkgconfig
	${REINPLACE_CMD} "s|%%PREFIX%%|${PREFIX}|" \
		${STAGEDIR}${PREFIX}/libdata/pkgconfig/*

.include <bsd.port.mk>
