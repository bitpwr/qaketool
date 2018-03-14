# CMake build tools for android and Qt

This tool is a guide how to build android applications using Qt and CMake on
Linux systems. It is inspired of [LaurentGomila/qt-android-cmake](https://github.com/LaurentGomila/qt-android-cmake)
but uses the toolchain file directly from the Android NDK.

The guide is tested to work with NDK version 16b, which by default uses the
clang 5.0 compiler with gnu stl. From NDK v17, the llvm stl will be used
by default and this might become problematic when combined with pre-built
Qt libraries.

## Prerequisites
Before you start, you need to install some required tools.

* Install openjdk
* Download android sdk
* Download android ndk

Ensure you accept the android java sdk license.

```
sdk/tools/bin/sdkmanager --license
```

## A simple build
To simply cross complie for android, it is enough to point out the toolchain
file and define the Android Api level. For Qt applications we must also
set `CMAKE_PREFIX_PATH` to indicate to CMake where to find the pre-built
Qt libraries. Since the toolchain file appends the sysroot to all find paths.
we must also set `CMAKE_FIND_ROOT_PATH_MODE_PACKAGE` to find Qt modules.

```
cmake -DCMAKE_TOOLCHAIN_FILE=<path>/android-ndk-r16b/build/cmake/android.toolchain.cmake -DCMAKE_PREFIX_PATH=<path>/qt/5.9/android_armv7/lib/cmake -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON -DANDROID_NATIVE_API_LEVEL=android-19 ..
```

This will setup a build for armeabi-v7a using clang, but these can be changed by
providing `-DANDROID_ABI=` and `-DANDROID_TOOLCHAIN=`

Then start the build

```
cmake --build .
```

## Create an apk package
For this part, we rely on the qtdeplytool provided by Qt. The usage of this
tool is bundled in the xxx.cmake.

### Environment

Set these environment variables, preferably using an activation script.

```
export JAVA_HOME=<path to jdk>
export ANDROID_SDK=<path to sdk>
export ANDROID_NDK=<path to ndk>
```



