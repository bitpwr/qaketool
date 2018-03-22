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
message(STATUS "Using qaketool: ${CMAKE_CURRENT_LIST_DIR}")

macro(create_apk SOURCE_TARGET)

    # parse the macro arguments
    set(PARSE_VALUES NAME PACKAGE_NAME BUILDTOOLS_REVISION VERSION_CODE VERSION_NAME)
    cmake_parse_arguments(ARG "" "${PARSE_VALUES}" "" ${ARGN})
#    cmake_parse_arguments(ARG "NAME;VERSION_CODE;PACKAGE_NAME;PACKAGE_SOURCES;KEYSTORE_PASSWORD;BUILDTOOLS_REVISION" "DEPENDS;KEYSTORE" ${ARGN})

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

    ## build tools revision
    set(BUILDTOOLS_REVISION ${ARG_BUILDTOOLS_REVISION})

    set(PACKAGE_DIR "${CMAKE_CURRENT_BINARY_DIR}/package")
    set(TARGET_PATH $<TARGET_FILE:${SOURCE_TARGET}>)
    set(DEPLOY_INPUT ${CMAKE_CURRENT_BINARY_DIR}/deployinput.json)

    # generate the manifest
    configure_file(${QAKE_DIR}/AndroidManifest.xml.in
                   ${PACKAGE_DIR}/AndroidManifest.xml)

    # generate androiddeployqt input
    configure_file(${QAKE_DIR}/deployinput.json.in
                   ${CMAKE_CURRENT_BINARY_DIR}/deployinput.tmp)

    # must substitute generator expression for target path
    file(GENERATE OUTPUT ${DEPLOY_INPUT}
         INPUT ${CMAKE_CURRENT_BINARY_DIR}/deployinput.tmp)

    add_custom_target(build_apk ALL DEPENDS ${SOURCE_TARGET}
        COMMAND ${CMAKE_COMMAND} -E remove_directory
                ${CMAKE_CURRENT_BINARY_DIR}/libs/${ANDROID_ABI}
        COMMAND ${CMAKE_COMMAND} -E make_directory
                ${CMAKE_CURRENT_BINARY_DIR}/libs/${ANDROID_ABI}
        COMMAND ${CMAKE_COMMAND} -E copy ${TARGET_PATH}
                ${CMAKE_CURRENT_BINARY_DIR}/libs/${ANDROID_ABI}
        COMMAND ${QT_PATH}/bin/androiddeployqt --verbose --output ${CMAKE_CURRENT_BINARY_DIR}
                --input ${DEPLOY_INPUT} --android-platform android-${ANDROID_NATIVE_API_LEVEL}
                --gradle
    )
                               
endmacro()