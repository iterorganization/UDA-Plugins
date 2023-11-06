macro( filter_lib_list INPUT OUTPUT GOOD BAD )
  set( LIB_LST ${INPUT} )
  set( USE_LIB YES )
  foreach( ELEMENT IN LISTS LIB_LST )
    if( "${ELEMENT}" STREQUAL "general" OR "${ELEMENT}" STREQUAL "${GOOD}" )
      set( USE_LIB YES )
    elseif( "${ELEMENT}" STREQUAL "${BAD}" )
      set( USE_LIB NO )
    elseif( USE_LIB )
      list( APPEND ${OUTPUT} ${ELEMENT} )
    endif()
  endforeach()
endmacro( filter_lib_list )

macro( uda_plugin )

  include( CMakeParseArguments )

  set( optionArgs )
  set( oneValueArgs NAME LIBNAME ENTRY_FUNC DESCRIPTION EXAMPLE CONFIG_FILE VERSION COPY_ASSET_DIR COPY_ASSET_FILE)
  set( multiValueArgs SOURCES EXTRA_INCLUDE_DIRS EXTRA_LINK_DIRS EXTRA_LINK_LIBS EXTRA_DEFINITIONS EXTRA_INSTALL_FILES )

  cmake_parse_arguments(
    PLUGIN
    "${optionArgs}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    "${ARGN}"
  )

  set( BUILT_PLUGINS ${BUILT_PLUGINS} "${PLUGIN_NAME}" PARENT_SCOPE )

  if( NOT PLUGIN_VERSION )
    set( PLUGIN_VERSION "0.0.0" )
  endif()

  find_package( UDA REQUIRED )

  include_directories(
    ${UDA_PLUGINS_INCLUDE_DIRS}
  )

  link_directories( ${UDA_PLUGINS_LIBRARY_DIRS} )

  if( CMAKE_COMPILER_IS_GNUCC )
    set( CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,defs" )
  endif()

  foreach( INCLUDE_DIR ${PLUGIN_EXTRA_INCLUDE_DIRS} )
    include_directories( SYSTEM ${INCLUDE_DIR} )
  endforeach()

  foreach( LINK_DIR ${PLUGIN_EXTRA_LINK_DIRS} )
    link_directories( ${LINK_DIR} )
  endforeach()

  add_library( ${PLUGIN_LIBNAME} SHARED ${PLUGIN_SOURCES} )
  set_target_properties( ${PLUGIN_LIBNAME}
    PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    SOVERSION ${PLUGIN_VERSION}
    VERSION ${PLUGIN_VERSION}
  )

  if( CMAKE_SIZEOF_VOID_P EQUAL 8 )
    add_definitions( -DA64 )
  endif()

  target_compile_definitions( ${PLUGIN_LIBNAME} PRIVATE -DSERVERBUILD -DPLUGIN_NAME="${PLUGIN_NAME}" -DPLUGIN_VERSION="${PLUGIN_VERSION}" )
  foreach( DEF ${PLUGIN_EXTRA_DEFINITIONS} )
    target_compile_definitions( ${PLUGIN_LIBNAME} PRIVATE ${DEF} )
  endforeach()

  target_link_libraries( ${PLUGIN_LIBNAME} LINK_PRIVATE ${UDA_PLUGINS_LIBRARIES} )

  filter_lib_list( "${PLUGIN_EXTRA_LINK_LIBS}" FILTERED_LINK_LIBS debug optimized )

  foreach( LINK_LIB ${FILTERED_LINK_LIBS} )
    target_link_libraries( ${PLUGIN_LIBNAME} LINK_PRIVATE ${LINK_LIB} )
  endforeach()

  install(
    TARGETS ${PLUGIN_LIBNAME}
    DESTINATION lib/plugins
  )

  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/udaPlugins_${PLUGIN_NAME}.conf
    DESTINATION etc/plugins
  )

  foreach( INSTALL_FILE ${PLUGIN_EXTRA_INSTALL_FILES} )
    get_filename_component( INSTALL_DIR ${INSTALL_FILE} DIRECTORY )
    install( FILES ${INSTALL_FILE} DESTINATION etc/plugins/${INSTALL_DIR} )
  endforeach()

  #targetFormat, formatClass="function", librarySymbol, libraryName, methodName, interface, cachePermission, publicUse, description, example
  if( APPLE )
    set( EXT_NAME "dylib" )
  else()
    set( EXT_NAME "so" )
  endif()

  file( WRITE "${CMAKE_CURRENT_BINARY_DIR}/udaPlugins_${PLUGIN_NAME}.conf"
    "${PLUGIN_NAME}, function, ${PLUGIN_ENTRY_FUNC}, lib${PLUGIN_LIBNAME}.${EXT_NAME}, *, 1, 1, 1, ${PLUGIN_DESCRIPTION}, ${PLUGIN_EXAMPLE}\n" )
  file( APPEND "${CMAKE_CURRENT_BINARY_DIR}/../udaPlugins.conf"
    "${PLUGIN_NAME}, function, ${PLUGIN_ENTRY_FUNC}, lib${PLUGIN_LIBNAME}.${EXT_NAME}, *, 1, 1, 1, ${PLUGIN_DESCRIPTION}, ${PLUGIN_EXAMPLE}\n" )

  if( NOT EXISTS "${CMAKE_BINARY_DIR}/etc/plugins.d" )
    file( MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/etc/plugins.d" )
  endif()

  if( NOT "${PLUGIN_CONFIG_FILE}" STREQUAL "" )
    configure_file(
      "${CMAKE_CURRENT_LIST_DIR}/${PLUGIN_CONFIG_FILE}.in"
      "${CMAKE_BINARY_DIR}/etc/plugins.d/${PLUGIN_CONFIG_FILE}"
      @ONLY
    )
  install(
    FILES "${CMAKE_BINARY_DIR}/etc/plugins.d/${PLUGIN_CONFIG_FILE}"
    DESTINATION etc/plugins.d
  )
  endif()

  if( NOT "${PLUGIN_COPY_ASSET_DIR}" STREQUAL "" )
    file(COPY "${CMAKE_CURRENT_LIST_DIR}/${PLUGIN_COPY_ASSET_DIR}/" DESTINATION "${CMAKE_BINARY_DIR}/etc/${PLUGIN_COPY_ASSET_DIR}")
    string(TOLOWER "${PLUGIN_NAME}" PLUGIN_ASSET_DIRECTORY) 
    install(
      DIRECTORY "${CMAKE_BINARY_DIR}/etc/${PLUGIN_COPY_ASSET_DIR}"
      DESTINATION "etc/${PLUGIN_ASSET_DIRECTORY}"
  )
  endif()
    if( NOT "${PLUGIN_COPY_ASSET_FILE}" STREQUAL "" )
    file(COPY "${CMAKE_CURRENT_LIST_DIR}/${PLUGIN_COPY_ASSET_FILE}/" DESTINATION "${CMAKE_BINARY_DIR}/etc/${PLUGIN_COPY_ASSET_FILE}")
    string(TOLOWER "${PLUGIN_NAME}" PLUGIN_ASSET_DIRECTORY)
    install(
      FILES "${CMAKE_BINARY_DIR}/etc/${PLUGIN_COPY_ASSET_FILE}"
      DESTINATION "etc/${PLUGIN_ASSET_DIRECTORY}"
  )
  endif()

endmacro( uda_plugin )
