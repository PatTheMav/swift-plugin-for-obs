cmake_minimum_required(VERSION 3.28...3.30)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/bootstrap.cmake" NO_POLICY_SCOPE)

project(${_name} VERSION ${_version})

include(compilerconfig)
include(defaults)
include(helpers)

add_library(${CMAKE_PROJECT_NAME} MODULE)

find_package(libobs REQUIRED)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::libobs)
set_property(TARGET OBS::libobs PROPERTY INTERFACE_COMPILE_OPTIONS "")

target_sources(${CMAKE_PROJECT_NAME} PRIVATE Source/plugin-main.swift Source/${CMAKE_PROJECT_NAME}-Bridging-Header.h)

if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/plugin-version.swift")
  target_sources(${CMAKE_PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/plugin-version.swift")
endif()

enable_language(Swift)

set_target_properties_plugin(
    ${CMAKE_PROJECT_NAME}
    PROPERTIES OUTPUT_NAME ${_name}
               XCODE_ATTRIBUTE_SWIFT_VERSION 6.0
               XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
               XCODE_ATTRIBUTE_CLANG_WARN_SUSPICIOUS_IMPLICIT_CONVERSION YES
               XCODE_ATTRIBUTE_GCC_WARN_SHADOW YES
               XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES YES
               XCODE_ATTRIBUTE_CLANG_MODULES_AUTOLINK YES
               XCODE_ATTRIBUTE_GCC_STRICT_ALIASING YES
               XCODE_ATTRIBUTE_DEFINES_MODULE YES
               XCODE_ATTRIBUTE_SWIFT_OBJC_BRIDGING_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/Source/${CMAKE_PROJECT_NAME}-Bridging-Header.h"
)
