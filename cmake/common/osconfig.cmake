# CMake operating system bootstrap module

include_guard(GLOBAL)

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
  set(CMAKE_C_EXTENSIONS FALSE)
  set(CMAKE_CXX_EXTENSIONS FALSE)
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/macos")
  set(OS_MACOS TRUE)
else()
  message(FATAL_ERROR "Platform '${CMAKE_HOST_SYSTEM_NAME}' is not supported - this plugin supports macOS only.")
endif()
