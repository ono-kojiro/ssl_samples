#!/usr/bin/env sh

set -e
top_dir="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

logfile=""

pkgname=""
version=""

usage()
{
  cat - << EOS
usage : $0 [OPTIONS] TARGET1 [TARGET2]...
EOS
}

control()
{
  username=`git config user.name`
  email=`git config user.email`

  mkdir -p debian

  ctrlfile="debian/control"
  echo generate $ctrlfile ...

  cat - << EOS > $ctrlfile
Source: $pkgname
Section: utils
Maintainer: $username <$email>
Build-Depends: make

Package: $pkgname
Architecture: amd64
Depends: libc6
Description: $pkgname
EOS

  compatfile="debian/compat"
  echo generate $compatfile ...
  echo "10" > $compatfile

  formatfile="debian/source/format"
  echo generate $formatfile ...
  mkdir -p "debian/source"
  echo "3.0 (native)" > $formatfile

  changelog="./debian/changelog"
  echo copy $changelog ...
  cp -f ChangeLog $changelog

  rules="debian/rules"
  echo generate $rules ...
  cat - << 'EOS' > $rules
#!/usr/bin/make -f

# Aim for the top, adapt if anything should break on the buildds.
DEB_BUILD_MAINT_OPTIONS=	hardening=+all
export DEB_BUILD_MAINT_OPTIONS

GARCH:=	$(shell dpkg-architecture -qDEB_HOST_GNU_TYPE)

%:
	dh '$@'


override_dh_auto_configure:
	dh_auto_configure

override_dh_auto_test:
	make -j1 check

#execute_after_dh_auto_test:
#	make -j1 check

override_dh_makeshlibs:
	dh_makeshlibs -- -c4
EOS

}

ctrl()
{
  control
}

dsc()
{
  tarfile="${pkgname}_${version}.tar.gz"
  dscfile="${pkgname}_${version}.dsc"

  sha256sum=`sha256sum $tarfile | awk '{ print $1 }'`
  md5sum=`md5sum $tarfile | awk '{ print $1 }'`
  size=`ls -l $tarfile | awk '{ print $5 }'`

  username=`git config user.name`
  email=`git config user.email`

  cat - << EOS > $dscfile
Format: 3.0 (native)
Source: $pkgname
Binary: $pkgname
Architecture: any
Version: $version
Maintainer: $username <$email>
Uploaders: $username <$email>
Homepage: http://example.com/
Standards-Version: 4.6.0
Testsuite: autopkgtest
Package-List:
 $pkgname
EOS

  {
    echo "Checksums-Sha256:"
    echo " $sha256sum $size $tarfile"
    echo "Files:"
    echo " $md5sum $size $tarfile"
  } >> $dscfile
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

cmd="$1"
shift

case $cmd in
  -* )
    echo "invalid command, $cmd"
    exit 2
    ;;
  * )
    ;;
esac

echo cmd is $cmd

set +e
LANG=C type "$cmd" | grep 'function'
if [ "$?" -ne 0 ]; then
  echo "no such function in $0, $cmd"
  exit 1
fi

set -e

while [ "$#" -ne 0 ]; do
  case "$1" in
    -h | --help )
      ;;
    -l | --log )
      shift
      logfile=$1
      ;;
    -v | --version )
      shift
      version=$1
      ;;
    -p | --package )
      shift
      pkgname=$1
      ;;
    * )
      ;;
  esac

  shift
done

ret=0

if [ -z "$pkgname" ]; then
  echo "ERROR : no package option"
  ret=$(expr $ret + 1)
fi

if [ -z "$version" ]; then
  echo "ERROR : no version option"
  ret=$(expr $ret + 1)
fi

if [ "$ret" -ne 0 ]; then
  exit $ret
fi


$cmd

