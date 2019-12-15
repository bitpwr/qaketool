cmake_minimum_required(VERSION 3.5)

set(JAVA_HOME $ENV{JAVA_HOME})
if(NOT JAVA_HOME)
    message(FATAL_ERROR "The JAVA_HOME environment variable is not set.")
endif()

set(ANDROID_SDK_ROOT $ENV{ANDROID_SDK})
if(NOT ANDROID_SDK_ROOT)
    message(FATAL_ERROR "The ANDROID_SDK environment variable is not set.")
endif()

set(ANDROID_NDK_ROOT $ENV{ANDROID_NDK})
if(NOT ANDROID_NDK_ROOT)
    message(FATAL_ERROR "The ANDROID_NDK environment variable is not set.")
endif()

set(QAKE_DIR ${CMAKE_CURRENT_LIST_DIR})

if(NOT Qt5Core_DIR)
    find_package(Qt5Core REQUIRED)
endif()
get_filename_component(QT_PATH "${Qt5Core_DIR}/../../.." ABSOLUTE)

message(STATUS "Using Java: ${JAVA_HOME}")
message(STATUS "Using Android SDK: ${ANDROID_SDK_ROOT}")
message(STATUS "Using Android NDK: ${ANDROID_NDK_ROOT}")
message(STATUS "Using Qt: ${QT_PATH}")
message(STATUS "Using qaketool: ${QAKE_DIR}")

# create_apk() uses androiddeployqt to create an android apk with Qt
#
#   The first argument is the name of the target for the application to package.
#   A make target called `apk` will be generated but automatically built.
#
# options:
#   NAME - name of the application, as shown on the android device
#   PACKAGE_NAME - name of the application package
#   VERSION_CODE - version code used by Google Play when upgrading
#   VERSION_NAME - displayed version of the application
#   QML_PATH - path to qml files to parse for dependencies to include in apk
#   DEPENDENCIES - list of shared libraries to include in apk
#   MANIFEST - path to AndroidManifest.xml file to use, CMake substitution applies
#
macro(create_apk SOURCE_TARGET)

    # parse the macro arguments
    set(PARSE_VALUES NAME PACKAGE_NAME VERSION_CODE VERSION_NAME QML_PATH MANIFEST)
    cmake_parse_arguments(ARG "" "${PARSE_VALUES}" "DEPENDENCIES" ${ARGN})

    # application name
    if(ARG_NAME)
        set(QAKE_APP_NAME ${ARG_NAME})
    else()
        set(QAKE_APP_NAME ${SOURCE_TARGET})
    endif()

    # package name
    if(ARG_PACKAGE_NAME)
        set(QAKE_PACKAGE_NAME ${ARG_PACKAGE_NAME})
    else()
        set(QAKE_PACKAGE_NAME io.qt.${SOURCE_TARGET})
    endif()

    # version code
    if(ARG_VERSION_CODE)
        set(QAKE_VERSION_CODE ${ARG_VERSION_CODE})
    else()
        set(QAKE_VERSION_CODE 1)
    endif()

    # version name
    set(QAKE_VERSION_NAME ${ARG_VERSION_NAME})

    # path to qml files
    set(QAKE_QML_PATH ${ARG_QML_PATH})

    # detect sdk build tools revision
    set(SDK_BUILDTOOLS_REVISION "0.0.0")
    file(GLOB ALL_VERSIONS RELATIVE ${ANDROID_SDK_ROOT}/build-tools ${ANDROID_SDK_ROOT}/build-tools/*)
    foreach(BUILD_TOOLS_VERSION ${ALL_VERSIONS})
        if (${BUILD_TOOLS_VERSION} VERSION_GREATER ${SDK_BUILDTOOLS_REVISION})
            set(SDK_BUILDTOOLS_REVISION ${BUILD_TOOLS_VERSION})
        endif()
    endforeach()

    # set c++ stl version
    if(ANDROID_STL STREQUAL c++_shared)
        set(QAKE_STL_PATH "${ANDROID_NDK_ROOT}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_shared.so")
    else()
        set(QAKE_STL_PATH "${ANDROID_NDK_ROOT}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_static.so")
    endif()

    # show some info
    message(STATUS "Using Android SDK build tools version: ${SDK_BUILDTOOLS_REVISION}")
    message(STATUS "Using Android target SDK version: android-${ANDROID_NATIVE_API_LEVEL}")
    message(STATUS "ANDROID_TOOLCHAIN_NAME=${ANDROID_TOOLCHAIN_NAME} (${ANDROID_TOOLCHAIN})")
    message(STATUS "ANDROID_ABI=${ANDROID_ABI}")
    message(STATUS "ANDROID_STL=${ANDROID_STL}")
    message(STATUS "C++ STL library: ${QAKE_STL_PATH}")

    # library dependencies
    if(ARG_DEPENDENCIES)
        foreach(LIB ${ARG_DEPENDENCIES})
            if(DEPENDS)
                string(APPEND DEPENDS ",${LIB}")
            else()
                set(DEPENDS "${LIB}")
            endif()
        endforeach()
        set(QAKE_DEPENDENCIES ",\"android-extra-libs\": \"${DEPENDS}\"")
    endif()

    if(ARG_MANIFEST)
        set(QAKE_MANIFEST ${ARG_MANIFEST})
    else()
        set(QAKE_MANIFEST ${QAKE_DIR}/AndroidManifest.xml.in)
    endif()

    set(QAKE_PACKAGE_DIR "${CMAKE_CURRENT_BINARY_DIR}/package")
    set(TARGET_PATH $<TARGET_FILE:${SOURCE_TARGET}>)
    set(DEPLOY_INPUT ${CMAKE_CURRENT_BINARY_DIR}/deployinput.json)

    # generate the manifest
    configure_file(${QAKE_MANIFEST}
                   ${QAKE_PACKAGE_DIR}/AndroidManifest.xml)

    # generate androiddeployqt input
    configure_file(${QAKE_DIR}/deployinput.json.in
                   ${CMAKE_CURRENT_BINARY_DIR}/deployinput.tmp)

    # must substitute generator expression for target path
    file(GENERATE OUTPUT ${DEPLOY_INPUT}
         INPUT ${CMAKE_CURRENT_BINARY_DIR}/deployinput.tmp)

    message(STATUS "Generate APK for \"${QAKE_APP_NAME}\", version ${QAKE_VERSION_NAME}")
    if (DEPENDS)
        message(STATUS "Adding external dependencies: ${DEPENDS}")
    endif()

    if (DEFINED CMAKE_BUILD_TYPE AND CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(QAKE_QT_BUILD_TYPE --debug)
    else()
        set(QAKE_QT_BUILD_TYPE --release)
    endif()

    add_custom_target(apk DEPENDS ${SOURCE_TARGET}
        COMMAND ${CMAKE_COMMAND} -E remove_directory
                ${CMAKE_CURRENT_BINARY_DIR}/libs/${ANDROID_ABI}
        COMMAND ${CMAKE_COMMAND} -E make_directory
                ${CMAKE_CURRENT_BINARY_DIR}/libs/${ANDROID_ABI}
        COMMAND ${CMAKE_COMMAND} -E copy ${TARGET_PATH}
                ${CMAKE_CURRENT_BINARY_DIR}/libs/${ANDROID_ABI}
        COMMAND ${QT_PATH}/bin/androiddeployqt --verbose
                --output ${CMAKE_CURRENT_BINARY_DIR}
                --input ${DEPLOY_INPUT}
                --android-platform android-${ANDROID_NATIVE_API_LEVEL}
                ${QAKE_QT_BUILD_TYPE}
                --gradle
#                --qml-import-paths 
    )

endmacro()