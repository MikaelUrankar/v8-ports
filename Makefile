# $FreeBSD: head/lang/v8/Makefile 507372 2019-07-26 20:46:53Z gerald $

# https://chromereleases.googleblog.com/search/label/Desktop%20Update
# search for "The stable channel has been updated to" XX.X.XXXX.XXX
#  -> https://github.com/chromium/chromium/blob/85.0.4183.102/DEPS
#     -> 'v8_revision': '4dc61d3cd02f0a2462cc655095db1e99ad9047d2'
# https://github.com/v8/v8/commit/4dc61d3cd02f0a2462cc655095db1e99ad9047d2
#  -> Version  8.4.371.23

# see https://aur.archlinux.org/v8.git

PORTNAME=	v8
DISTVERSION=	8.7.142
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
		gn:devel/gn \
		${PYTHON_PKGNAMEPREFIX}Jinja2>0:devel/py-Jinja2@${PY_FLAVOR} \
		libunwind>0:devel/libunwind
LIB_DEPENDS=	libicudata.so:devel/icu

.include <bsd.port.options.mk>

# clang10+ is required, this conditional can be dropped when
# 11.3 and 12.1 are EOL
.if (${OSVERSION} >= 1100000 && ${OSVERSION} < 1103511) || \
    (${OSVERSION} >= 1200000 && ${OSVERSION} < 1201515)
BUILD_DEPENDS+=	llvm10>0:devel/llvm10
.endif

USES=		pkgconfig ninja python:3.5+,build tar:xz
USE_GITHUB=	yes
USE_LDCONFIG=	yes
USE_GNOME=	glib20

# new release every minutes
PORTSCOUT=	ignore

# egrep "build.git|buildtools.git|clang.git|common.git|googletest.git|icu.git|zlib.git" ${WRKSRC}/DEPS
BUILD_REV=	153ad0bf09eda458f1ef4f74dcac5c12d530d770
BUILDTOOLS_REV=		3ff4f5027b4b81a6c9c36d64d71444f2709a4896
CLANG_REV=	92b362238013c401926b8a45b0b8f0a42d506120
COMMON_REV=	23ef5333a357fc7314630ef88b44c3a545881dee
GOOGLETEST_REV=	4fe018038f87675c083d0cfb6a6b57c274fb1753
ICU_REV=	79326efe26e5440f530963704c3c0ff965b3a4ac
ZLIB_REV=	f8517bd62931d7adb9bcefb0cbe3c2ca5cd8862c

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
		use_custom_libcxx=false \
		v8_use_external_startup_data=false \
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

. if ${USER} == ${MAINTAINER:C/@.*//}
.  for f in build-${BUILD_REV} buildtools-${BUILDTOOLS_REV} \
		clang-${CLANG_REV} common-${COMMON_REV} \
		googletest-${GOOGLETEST_REV} icu-${ICU_REV} \
		zlib-${ZLIB_REV}
	scp ${DISTDIR}/${f}.tar.gz \
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
		${WRKSRC}/buildtools/third_party/libc++/BUILD.gn
# clang10+ is required, this conditionnal can be dropped when
# 11.3 and 12.1 are EOL
.if (${OSVERSION} >= 1100000 && ${OSVERSION} < 1103511) || \
    (${OSVERSION} >= 1200000 && ${OSVERSION} < 1201515)
	@${PATCH} -d ${PATCH_WRKSRC} ${PATCH_ARGS} < ${FILESDIR}/extrapatch-clang10
.endif

# google sucks, this file is needed but absent in the build* archive
# https://github.com/klzgrad/naiveproxy/blob/master/src/build/config/gclient_args.gni
	${TOUCH} ${WRKSRC}/build/config/gclient_args.gni
	${ECHO} "checkout_google_benchmark = false" >> ${WRKSRC}/build/config/gclient_args.gni

pre-configure:
	# use system libraries for ICU
	cd ${WRKSRC} && ${SETENV} ${CONFIGURE_ENV} ${PYTHON_CMD} \
		./build/linux/unbundle/replace_gn_files.py --system-libraries \
		icu || ${FALSE}
	# google build system is too stupid to create needed directory and
	# use system headers for ICU
	${MKDIR} ${WRKSRC}/out/${BUILDTYPE}/gen/shim_headers/icuuc_shim/third_party/icu/source/common/unicode \
		 ${WRKSRC}/out/${BUILDTYPE}/gen/shim_headers/icui18n_shim/third_party/icu/source/i18n/unicode \
		 ${WRKSRC}/out/${BUILDTYPE}/gen/include
	${CP} -R ${LOCALBASE}/include/unicode ${WRKSRC}/out/${BUILDTYPE}/gen/include

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
	${INSTALL_LIB} ${WRKSRC}/out/${BUILDTYPE}/libchrome_zlib.so ${STAGEDIR}${PREFIX}/lib/libchrome_zlib.so

	${INSTALL_DATA} ${WRKSRC}/include/*.h ${STAGEDIR}${PREFIX}/include/
	${MKDIR} ${STAGEDIR}${PREFIX}/include/libplatform \
	         ${STAGEDIR}${PREFIX}/include/cppgc
	${INSTALL_DATA} ${WRKSRC}/include/libplatform/*.h ${STAGEDIR}${PREFIX}/include/libplatform/
	cd ${WRKSRC}/include/cppgc && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/include/cppgc " -name *\.h"
	${INSTALL_DATA} ${FILESDIR}/*.pc ${STAGEDIR}${PREFIX}/libdata/pkgconfig
	${REINPLACE_CMD} "s|%%PREFIX%%|${PREFIX}|" \
		${STAGEDIR}${PREFIX}/libdata/pkgconfig/*

.include <bsd.port.mk>
