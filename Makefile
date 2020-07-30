# $FreeBSD: head/lang/v8/Makefile 507372 2019-07-26 20:46:53Z gerald $

# https://chromereleases.googleblog.com/search/label/Desktop%20Update
# search for "The stable channel has been updated to" XX.X.XXXX.XXX
#  -> https://github.com/chromium/chromium/blob/84.0.4147.125/DEPS
#     -> 'v8_revision': '451d38b60be0a0f692b11815289cf8cbc9b1dc98'
# https://github.com/v8/v8/commit/451d38b60be0a0f692b11815289cf8cbc9b1dc98
#  -> Version  8.4.371.23

PORTNAME=	v8
DISTVERSION=	8.4.371.23
CATEGORIES=	lang
MASTER_SITES=	LOCAL/mikael/v8/:build \
		LOCAL/mikael/v8/:buildtools \
		LOCAL/mikael/v8/:clang \
		LOCAL/mikael/v8/:common \
		LOCAL/mikael/v8/:googletest \
		LOCAL/mikael/v8/:icu \
		LOCAL/mikael/v8/:zlib \
		LOCAL/mikael/v8/:libcxx \
		LOCAL/mikael/v8/:libcxxabi
DISTFILES=	build-${BUILD_REV}.tar.gz:build \
		buildtools-${BUILDTOOLS_REV}.tar.gz:buildtools \
		clang-${CLANG_REV}.tar.gz:clang \
		common-${COMMON_REV}.tar.gz:common \
		googletest-${GOOGLETEST_REV}.tar.gz:googletest \
		icu-${ICU_REV}.tar.gz:icu \
		zlib-${ZLIB_REV}.tar.gz:zlib \
		libcxx-${LIBCXX_REV}.tar.gz:libcxx \
		libcxxabi-${LIBCXXABI_REV}.tar.gz:libcxxabi
EXTRACT_ONLY=	${DISTNAME}.tar.gz

MAINTAINER=	sunpoet@FreeBSD.org
COMMENT=	Open source JavaScript engine by Google

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	binutils>0:devel/binutils \
		gn:devel/chromium-gn \
		${PYTHON_PKGNAMEPREFIX}Jinja2>0:devel/py-Jinja2@${PY_FLAVOR} \
		libunwind>0:devel/libunwind

.include <bsd.port.options.mk>

# clang10+ is required, this conditional can be dropped when
# 11.3 and 12.1 are EOL
.if (${OSVERSION} >= 1100000 && ${OSVERSION} < 1103511) || \
    (${OSVERSION} >= 1200000 && ${OSVERSION} < 1201515)
BUILD_DEPENDS+=	llvm10>0:devel/llvm10
.endif

USES=		pkgconfig ninja python:2.7,build tar:xz
USE_GITHUB=	yes
USE_LDCONFIG=	yes
USE_GNOME=	glib20

# new release every minutes
PORTSCOUT=	ignore

# egrep "build.git|buildtools.git|clang.git|common.git|googletest.git|icu.git|zlib.git|libcxx.git|libcxxabi.git" ${WRKSRC}/DEPS
BUILD_REV=	1b904cc30093c25d5fd48389bd58e3f7409bcf80
BUILDTOOLS_REV=		204a35a2a64f7179f8b76d7a0385653690839e21
CLANG_REV=	de3e20662b84f0ee361a5ae11c99a9513df7c8e8
COMMON_REV=	dab187b372fc17e51f5b9fad8201813d0aed5129
GOOGLETEST_REV=	a09ea700d32bab83325aff9ff34d0582e50e3997
ICU_REV=	f2223961702f00a8833874b0560d615a2cc42738
ZLIB_REV=	90fc47e6eed7bd1a59ad1603761303ef24705593
LIBCXX_REV=	d9040c75cfea5928c804ab7c235fed06a63f743a
LIBCXXABI_REV=	196ba1aaa8ac285d94f4ea8d9836390a45360533

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

# sha256 changes everytime you download the archive, need to host them on
# freefall
# To download distfiles : as sunpoet: make MAINTAINER_MODE=yes fetch
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
	${FETCH_CMD} -o ${DISTDIR}/libcxx-${LIBCXX_REV}.tar.gz \
		 https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxx.git/+archive/${LIBCXX_REV}.tar.gz
	${FETCH_CMD} -o ${DISTDIR}/libcxxabi-${LIBCXXABI_REV}.tar.gz \
		 https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxxabi.git/+archive/${LIBCXXABI_REV}.tar.gz

. if ${USER} == ${MAINTAINER:C/@.*//}
.  for f in build-${BUILD_REV}.tar.gz buildtools-${BUILDTOOLS_REV}.tar.gz \
		clang-${CLANG_REV}.tar.gz common-${COMMON_REV}.tar.gz \
		googletest-${GOOGLETEST_REV}.tar.gz icu-${ICU_REV}.tar.gz \
		zlib-${ZLIB_REV}.tar.gz
	scp ${DISTDIR}/${f} \
	    freefall.freebsd.org:public_distfiles/v8
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
		${WRKSRC}/tools/clang \
		${WRKSRC}/buildtools/third_party/libc++/trunk \
		${WRKSRC}/buildtools/third_party/libc++abi/trunk
	${TAR} -xf ${DISTDIR}/build-${BUILD_REV}.tar.gz  -C ${WRKSRC}/build
	${TAR} -xf ${DISTDIR}/buildtools-${BUILDTOOLS_REV}.tar.gz  -C ${WRKSRC}/buildtools
	${TAR} -xf ${DISTDIR}/clang-${CLANG_REV}.tar.gz  -C ${WRKSRC}/tools/clang
	${TAR} -xf ${DISTDIR}/common-${COMMON_REV}.tar.gz  -C ${WRKSRC}/base/trace_event/common
	${TAR} -xf ${DISTDIR}/googletest-${GOOGLETEST_REV}.tar.gz  -C ${WRKSRC}/third_party/googletest/src
	${TAR} -xf ${DISTDIR}/icu-${ICU_REV}.tar.gz -C ${WRKSRC}/third_party/icu
	${TAR} -xf ${DISTDIR}/zlib-${ZLIB_REV}.tar.gz -C ${WRKSRC}/third_party/zlib
	${TAR} -xf ${DISTDIR}/libcxx-${LIBCXX_REV}.tar.gz -C ${WRKSRC}/buildtools/third_party/libc++/trunk
	${TAR} -xf ${DISTDIR}/libcxxabi-${LIBCXXABI_REV}.tar.gz -C ${WRKSRC}/buildtools/third_party/libc++abi/trunk

post-patch:
	${REINPLACE_CMD} "s|%%LOCALBASE%%|${LOCALBASE}|" \
		${WRKSRC}/build/toolchain/gcc_toolchain.gni \
		${WRKSRC}/buildtools/third_party/libc++/BUILD.gn
# clang10+ is required, this conditionnal can be dropped when
# 11.3 and 12.1 are EOL
.if (${OSVERSION} >= 1100000 && ${OSVERSION} < 1103511) || \
    (${OSVERSION} >= 1200000 && ${OSVERSION} < 1201515)
	@${PATCH} -d ${PATCH_WRKSRC} ${PATCH_ARGS} < ${FILESDIR}/extrapatch-clang10
.endif

do-configure:
	cd ${WRKSRC} && ${SETENV} ${CONFIGURE_ENV} gn gen out/${BUILDTYPE} --args='${GN_ARGS}'

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
