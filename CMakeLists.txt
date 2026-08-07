cmake_minimum_required(VERSION 3.19)

# Version selection: pass -DCAELESTIA_GREETER_VERSION=X.Y.Z to pin the version
# manually, otherwise derive it from the most recent git tag (e.g. v1.2.3).
set(CAELESTIA_GREETER_VERSION ""
    CACHE STRING "Version of caelestia-greeter (default: latest git tag)")

if(NOT CAELESTIA_GREETER_VERSION)
    find_package(Git QUIET)
    if(GIT_EXECUTABLE)
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" describe --tags --match "v[0-9]*" --abbrev=0 HEAD
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            RESULT_VARIABLE git_describe_result
            OUTPUT_VARIABLE git_describe_version
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
        if(git_describe_result EQUAL 0 AND git_describe_version)
            string(REGEX REPLACE "^v" "" CAELESTIA_GREETER_VERSION "${git_describe_version}")
        endif()
    endif()
endif()

if(NOT CAELESTIA_GREETER_VERSION)
    set(CAELESTIA_GREETER_VERSION "0.0.0")
endif()

project(caelestia-greeter VERSION ${CAELESTIA_GREETER_VERSION} LANGUAGES CXX)

# Default to /usr so a plain `cmake --install build` lands in the locations
# the launcher and README expect (/usr/bin, /etc/xdg/quickshell/...).
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Installation prefix" FORCE)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_compile_options(
    -Wall -Wextra -Wpedantic -Wshadow -Wconversion
    -Wold-style-cast -Wnull-dereference -Wdouble-promotion
    -Wformat=2
)

include(GNUInstallDirs)

# System configuration is prefix-independent and always read from /etc by the
# launcher, so install it to an absolute path regardless of CMAKE_INSTALL_PREFIX.
set(INSTALL_QSCONFDIR "/etc/xdg/quickshell/caelestia-greeter"
    CACHE STRING "Quickshell config install dir")

add_subdirectory(plugin)

# Install QML source files
install(DIRECTORY components modules services assets
    DESTINATION "${INSTALL_QSCONFDIR}")
install(FILES shell.qml README.md
    DESTINATION "${INSTALL_QSCONFDIR}")

# Build the launcher binary (compiled, installed as caelestia-greeter)
add_executable(caelestia-greeter-launcher launcher/main.cpp)
target_compile_definitions(caelestia-greeter-launcher PRIVATE
    CAELESTIA_GREETER_VERSION="${PROJECT_VERSION}"
)
set_target_properties(caelestia-greeter-launcher PROPERTIES OUTPUT_NAME caelestia-greeter)
install(TARGETS caelestia-greeter-launcher RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")

