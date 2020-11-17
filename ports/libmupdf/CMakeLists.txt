cmake_minimum_required(VERSION 3.9)
project(libmupdf C)

set(CMAKE_DEBUG_POSTFIX d)
set(coffs)

if(WIN32)
  add_executable(bin2coff "scripts/bin2coff.c")
  file(GLOB_RECURSE FONTS "resources/fonts/*.[otc][ft][cf]")
  foreach(f ${FONTS})
    get_filename_component(fn "${f}" NAME_WE)
    get_filename_component(fx "${f}" EXT)
    string(SUBSTRING "${fx}" 1 -1 fx)
    add_custom_command(OUTPUT "${fn}_${fx}.obj"
        COMMAND bin2coff "${f}" "${fn}_${fx}.obj" "_binary_${fn}_${fx}" ${VCPKG_TARGET_ARCHITECTURE}
        MAIN_DEPENDENCY "${f}"
        COMMENT "Generating coff for ${fn}.${fx}"
        VERBATIM
    )
    list(APPEND coffs "${fn}_${fx}.obj")
  endforeach()
else()
  find_program(MAKE_EXE NAMES make REQUIRED)
  execute_process(
    COMMAND ${MAKE_EXE} "generate"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  )
endif() 


find_package(freetype NO_MODULE REQUIRED)
find_package(JPEG REQUIRED)
find_path(HARFBUZZ_INCLUDE hb.h PATH_SUFFIXES harfbuzz)
find_library(HARFBUZZ_LIBRARIES harfbuzz)
find_package(ZLIB REQUIRED)
find_package(OpenJPEG CONFIG REQUIRED)
find_library(JBIG2DEC_LIB NAMES jbig2decd jbig2dec)

file(GLOB_RECURSE SOURCES "source/*.c" "generated/*.c")
list(FILTER SOURCES EXCLUDE REGEX "source/tools/[a-z]*\\.c$")
list(FILTER SOURCES EXCLUDE REGEX "source/tests/.*.c$")

add_library(libmupdf ${SOURCES} ${coffs})

if(WIN32)
  target_compile_definitions(libmupdf PRIVATE -DSHARE_JPEG -DFZ_ENABLE_JS=0 -DFZ_ENABLE_ICC=0)
else()
  target_compile_definitions(libmupdf PRIVATE -DSHARE_JPEG -DFZ_ENABLE_JS=0 -DFZ_ENABLE_ICC=0 -DHAVE_PTHREAD=1)
endif()
target_include_directories(libmupdf
  PUBLIC
    include
  PRIVATE
    generated
    ${JPEG_INCLUDE_DIR}
    ${HARFBUZZ_INCLUDE}
)
target_link_libraries(libmupdf PRIVATE
  openjp2
  freetype
  ${JPEG_LIBRARIES}
  ${HARFBUZZ_LIBRARIES}
  ${JBIG2DEC_LIB}
  ZLIB::ZLIB
)

install(TARGETS libmupdf
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
)

if(BUILD_EXAMPLES)
  add_executable(mu-office-test source/tests/mu-office-test.c)
  target_link_libraries(mu-office-test PRIVATE libmupdf)
endif()
