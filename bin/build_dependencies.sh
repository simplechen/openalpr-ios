#!/bin/bash -x
# build.sh

# This is a modification of this script:
#
# http://stackoverflow.com/questions/12849517/c-linking-problems-seems-like-i-cant-link-against-standard-c-stuff
#
# It has been updated with the following:
# - amd64 build support
# - pointers to new locations of XCode toolchains 
# - additional header files for Tesseract 3.03-rc1

# This script was tested with iOS 8.0 base target, on Mavericks.


# http://stackoverflow.com/questions/6429494/undefined-symbols-for-architecture-armv7/10170293#10170293
# http://tinsuke.wordpress.com/2011/11/01/how-to-compile-and-use-tesseract-3-01-on-ios-sdk-5/
# http://stackoverflow.com/questions/16323316/tesseract-ocr-3-02-with-libc
# http://stackoverflow.com/questions/17733162/compiler-errors-after-upgrading-to-opencv-2-4-5-on-ios-is-there-a-quick-fix-to
# http://stackoverflow.com/questions/14855844/errors-in-tesseract-integration-in-ios-app
# http://stackoverflow.com/questions/16352833/linking-with-clang-on-os-x-generates-lots-of-symbol-not-found-errors
# http://stackoverflow.com/questions/13933513/build-error-using-featured2d-in-opencv-with-xcode

trap "echo 'error with last command. exiting.' && exit 1" ERR
trap "echo 'user interrupted.' && exit 1" INT

WORK_DIR=`pwd`/work

GLOBAL_OUTDIR="$WORK_DIR/dependencies"
LOCAL_OUTDIR="$WORK_DIR/outdir"

LEPTON_LIB="leptonica-1.71"
LEPTON_LIB_DIR="$WORK_DIR/$LEPTON_LIB"
LEPTON_LIB_URL="http://www.leptonica.org/source/${LEPTON_LIB}.tar.gz"
TESSERACT_LIB="tesseract-3.03"
TESSERACT_LIB_DIR="$WORK_DIR/$TESSERACT_LIB"
TESSERACT_LIB_URL='https://drive.google.com/uc?id=0B7l10Bj_LprhSGN2bTYwemVRREU&export=download'

IOS_BASE_SDK="8.0"
IOS_DEPLOY_TGT="8.0"

BUILD_PLATFORMS="i386 armv7 armv7s arm64"

XCODE_DEVELOPER="/Applications/Xcode.app/Contents/Developer"
XCODETOOLCHAIN=$XCODE_DEVELOPER/Toolchains/XcodeDefault.xctoolchain
SDK_IPHONEOS=$(xcrun --sdk iphoneos --show-sdk-path)
SDK_IPHONESIMULATOR=$(xcrun --sdk iphonesimulator --show-sdk-path)

TESSERACT_HEADERS=( 
  api/apitypes.h api/baseapi.h 
  ccmain/pageiterator.h ccmain/mutableiterator.h ccmain/ltrresultiterator.h ccmain/resultiterator.h 
  ccmain/thresholder.h ccstruct/publictypes.h 
  ccutil/errcode.h ccutil/genericvector.h ccutil/helpers.h 
  ccutil/host.h ccutil/ndminx.h ccutil/ocrclass.h 
  ccutil/platform.h ccutil/tesscallback.h ccutil/unichar.h 
)


#-----------------------------------------------------------------------------
setenv_all() {
  
	# Add internal libs
	export CFLAGS="$CFLAGS -I$GLOBAL_OUTDIR/include -L$GLOBAL_OUTDIR/lib"
	
  export CXX=`xcrun -find c++`
  export CC=`xcrun -find cc`
  export PATH="$XCODETOOLCHAIN/usr/bin:$PATH"

  export LD=`xcrun -find ld`
  export AR=`xcrun -find ar`
  export AS=`xcrun -find as`
  export NM=`xcrun -find nm`
  export RANLIB=`xcrun -find ranlib`

	#export CXX="$DEVROOT/usr/bin/llvm-g++"
	#export CC="$DEVROOT/usr/bin/llvm-gcc"
#	export CXX="/usr/bin/g++ -stdlib=libc++" #-std=c++11"
#	export CC="/usr/bin/gcc"
#
#	export LD=$DEVROOT/usr/bin/ld
#	export AR=$DEVROOT/usr/bin/ar
#	export AS=$DEVROOT/usr/bin/as
#	export NM=$DEVROOT/usr/bin/nm
#	export RANLIB=$DEVROOT/usr/bin/ranlib
	export LDFLAGS="-L$SDKROOT/usr/lib/"
	
	export CPPFLAGS=$CFLAGS
	export CXXFLAGS=$CFLAGS
}

#-----------------------------------------------------------------------------
function set_env_for_platform() {
  local platform=$1

  local XCODE_DEV_DIR="/Applications/Xcode.app/Contents/Developer/"

	unset BUILD_HOST_NAME DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS

  if [ "$platform" == "i386" ]; then 
    #export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
    #export SDKROOT=$DEVROOT/SDKs/iPhoneSimulator$IOS_BASE_SDK.sdk
    #export DEVROOT=$XCODE_DEV_DIR/Toolchains/XcodeDefault.xctoolchain
    #export SDKROOT=$XCODE_DEV_DIR/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$IOS_BASE_SDK.sdk
    export SDKROOT=$SDK_IPHONESIMULATOR
    export CFLAGS="-arch i386 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT"
  elif [ "$platform" == "armv7" ]; then 
    #export DEVROOT=$XCODE_DEV_DIR/Platforms/iPhoneOS.platform/Developer
    export SDKROOT=$SDK_IPHONEOS
    export CFLAGS="-arch armv7 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
    export BUILD_HOST_NAME="arm-apple-darwin7"
  elif [ "$platform" == "armv7s" ]; then 
    #export DEVROOT=$XCODE_DEV_DIR/Platforms/iPhoneOS.platform/Developer
    export SDKROOT=$SDK_IPHONEOS
    export CFLAGS="-arch armv7s -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
    export BUILD_HOST_NAME="arm-apple-darwin7s"
  elif [ "$platform" == "arm64" ]; then 
    #export DEVROOT=$XCODE_DEV_DIR/Platforms/iPhoneOS.platform/Developer
    export SDKROOT=$SDK_IPHONEOS
    export CFLAGS="-arch arm64 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
    export BUILD_HOST_NAME="arm-apple-darwin64"
  else 
    echo "Unknown platform: $platform"
    exit 1
  fi

  if [ ! -f "$SDKROOT" ] &&  [ ! -h "$SDKROOT" ]; then
    echo "SDKROOT does not exist: $SDKROOT"
    exit 1
  fi

  setenv_all
}

#-----------------------------------------------------------------------------
# xcrun -sdk iphoneos lipo -info $(FILENAME)
#-----------------------------------------------------------------------------
create_outdir_lipo() {

	for lib_i386 in `find $LOCAL_OUTDIR/i386 -name "lib*.a"`; do

		#lib_arm7=`echo $lib_i386 | sed "s/i386/arm7/g"`
		#lib_arm7s=`echo $lib_i386 | sed "s/i386/arm7s/g"`
		#lib_arm64=`echo $lib_i386 | sed "s/i386/arm64/g"`
		local lib=`echo $lib_i386 | sed "s/i386//g"`

    #local lipoArgs="-arch i386 $lib_i386"
    local lipoArgs=""

    for platform in $BUILD_PLATFORMS; do 
      if [ "$platform" == "i386" ]; then
        continue
      fi
      local libName=`echo $lib_i386 | sed "s/i386/$platform/g"`
      if [ -f "$libName" ]; then
        lipoArgs="$lipoArgs -arch $platform $libName"
      else
        echo "********* WARNING: lib doesn't exist! $PWD/$libName"
      fi
    done

    local lipoArgs="$lipoArgs -arch i386 $lib_i386"

    echo "LIPOing libs  with args: $lipoArgs"
		lipoResult=`xcrun -sdk iphoneos lipo $lipoArgs -create -output $lib 2>&1`
    if [ `echo $lipoResult | grep -c 'fatal error'` == 1 ]; then 
      echo "Got fatal error during LIPO: ${lipoResult}"
      exit 1
    fi
		#xcrun -sdk iphoneos lipo -arch armv7s $lib_arm7s -arch armv7 $lib_arm7 -arch i386 $lib_i386 -arch arm64 $lib_arm64 -create -output $lib
	done
}

#-----------------------------------------------------------------------------
merge_libfiles() {
	local DIR=$1
	local LIBNAME=$2

  local tmpDir="${DIR}.tmp"
  mkdir $tmpDir
	
	cd $tmpDir
	#find . -name "../../$DIR/lib*.a" -print -exec $AR -x {} \;
	for file in `find ../../$DIR -name "lib*.a"`; do
    $AR -x $file `$AR -t $file  | grep ".o$"`
    $AR -r ../../$DIR/$LIBNAME *.o
  done

	#for i in `find . -name "lib*.a"`; do
#		$AR -x $i
#	done
	#$AR -r ../$DIR/$LIBNAME *.o
	#rm -rf *.o __*
  cd -

  rm -f $tmpDir/*
  rmdir $tmpDir
}


#-----------------------------------------------------------------------------
function cleanup_output() {
  rm -rf $LOCAL_OUTDIR
  mkdir -p $LOCAL_OUTDIR/armv7 $LOCAL_OUTDIR/i386 $LOCAL_OUTDIR/armv7s $LOCAL_OUTDIR/arm64
}

#-----------------------------------------------------------------------------
function cleanup_source() {
  make clean 2> /dev/null || echo "Nothing to clean"
  make distclean 2> /dev/null || echo "Nothing to clean"
}

#-----------------------------------------------------------------------------
function do_standard_build() {
  local platform=$1
  shift
  local buildArgs=$@

  local buildHostArg=""
  if [ "$BUILD_HOST_NAME" != "" ]; then 
    buildHostArg="--host=$BUILD_HOST_NAME"
  fi
  ./configure $buildHostArg $buildArgs && make -j12
}

#-----------------------------------------------------------------------------
function install_leptonica() {
  cleanup_output

  for platform in $BUILD_PLATFORMS; do
    cd $LEPTON_LIB_DIR
    cleanup_source
    set_env_for_platform $platform
    do_standard_build $platform --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib --without-libtiff
    [ $? != 0 ] && echo "Build failed." && exit 1
    cp -rvf src/.libs/lib*.a $LOCAL_OUTDIR/$platform
  done

  create_outdir_lipo
  mkdir -p $GLOBAL_OUTDIR/include/leptonica && cp -rvf src/*.h $GLOBAL_OUTDIR/include/leptonica
  mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $LOCAL_OUTDIR/lib*.a $GLOBAL_OUTDIR/lib
}


#######################
# TESSERACT-OCR (v3)
# ./configure --host=arm-apple-darwin7 --enable-shared=no LIBLEPT_HEADERSDIR=$GLOBAL_OUTDIR/include/
# for i in `find . -name "lib*.a" | grep -v arm`; do cp -rvf $i $LOCAL_OUTDIR/arm7; done
# ./configure --host=arm-apple-darwin7s --enable-shared=no LIBLEPT_HEADERSDIR=$GLOBAL_OUTDIR/include/
# for i in `find . -name "lib*.a" | grep -v arm`; do cp -rvf $i $LOCAL_OUTDIR/arm7s; done
# ./configure --enable-shared=no LIBLEPT_HEADERSDIR=$GLOBAL_OUTDIR/include/
# for i in `find . -name "lib*.a" | grep -v arm`; do cp -rvf $i $LOCAL_OUTDIR/i386; done
#######################
#-----------------------------------------------------------------------------
function install_tesseract() {
  cleanup_output

  for platform in $BUILD_PLATFORMS; do

    cd $TESSERACT_LIB_DIR
    cleanup_source
    set_env_for_platform $platform
    bash autogen.sh
    do_standard_build $platform --enable-shared=no LIBLEPT_HEADERSDIR=$GLOBAL_OUTDIR/include/
    [ $? != 0 ] && echo "Build failed." && exit 1

    for i in `find . -name "lib*.a" | grep -v arm`; do cp -rvf $i $LOCAL_OUTDIR/$platform; done
    merge_libfiles $LOCAL_OUTDIR/$platform libtesseract_all.a
  done

  cd $TESSERACT_LIB_DIR

  create_outdir_lipo
  mkdir -p $GLOBAL_OUTDIR/include/tesseract
#  tess_inc=( api/apitypes.h api/baseapi.h 
#  ccmain/pageiterator.h ccmain/mutableiterator.h ccmain/ltrresultiterator.h ccmain/resultiterator.h 
#  ccmain/thresholder.h ccstruct/publictypes.h ccutil/errcode.h
#  ccutil/genericvector.h ccutil/helpers.h ccutil/host.h ccutil/ndminx.h ccutil/ocrclass.h
#  ccutil/platform.h ccutil/tesscallback.h ccutil/unichar.h )
  for i in "${TESSERACT_HEADERS[@]}"; do
    cp -rvf $i $GLOBAL_OUTDIR/include/tesseract
  done
  mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $LOCAL_OUTDIR/lib*.a $GLOBAL_OUTDIR/lib

  cleanup_source
}


#-----------------------------------------------------------------------------

if [ ! -d "$WORK_DIR" ]; then
  mkdir $WORK_DIR 
fi

cd $WORK_DIR

if [ ! -f "$LEPTON_LIB.tar.gz" ]; then
  echo "Downloading leptonica library."
  curl -o $WORK_DIR/$LEPTON_LIB.tar.gz $LEPTON_LIB_URL
fi
if [ ! -d "$LEPTON_LIB_DIR" ]; then
  tar -xvf $WORK_DIR/$LEPTON_LIB.tar.gz
fi

if [ ! -f "$TESSERACT_LIB.tar.gz" ]; then
  echo "Downloading tesseract library."
  curl -L -o $TESSERACT_LIB.tar.gz $TESSERACT_LIB_URL
fi
if [ ! -d "$TESSERACT_LIB_DIR" ]; then
  tar -xvf $TESSERACT_LIB.tar.gz
fi

for srcdir in $LEPTON_LIB_DIR $TESSERACT_LIB_DIR; do 
  if [ ! -d "$srcdir" ]; then 
    echo "Missing source directory: $srcdir"
    exit 1
  fi 
done

install_leptonica 
[ $? != 0 ] && echo "Leptonica installation failed." && exit 1

install_tesseract 
[ $? != 0 ] && echo "Tesseract installation failed." && exit 1

cleanup_output

echo "Finished!"