# $FreeBSD$

PORTNAME=	v8
PORTVERSION=	6.8.275.32
CATEGORIES=	lang

MASTER_SITES=	http://mikael.urankar.free.fr/FreeBSD/v8-6.8/:build \
		http://mikael.urankar.free.fr/FreeBSD/v8-6.8/:buildtools \
		http://mikael.urankar.free.fr/FreeBSD/v8-6.8/:clang \
		http://mikael.urankar.free.fr/FreeBSD/v8-6.8/:common \
		http://mikael.urankar.free.fr/FreeBSD/v8-6.8/:gmock \
		http://mikael.urankar.free.fr/FreeBSD/v8-6.8/:gtest \
		http://mikael.urankar.free.fr/FreeBSD/v8-6.8/:icu
# XXX sha256 changes everytime you download the archive
#MASTER_SITES=	https://chromium.googlesource.com/chromium/src/build.git/+archive/:build \
#		https://chromium.googlesource.com/chromium/deps/icu.git/+archive/:icu \
#		https://chromium.googlesource.com/chromium/buildtools.git/+archive/:buildtools \
#		https://chromium.googlesource.com/chromium/src/base/trace_event/common.git/+archive/:common \
#		https://chromium.googlesource.com/external/swarming.client.git/+archive/:swarming_client \
#		https://chromium.googlesource.com/external/github.com/google/googletest.git/+archive/:gtest \
#		https://chromium.googlesource.com/external/googlemock.git/+archive/:gmock \
#		https://chromium.googlesource.com/chromium/src/tools/clang.git/+archive/:clang
DISTFILES=	build-${BUILD_REV}.tar.gz:build \
		buildtools-${BUILDTOOLS_REV}.tar.gz:buildtools \
		clang-${CLANG_REV}.tar.gz:clang \
		common-${COMMON_REV}.tar.gz:common \
		gmock-${GMOCK_REV}.tar.gz:gmock \
		gtest-${GTEST_REV}.tar.gz:gtest \
		icu-${ICU_REV}.tar.gz:icu
EXTRACT_ONLY=	${DISTNAME}.tar.gz

MAINTAINER=	sunpoet@FreeBSD.org
COMMENT=	Open source JavaScript engine by Google

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

# clang10+ is required, hardcoded in files/patch-build_toolchain_gcc__toolchain.gni
BUILD_DEPENDS=	binutils>0:devel/binutils \
		gn:devel/chromium-gn \
		${PYTHON_PKGNAMEPREFIX}Jinja2>0:devel/py-Jinja2@${PY_FLAVOR} \
		llvm10>0:devel/llvm10
LIB_DEPENDS=	libicuuc.so:devel/icu

ONLY_FOR_ARCHS=	aarch64 amd64 i386

USES=		pkgconfig ninja python:2.7,build
USE_GITHUB=	yes
USE_LDCONFIG=	yes
USE_GNOME=	glib20

BUILDTYPE=	Release
BINARY_ALIAS=	python=${PYTHON_CMD}

BUILD_REV=	b5df2518f091eea3d358f30757dec3e33db56156
BUILDTOOLS_REV=	94288c26d2ffe3aec9848c147839afee597acefd
CLANG_REV=	c893c7eec4706f8c7fc244ee254b1dadd8f8d158
COMMON_REV=	211b3ed9d0481b4caddbee1322321b86a483ca1f
GMOCK_REV=	0421b6f358139f02e102c9c332ce19a33faf75be
GTEST_REV=	6f8a66431cb592dad629028a50b3dd418a408c87
ICU_REV=	f61e46dbee9d539a32551493e3bcc1dea92f83ec

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
		${WRKSRC}/third_party/googletest/src/googlemock \
		${WRKSRC}/third_party/googletest/src/googletest \
		${WRKSRC}/third_party/icu \
		${WRKSRC}/tools/clang
	${TAR} -xf ${DISTDIR}/build-${BUILD_REV}.tar.gz  -C ${WRKSRC}/build
	${TAR} -xf ${DISTDIR}/buildtools-${BUILDTOOLS_REV}.tar.gz  -C ${WRKSRC}/buildtools
	${TAR} -xf ${DISTDIR}/clang-${CLANG_REV}.tar.gz  -C ${WRKSRC}/tools/clang
	${TAR} -xf ${DISTDIR}/common-${COMMON_REV}.tar.gz  -C ${WRKSRC}/base/trace_event/common
	${TAR} -xf ${DISTDIR}/gmock-${GMOCK_REV}.tar.gz  -C ${WRKSRC}/third_party/googletest/src/googlemock
	${TAR} -xf ${DISTDIR}/gtest-${GTEST_REV}.tar.gz  -C ${WRKSRC}/third_party/googletest/src/googletest
	${TAR} -xf ${DISTDIR}/icu-${ICU_REV}.tar.gz -C ${WRKSRC}/third_party/icu

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
	${RM} ${STAGEDIR}${PREFIX}/libdata/pkgconfig/v8.pc.bak
	${RM} ${STAGEDIR}${PREFIX}/libdata/pkgconfig/v8_libbase.pc.bak
	${RM} ${STAGEDIR}${PREFIX}/libdata/pkgconfig/v8_libplatform.pc.bak

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
