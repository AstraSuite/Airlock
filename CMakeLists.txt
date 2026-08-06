cmake_minimum_required(VERSION 3.19)

project(caelestia-greeter VERSION 1.0.0 LANGUAGES CXX)

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

# Install launcher binary
install(PROGRAMS bin/caelestia-greeter
    DESTINATION "${CMAKE_INSTALL_BINDIR}")

