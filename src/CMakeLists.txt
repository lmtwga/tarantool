#
# Set compile flags for entire src/ directory
#
enable_tnt_compile_flags()

include_directories(${LIBEV_INCLUDE_DIR})
include_directories(${LIBEIO_INCLUDE_DIR})
include_directories(${LIBCORO_INCLUDE_DIR})
include_directories(${LIBGOPT_INCLUDE_DIR})
include_directories(${LUAJIT_INCLUDE_DIRS})
include_directories(${READLINE_INCLUDE_DIRS})
include_directories(${LIBYAML_INCLUDE_DIRS})
include_directories(${MSGPUCK_INCLUDE_DIRS})

set(LIBUTIL_FREEBSD_SRC ${CMAKE_SOURCE_DIR}/third_party/libutil_freebsd)
include_directories(${LIBUTIL_FREEBSD_SRC})

# Compile src/lua/*.lua files into src/lua/*.lua.c sources
set(lua_sources)
lua_source(lua_sources lua/init.lua)
lua_source(lua_sources lua/fiber.lua)
lua_source(lua_sources lua/buffer.lua)
lua_source(lua_sources lua/uuid.lua)
lua_source(lua_sources lua/crypto.lua)
lua_source(lua_sources lua/digest.lua)
lua_source(lua_sources lua/msgpackffi.lua)
lua_source(lua_sources lua/uri.lua)
lua_source(lua_sources lua/console.lua)
lua_source(lua_sources lua/socket.lua)
lua_source(lua_sources lua/errno.lua)
lua_source(lua_sources lua/log.lua)
lua_source(lua_sources lua/help.lua)
lua_source(lua_sources lua/help_en_US.lua)
lua_source(lua_sources lua/tap.lua)
lua_source(lua_sources lua/fio.lua)
lua_source(lua_sources lua/csv.lua)
lua_source(lua_sources lua/strict.lua)
lua_source(lua_sources lua/clock.lua)
lua_source(lua_sources lua/title.lua)
lua_source(lua_sources lua/argparse.lua)
lua_source(lua_sources lua/env.lua)
lua_source(lua_sources lua/trigger.lua)
lua_source(lua_sources ../third_party/luafun/fun.lua)
# LuaJIT jit.* library
lua_source(lua_sources "${CMAKE_BINARY_DIR}/third_party/luajit/src/jit/bc.lua")
lua_source(lua_sources "${CMAKE_BINARY_DIR}/third_party/luajit/src/jit/bcsave.lua")
lua_source(lua_sources "${CMAKE_BINARY_DIR}/third_party/luajit/src/jit/dis_x86.lua")
lua_source(lua_sources "${CMAKE_BINARY_DIR}/third_party/luajit/src/jit/dis_x64.lua")
lua_source(lua_sources "${CMAKE_BINARY_DIR}/third_party/luajit/src/jit/dump.lua")
lua_source(lua_sources "${CMAKE_BINARY_DIR}/third_party/luajit/src/jit/vmdef.lua")
lua_source(lua_sources "${CMAKE_BINARY_DIR}/third_party/luajit/src/jit/v.lua")
lua_source(lua_sources "${CMAKE_BINARY_DIR}/third_party/luajit/src/jit/p.lua")
lua_source(lua_sources "${CMAKE_BINARY_DIR}/third_party/luajit/src/jit/zone.lua")

add_custom_target(generate_lua_sources
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/src/box
    DEPENDS ${lua_sources})
set_property(DIRECTORY PROPERTY ADDITIONAL_MAKE_CLEAN_FILES ${lua_sources})

add_custom_target(ragel
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMAND ragel -G2 src/uri.rl -o src/uri.c)

set (core_sources
     diag.c
     say.c
     memory.c
     fiber.c
     cbus.c
     fiber_pool.c
     exception.cc
     coro.c
     reflection.c
     assoc.c
     rmean.c
     histogram.c
     util.c
     path_lock.c
 )

add_library(core STATIC ${core_sources})
target_link_libraries(core
    salad small pthread
    ${LIBEV_LIBRARIES}
    ${LIBCORO_LIBRARIES}
)

set (server_sources
     find_path.c
     sio.cc
     evio.cc
     coio.cc
     coeio.c
     iobuf.cc
     coio_buf.cc
     pickle.c
     ipc.c
     latch.c
     errinj.c
     fio.c
     crc32.c
     random.c
     scramble.c
     opts.c
     cfg.c
     cpu_feature.c
     tt_uuid.c
     uri.c
     backtrace.cc
     proc_title.c
     coeio_file.c
     clock.c
     lua/console.c
     lua/digest.c
     lua/init.c
     lua/fiber.c
     lua/trigger.c
     lua/ipc.c
     lua/msgpack.c
     lua/utils.c
     lua/errno.c
     lua/socket.c
     lua/pickle.c
     lua/fio.c
     lua/crypto.c
     ${lua_sources}
     ${PROJECT_SOURCE_DIR}/third_party/lua-yaml/lyaml.cc
     ${PROJECT_SOURCE_DIR}/third_party/lua-yaml/b64.c
     ${PROJECT_SOURCE_DIR}/third_party/lua-cjson/lua_cjson.c
     ${PROJECT_SOURCE_DIR}/third_party/lua-cjson/strbuf.c
)

set(api_headers
    ${CMAKE_BINARY_DIR}/src/trivia/config.h
    ${CMAKE_SOURCE_DIR}/src/trivia/util.h
    ${CMAKE_SOURCE_DIR}/src/say.h
    ${CMAKE_SOURCE_DIR}/src/fiber.h
    ${CMAKE_SOURCE_DIR}/src/coio.h
    ${CMAKE_SOURCE_DIR}/src/coeio.h
    ${CMAKE_SOURCE_DIR}/src/lua/utils.h
    ${CMAKE_SOURCE_DIR}/src/box/txn.h
    ${CMAKE_SOURCE_DIR}/src/box/tuple.h
    ${CMAKE_SOURCE_DIR}/src/box/memtx_tuple.h
    ${CMAKE_SOURCE_DIR}/src/box/schema.h
    ${CMAKE_SOURCE_DIR}/src/box/box.h
    ${CMAKE_SOURCE_DIR}/src/box/index.h
    ${CMAKE_SOURCE_DIR}/src/box/error.h
    ${CMAKE_SOURCE_DIR}/src/box/lua/call.h
    ${CMAKE_SOURCE_DIR}/src/latch.h
    ${CMAKE_SOURCE_DIR}/src/clock.h
)
rebuild_module_api(${api_headers})

if (NOT TARGET_OS_DEBIAN_FREEBSD)
    if (TARGET_OS_FREEBSD)
        set_source_files_properties(
        ${PROJECT_SOURCE_DIR}/src/proc_title.c
        PROPERTIES COMPILE_FLAGS "-DHAVE_SETPROCTITLE")
    endif()
endif()

set_source_files_compile_flags(${server_sources})
add_library(server STATIC ${server_sources})
target_link_libraries(server core bit)

# Rule of thumb: if exporting a symbol from a static library, list the
# library here.
set (reexport_libraries server core misc bitset csv
     ${LUAJIT_LIBRARIES} ${MSGPUCK_LIBRARIES})

set (common_libraries
    ${reexport_libraries}
    ${LIBEIO_LIBRARIES}
    ${LIBGOPT_LIBRARIES}
    ${LIBYAML_LIBRARIES}
    ${READLINE_LIBRARIES}
    ${OPENSSL_LIBRARIES}
)

if (TARGET_OS_LINUX OR TARGET_OS_DEBIAN_FREEBSD)
    set (common_libraries ${common_libraries} dl rt)
endif()

if (TARGET_OS_FREEBSD AND NOT TARGET_OS_DEBIAN_FREEBSD)
    find_library (INTL intl)
    if (NOT INTL)
        message(FATAL_ERROR "intl library not found")
    else()
        set (common_libraries ${common_libraries} ${INTL})
    endif()
endif()

if (ENABLE_BACKTRACE AND HAVE_BFD)
    set (common_libraries ${common_libraries} ${BFD_LIBRARIES})
endif()

set (common_libraries ${common_libraries} ${LIBUUID_LIBRARIES})
set (common_libraries ${common_libraries} PARENT_SCOPE)

add_subdirectory(lib)
add_subdirectory(box)

# Save CMAKE_XXX_FLAGS from this directory for config.h (used in --version)
set(TARANTOOL_C_FLAGS ${CMAKE_C_FLAGS} PARENT_SCOPE)
set(TARANTOOL_CXX_FLAGS ${CMAKE_CXX_FLAGS} PARENT_SCOPE)

# Exports syntax is toolchain-dependent, preprocessing is necessary
set(exports_file ${CMAKE_BINARY_DIR}/extra/exports.${CMAKE_SYSTEM_NAME})
add_custom_target(preprocess_exports
                  DEPENDS ${exports_file})
add_custom_command(
    OUTPUT  ${exports_file}
    DEPENDS ${CMAKE_SOURCE_DIR}/extra/exports
    COMMAND ${CMAKE_SOURCE_DIR}/extra/mkexports
            ${CMAKE_SOURCE_DIR}/extra/exports
            ${exports_file} ${CMAKE_SYSTEM_NAME})

add_executable(
	tarantool main.cc title.c
	${LIBUTIL_FREEBSD_SRC}/flopen.c
	${LIBUTIL_FREEBSD_SRC}/pidfile.c)

add_dependencies(tarantool build_bundled_libs preprocess_exports)

# Re-link if exports changed
set_target_properties(tarantool PROPERTIES LINK_DEPENDS ${exports_file})

# A note about linkers:
# [GNU linker] When linking an *executable* visibility is ignored, and
#              either nothing is exported (default), or any non-static
#              symbol is exported (-rdynamic), or explicitly listed
#              symbols are exported (--dynamic-list).
#
#              However, if a symbol listed lives in a static library it
#              won't be automatically pulled, hence --whole-archive
#              option.
#
# [Apple linker] One can provide an explicit export list; pulls symbols
#                from static libraries.
#
if (TARGET_OS_DARWIN)
    target_link_libraries(tarantool box ${common_libraries})
    # Necessary to make LuaJIT work on Darwin, see
    # http://luajit.org/install.html
    set_target_properties(tarantool PROPERTIES
        LINK_FLAGS "-pagezero_size 10000 -image_base 100000000 \
        -Wl,-exported_symbols_list,${exports_file}")
else ()
    target_link_libraries(tarantool
                          -Wl,--whole-archive box ${reexport_libraries}
                          salad -Wl,--no-whole-archive
                          ${common_libraries})
    set_target_properties(tarantool PROPERTIES
        LINK_FLAGS "-Wl,--dynamic-list,${exports_file}")
    # get rid of -rdynamic
    set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
endif()

install (TARGETS tarantool DESTINATION bin)
