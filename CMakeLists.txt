# Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
# Copyright 2018-2020 Nitrux Latinoamericana S.C.
#
# SPDX-License-Identifier: GPL-3.0-or-later

cmake_minimum_required(VERSION 3.16)

set(NOTA_VERSION 4.0.3)
add_compile_definitions(APP_COPYRIGHT_NOTICE="© 2019-2025 Maui Development Team")

project(nota VERSION ${NOTA_VERSION})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$"
        AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_compile_options(-march=x86-64-v3)
    endif()
endif()

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(QT_MAJOR_VERSION 6)

set(REQUIRED_QT_VERSION 6.5.2)
set(REQUIRED_KF_VERSION 5.240.0)
set(REQUIRED_MAUI_VERSION 4.0.0)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(FATAL_ERROR "Nota only supports Linux.")
endif()

find_package(ECM ${REQUIRED_KF_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)

find_package(Qt6 ${REQUIRED_QT_VERSION} REQUIRED NO_MODULE COMPONENTS Core Qml Quick Widgets DBus)
find_package(KF6 ${REQUIRED_KF_VERSION} REQUIRED COMPONENTS I18n CoreAddons)

find_package(MauiKit4 ${REQUIRED_MAUI_VERSION} REQUIRED COMPONENTS FileBrowsing TextEditor)

include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDEClangFormat)
include(ECMSetupVersion)
include(ECMSourceVersionControl)
include(FeatureSummary)

if(${ECM_SOURCE_UNDER_VERSION_CONTROL})
    execute_process(
        COMMAND git rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    # Get the latest abbreviated commit hash of the working branch
    execute_process(
        COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    add_definitions(-DGIT_COMMIT_HASH="${GIT_COMMIT_HASH}")
    add_definitions(-DGIT_BRANCH="${GIT_BRANCH}")

else()
    add_definitions(-DGIT_COMMIT_HASH="${NOTA_VERSION}")
    add_definitions(-DGIT_BRANCH="Stable")
endif()

ecm_setup_version(${NOTA_VERSION}
    VARIABLE_PREFIX NOTA
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/nota_version.h")

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

add_subdirectory(src)

ki18n_install(po)

install(FILES org.kde.nota.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.nota.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})

qt_finalize_project()

if(NOT TARGET uninstall)
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        IMMEDIATE
        @ONLY)

    add_custom_target(uninstall
        COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
endif()
