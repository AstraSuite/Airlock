cmake_minimum_required(VERSION 3.19)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick)

qt_standard_project_setup(REQUIRES 6.6)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

qt_add_qml_module(caelestia-greeter-plugin
    URI Caelestia.Greeter
    VERSION 1.0
    SOURCES
        src/greeterstate.hpp
        src/sessiondiscovery.hpp
        src/sessiondiscovery.cpp
        src/userdiscovery.hpp
        src/userdiscovery.cpp
        src/schemediscovery.hpp
        src/schemediscovery.cpp
)

target_include_directories(caelestia-greeter-plugin PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(caelestia-greeter-plugin PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
)

# Install
include(GNUInstallDirs)
set(INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml"
    CACHE STRING "QML module install dir")

qt_query_qml_module(caelestia-greeter-plugin
    URI module_uri
    PLUGIN_TARGET module_plugin_target
    TARGET_PATH module_target_path
    QMLDIR module_qmldir
    TYPEINFO module_typeinfo
)

install(TARGETS caelestia-greeter-plugin
    LIBRARY DESTINATION "${INSTALL_QMLDIR}/${module_target_path}"
    RUNTIME DESTINATION "${INSTALL_QMLDIR}/${module_target_path}"
)
install(TARGETS "${module_plugin_target}"
    LIBRARY DESTINATION "${INSTALL_QMLDIR}/${module_target_path}"
    RUNTIME DESTINATION "${INSTALL_QMLDIR}/${module_target_path}"
)
install(FILES "${module_qmldir}" DESTINATION "${INSTALL_QMLDIR}/${module_target_path}")
install(FILES "${module_typeinfo}" DESTINATION "${INSTALL_QMLDIR}/${module_target_path}")
