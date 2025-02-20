odnl> Do not add anything above
AC_INIT([edge], m4_esyscmd([scripts/version.sh | tr -d '\n']))
dnl> Do not add anything above

N2N_VERSION=${PACKAGE_VERSION}

if test "${CC+set}" != set; then
    CC=gcc
fi
if test "${AR+set}" != set; then
    AR=ar
fi

N2N_LIBS=

AC_PROG_CC

AC_ARG_WITH(edgex,    [  --with-edgex            Build for Ubiquity-X])

if test "${with_edgex+set}" = set; then
   CC=mipsel-linux-gnu-gcc
   AR=mipsel-linux-gnu-arzls   
fi
   
AC_ARG_WITH([zstd],
 [AS_HELP_STRING([--with-zstd],
 [enable support for zstd])],
 [],
 [with_zstd=no])
if test "x$with_zstd" != xno; then
  AC_CHECK_LIB([zstd], [ZSTD_compress])
  if test "x$ac_cv_lib_zstd_ZSTD_compress" != xyes; then
    AC_MSG_RESULT(Building n2n without ZSTD support)
  else
    AC_DEFINE([N2N_HAVE_ZSTD], [], [Have ZSTD support])
    N2N_LIBS="-lzstd ${N2N_LIBS}"
  fi
fi

AC_ARG_WITH([openssl],
 [AS_HELP_STRING([--with-openssl],
 [enable support for OpenSSL])],
 [],
 [with_openssl=no])
if test "x$with_openssl" != xno; then
  OLD_CFLAGS="${CFLAGS}"
  OLD_LDFLAGS="${LDFLAGS}"
  CFLAGS="${CFLAGS} -I/usr/local/opt/openssl@1.1/include"
  LDFLAGS="${LDFLAGS} -L/usr/local/opt/openssl@1.1/lib/"
  AC_CHECK_LIB([crypto], [EVP_CIPHER_CTX_reset])
  if test "x$ac_cv_lib_crypto_EVP_CIPHER_CTX_reset" != xyes; then
     AC_MSG_RESULT(OpenSSL 1.1 not present)
     CFLAGS="${OLD_CFLAGS}"
     LDFLAGS="${OLD_LDFLAGS}"
  else
    AC_DEFINE([HAVE_OPENSSL_1_1], [], [OpenSSL 1.1 is present])
    N2N_LIBS="-lcrypto ${N2N_LIBS}"
  fi
fi

AC_CHECK_LIB([miniupnpc], [upnpDiscover], miniupnp=true)

if test x$miniupnp != x; then
  AC_DEFINE([HAVE_MINIUPNP], [], [Have miniupnp library])
  N2N_LIBS="-lminiupnpc ${N2N_LIBS}"
fi

AC_CHECK_LIB([natpmp], [initnatpmp], natpmp=true)

if test x$natpmp != x; then
  AC_DEFINE([HAVE_NATPMP], [], [Have natpmp library])
  N2N_LIBS="-lnatpmp ${N2N_LIBS}"
fi

AC_CHECK_LIB([pcap], [pcap_open_live], pcap=true)

if test x$pcap != x; then
  AC_DEFINE([N2N_HAVE_PCAP], [], [Have PCAP library])
  ADDITIONAL_TOOLS="$ADDITIONAL_TOOLS n2n-decode"
fi

AC_CHECK_LIB([pcap], [pcap_set_immediate_mode], pcap_immediate_mode=true)

if test x$pcap_immediate_mode != x; then
  AC_DEFINE([HAVE_PCAP_IMMEDIATE_MODE], [], [Have pcap_immediate_mode])
fi

AC_CHECK_LIB([cap], [cap_get_proc], cap=true)
if test x$cap != x; then
  N2N_LIBS="${N2N_LIBS} -lcap"
  AC_DEFINE([HAVE_LIBCAP],[1],[Support for linux capabilities])
fi

AC_CHECK_LIB([pthread], [pthread_mutex_trylock], pthread=true)
if test x$pthread != x; then
  LDFLAGS="${LDFLAGS} -pthread"
  AC_DEFINE([HAVE_PTHREAD],[],[pthread is present])
fi


MACHINE=`uname -m`
SYSTEM=`uname -s`

if test $SYSTEM = "Linux"; then
   if test -f /etc/debian_version; then
      DEBIAN_VERSION=`cat /etc/debian_version`
      OSNAME="Debian $DEBIAN_VERSION"
   else
      OSNAME=`./config.guess`
   fi
else
dnl> wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
   OSNAME=`./config.guess`
fi
AC_DEFINE_UNQUOTED(PACKAGE_OSNAME, "${OSNAME}", [OS name])

if test $MACHINE = "x86_64"; then
   EXTN="amd64"
else
   if test $MACHINE = "i686"; then
     EXTN="i386"
   fi
fi

DATE=`date +"%Y-%m-%d"`

AC_SUBST(CC)
AC_SUBST(AR)
AC_SUBST(CFLAGS)
AC_SUBST(LDFLAGS)
AC_SUBST(N2N_VERSION)
AC_SUBST(N2N_DEFINES)
AC_SUBST(N2N_LIBS)
AC_SUBST(ADDITIONAL_TOOLS)
AC_CONFIG_HEADERS(include/config.h)
AC_CONFIG_FILES(Makefile)
AC_CONFIG_FILES(tools/Makefile)

AC_OUTPUT
