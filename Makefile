# $FreeBSD: head/lang/v8/Makefile 507372 2019-07-26 20:46:53Z gerald $

PORTNAME=	v8
DISTVERSION=	8.3.110.13
CATEGORIES=	lang
MASTER_SITES=	LOCAL/mikael/v8/:build \
		LOCAL/mikael/v8/:buildtools \
		LOCAL/mikael/v8/:clang \
		LOCAL/mikael/v8/:common \
		LOCAL/mikael/v8/:googletest \
		LOCAL/mikael/v8/:icu \
		LOCAL/mikael/v8/:zlib
DISTFILES=	build-${BUILD_REV}.tar.gz:build \
		buildtools-${BUILDTOOLS_REV}.tar.gz:buildtools \
		clang-${CLANG_REV}.tar.gz:clang \
		common-${COMMON_REV}.tar.gz:common \
		googletest-${GOOGLETEST_REV}.tar.gz:googletest \
		icu-${ICU_REV}.tar.gz:icu \
		zlib-${ZLIB_REV}.tar.gz:zlib
EXTRACT_ONLY=	${DISTNAME}.tar.gz

MAINTAINER=	sunpoet@FreeBSD.org
COMMENT=	Open source JavaScript engine by Google

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	binutils>0:devel/binutils \
		gn:devel/chromium-gn \
		glib>0:devel/glib20 \
		${PYTHON_PKGNAMEPREFIX}Jinja2>0:devel/py-Jinja2@${PY_FLAVOR} \

.include <bsd.port.options.mk>

# clang10+ is required, this conditionnal can be dropped when
# 11.3 and 12.1 are EOL
.if (${OSVERSION} >= 1100000 && ${OSVERSION} < 1103511) || \
    (${OSVERSION} >= 1200000 && ${OSVERSION} < 1201515)
BUILD_DEPENDS+=	llvm10>0:devel/llvm10
.endif

USES=		pkgconfig ninja python:2.7,build tar:xz
USE_GITHUB=	yes
USE_LDCONFIG=	yes

# new release every minutes
PORTSCOUT=	ignore

# see ${WRKSRC}/DEPS
BUILD_REV=	26e9d485d01d6e0eb9dadd21df767a63494c8fea
BUILDTOOLS_REV=		7977eb176752aeec29d888cfe8e677ac12ed1c41
CLANG_REV=	105a8460911176861a422738eee4daad8dfe88a2
COMMON_REV=	dab187b372fc17e51f5b9fad8201813d0aed5129
GOOGLETEST_REV=	10b1902d893ea8cc43c69541d70868f91af3646b
ICU_REV=	d7aff76cf6bb0fbef3afa6c07718f78a80a70f8f
ZLIB_REV=	156be8c52f80cde343088b4a69a80579101b6e67

BUILDTYPE=	Release

BINARY_ALIAS=	python=${PYTHON_CMD}

# Run "gn args out/Release --list" for all variables.
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

#
# sha256 changes everytime you download the archive, need to host them on
# freefall
# To download distfiles : as sunpoet: make MAINTAINER_MODE=yes fetch
#
.if defined(MAINTAINER_MODE)
do-fetch:
	${FETCH_CMD} -o ${DISTDIR}/build-${BUILD_REV}.tar.gz \
		https://chromium.googlesource.com/chromium/src/build.git/+archive/${BUILD_REV}.tar.gz
	${FETCH_CMD} -o ${DISTDIR}/buildtools-${BUILDTOOLS_REV}.tar.gz \
		https://chromium.googlesource.com/chromium/src/buildtools.git/+archive/${BUILDTOOLS_REV}.tar.gz
	${FETCH_CMD} -o ${DISTDIR}/clang-${CLANG_REV}.tar.gz \
		https://chromium.googlesource.com/chromium/src/tools/clang.git/+archive/${CLANG_REV}.tar.gz
	${FETCH_CMD} -o ${DISTDIR}/common-${COMMON_REV}.tar.gz \
		https://chromium.googlesource.com/chromium/src/base/trace_event/common.git/+archive/${COMMON_REV}.tar.gz
	${FETCH_CMD} -o ${DISTDIR}/googletest-${GOOGLETEST_REV}.tar.gz \
		https://chromium.googlesource.com/external/github.com/google/googletest.git/+archive/${GOOGLETEST_REV}.tar.gz
	${FETCH_CMD} -o ${DISTDIR}/icu-${ICU_REV}.tar.gz \
		https://chromium.googlesource.com/chromium/deps/icu.git/+archive/${ICU_REV}.tar.gz
	${FETCH_CMD} -o ${DISTDIR}/zlib-${ZLIB_REV}.tar.gz \
		https://chromium.googlesource.com/chromium/src/third_party/zlib.git/+archive/${ZLIB_REV}.tar.gz
. if ${USER} == ${MAINTAINER:C/@.*//}
.  for f in build-${BUILD_REV}.tar.gz buildtools-${BUILDTOOLS_REV}.tar.gz \
		clang-${CLANG_REV}.tar.gz common-${COMMON_REV}.tar.gz \
		googletest-${GOOGLETEST_REV}.tar.gz icu-${ICU_REV}.tar.gz \
		zlib-${ZLIB_REV}.tar.gz
	scp ${DISTDIR}/${f} \
	    mikael@freefall.freebsd.org:public_distfiles/v8
.  endfor
. endif
.endif # defined(MAINTAINER_MODE)

post-extract:
	${MKDIR} \
		${WRKSRC}/base/trace_event/common \
		${WRKSRC}/build \
		${WRKSRC}/buildtools \
		${WRKSRC}/third_party/googletest/src \
		${WRKSRC}/third_party/icu \
		${WRKSRC}/third_party/zlib \
		${WRKSRC}/tools/clang
	${TAR} -xf ${DISTDIR}/build-${BUILD_REV}.tar.gz  -C ${WRKSRC}/build
	${TAR} -xf ${DISTDIR}/buildtools-${BUILDTOOLS_REV}.tar.gz  -C ${WRKSRC}/buildtools
	${TAR} -xf ${DISTDIR}/clang-${CLANG_REV}.tar.gz  -C ${WRKSRC}/tools/clang
	${TAR} -xf ${DISTDIR}/common-${COMMON_REV}.tar.gz  -C ${WRKSRC}/base/trace_event/common
	${TAR} -xf ${DISTDIR}/googletest-${GOOGLETEST_REV}.tar.gz  -C ${WRKSRC}/third_party/googletest/src
	${TAR} -xf ${DISTDIR}/icu-${ICU_REV}.tar.gz -C ${WRKSRC}/third_party/icu
	${TAR} -xf ${DISTDIR}/zlib-${ZLIB_REV}.tar.gz -C ${WRKSRC}/third_party/zlib

post-patch:
	${REINPLACE_CMD} "s|%%LOCALBASE%%|${LOCALBASE}|" \
		${WRKSRC}/build/toolchain/gcc_toolchain.gni
# clang10+ is required, this conditionnal can be dropped when
# 11.3 and 12.1 are EOL
.if (${OSVERSION} >= 1100000 && ${OSVERSION} < 1103511) || \
    (${OSVERSION} >= 1200000 && ${OSVERSION} < 1201515)
	@${PATCH} -d ${PATCH_WRKSRC} ${PATCH_ARGS} < ${FILESDIR}/extrapatch-clang10
.endif

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
	${MKDIR} ${STAGEDIR}${PREFIX}/include/libplatform \
	         ${STAGEDIR}${PREFIX}/include/cppgc
	${INSTALL_DATA} ${WRKSRC}/include/libplatform/*.h ${STAGEDIR}${PREFIX}/include/libplatform/
	cd ${WRKSRC}/include/cppgc && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/include/cppgc " -name *\.h"
	${INSTALL_DATA} ${FILESDIR}/*.pc ${STAGEDIR}${PREFIX}/libdata/pkgconfig
	${REINPLACE_CMD} "s|%%PREFIX%%|${PREFIX}|" \
		${STAGEDIR}${PREFIX}/libdata/pkgconfig/*

.include <bsd.port.mk>
