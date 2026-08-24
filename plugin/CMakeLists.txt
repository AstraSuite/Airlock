cmake_minimum_required(VERSION 3.19)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick DBus)

qt_standard_project_setup(REQUIRES 6.6)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

qt_add_qml_module(astra-airlock-plugin
    URI Astra.Airlock
    VERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    SOURCES
        src/greeterstate.hpp
        src/greeterstate.cpp
        src/sessiondiscovery.hpp
        src/sessiondiscovery.cpp
        src/userdiscovery.hpp
        src/userdiscovery.cpp
        src/schemediscovery.hpp
        src/schemediscovery.cpp
        src/sessionmanager.hpp
        src/sessionmanager.cpp
)

target_include_directories(astra-airlock-plugin PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(astra-airlock-plugin PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
    Qt6::DBus
)

# Install
include(GNUInstallDirs)
set(INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml"
    CACHE STRING "QML module install dir")

qt_query_qml_module(astra-airlock-plugin
    URI module_uri
    PLUGIN_TARGET module_plugin_target
    TARGET_PATH module_target_path
    QMLDIR module_qmldir
    TYPEINFO module_typeinfo
)

install(TARGETS astra-airlock-plugin
    LIBRARY DESTINATION "${INSTALL_QMLDIR}/${module_target_path}"
    RUNTIME DESTINATION "${INSTALL_QMLDIR}/${module_target_path}"
)
install(TARGETS "${module_plugin_target}"
    LIBRARY DESTINATION "${INSTALL_QMLDIR}/${module_target_path}"
    RUNTIME DESTINATION "${INSTALL_QMLDIR}/${module_target_path}"
)
install(FILES "${module_qmldir}" DESTINATION "${INSTALL_QMLDIR}/${module_target_path}")
install(FILES "${module_typeinfo}" DESTINATION "${INSTALL_QMLDIR}/${module_target_path}")
