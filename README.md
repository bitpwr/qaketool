# CMake build tools for android and Qt

This tool is a guide how to build android applications using Qt and CMake on
Linux systems - _**Q**t**A**ndroidcma**KE**_. It uses the toolchain file
directly from the Android NDK.

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

```sh
sdk/tools/bin/sdkmanager --license
```

## A quick cross compilation

To simply cross complie for android, it is enough to point out the toolchain
file and define the Android Api level. For Qt applications we must also
set `CMAKE_PREFIX_PATH` to indicate to CMake where to find the pre-built
Qt libraries. Since the toolchain file appends the sysroot to all find paths,
we must also set `CMAKE_FIND_ROOT_PATH_MODE_PACKAGE` to find Qt modules.

```sh
cmake -DCMAKE_TOOLCHAIN_FILE=<path>/android-ndk-r16b/build/cmake/android.toolchain.cmake -DCMAKE_PREFIX_PATH=<path>/qt/5.9/android_armv7/lib/cmake -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON -DANDROID_NATIVE_API_LEVEL=android-19 ..
```

This will setup a build for armeabi-v7a using clang, but these can be changed by
providing `-DANDROID_ABI=` and `-DANDROID_TOOLCHAIN=`

Then start the build

```sh
cmake --build .
```

## Creating an apk package

For this part, we rely on the `androiddeplyqt` tool provided by Qt.
The usage of this tool is bundled in the `create_apk.cmake` file.

### Environment

Set these environment variables, preferably using an activation script.

```sh
export JAVA_HOME=<path to jdk>
export ANDROID_SDK=<path to sdk>
export ANDROID_NDK=<path to ndk>
export QAKE_DIR=<path to qaketool>
```

### CMake setup

The toolchain file sets the `ANDROID` variable. Use this for Android specific
settings, e.g that the executable must be built as a shared library for the apk.

```cmake
if (ANDROID)
    add_library(${PROJECT_NAME} SHARED ...)
else()
    add_executable(${PROJECT_NAME} ...)
endif()
```

### Configure the apk

Include the `create_apk.cmake` file and use the `create_apk` macro to define the apk build.

```cmake
if(ANDROID)
    include($ENV{QAKE_DIR}/create_apk.cmake)
    create_apk(${PROJECT_NAME}
        NAME "SuperApp"
        PACKAGE_NAME "com.domain.${PROJECT_NAME}
        BUILDTOOLS_REVISION "25.0.3"
        VERSION_CODE 1
        VERSION_NAME "1.1"
        )
endif()
```

The first argument to `create_apk` is the name of the target for the application.
A make target called `build_apk` will be generated but will be automatically built.

#### create_apk() options

__NAME__ - The name of the application, as shown on the android device. If not provided,
the name of the source target will be used.

__PACKAGE_NAME__ - The name of the application package. If not provided, `io.qt.${PROJECT_NAME}` is used.

__BUILDTOOLS_REVISION__ - The revision of build tools in the Android SDK, as found
in the <ANDROID_SDK>/build-tools directory.

__VERSION_CODE__ - Version code used by Google Play. Must be incremented when new
version is published. Set to 1 if omitted.

__VERSION_NAME__ - Displayed version of the application.

## Build

To ensure `make` from the ndk is used:

```sh
cmake --build .
```

## Installation

To install the apk on a connected Android phone, just use `adb` from the Android sdk.

```sh
<path>/sdk/platform-tools/adb install -r <buildFolder>/build/outputs/apk/<name>.apk
```
