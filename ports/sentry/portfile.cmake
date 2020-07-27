include(vcpkg_common_functions)

find_program(GIT NAMES git git.cmd)

set(GIT_URL "https://github.com/getsentry/sentry-native.git")
set(GIT_REF "0.3.4")

set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/${GIT_REF})

if(NOT EXISTS "${SOURCE_PATH}")
    message(STATUS "Cloning")
    vcpkg_execute_required_process(
        COMMAND ${GIT} clone --recurse-submodules --branch ${GIT_REF} ${GIT_URL} ${SOURCE_PATH}
        WORKING_DIRECTORY ${DOWNLOADS}
        LOGNAME clone
    )
endif()
message(STATUS "Cloning done in ${SOURCE_PATH}" )

if( WIN32 )
	set( SENTRY_TRANSPORT "winhttp" )
	set( SENTRY_BACKEND "crashpad" )
	set( TOOL_NAME "crashpad_handler.exe" )
elseif( APPLE )
	set( SENTRY_TRANSPORT "curl" )
	set( SENTRY_BACKEND "crashpad" )
	set( TOOL_NAME "crashpad_handler" )
else()
	set( SENTRY_TRANSPORT "curl" )
	set( SENTRY_BACKEND "breakpad" )
	set( TOOL_NAME "" )
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DSENTRY_BUILD_TESTS=OFF
        -DSENTRY_BUILD_EXAMPLES=OFF
        -DSENTRY_TRANSPORT=${SENTRY_TRANSPORT}
        -DSENTRY_BACKEND=${SENTRY_BACKEND}
)

vcpkg_install_cmake()

vcpkg_fixup_cmake_targets( CONFIG_PATH lib/cmake/${PORT} TARGET_PATH share/${PORT} )

vcpkg_copy_pdbs()

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

# Debug cleanup
file( REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include ${CURRENT_PACKAGES_DIR}/debug/share )

# Tools
if( NOT TOOL_NAME STREQUAL "" )
	file( MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/tools/${PORT}/ )
	file( RENAME ${CURRENT_PACKAGES_DIR}/bin/${TOOL_NAME} ${CURRENT_PACKAGES_DIR}/tools/${PORT}/${TOOL_NAME} )
	vcpkg_copy_tool_dependencies( ${CURRENT_PACKAGES_DIR}/tools/${PORT} )
	file( REMOVE ${CURRENT_PACKAGES_DIR}/debug/bin/${TOOL_NAME} )
endif()
if( NOT WIN32 )
	file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

# Static cleanup
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()
