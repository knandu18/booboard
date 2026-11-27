cmake_minimum_required(VERSION 3.22.1)
project(booboard_images LANGUAGES C CXX)

# libbooboard_images.so: stable-diffusion.cpp (offline image engine) behind a small JNI bridge.
# Built for arm64-v8a and x86_64 only (see android/app/build.gradle.kts). No network code: the engine is
# built as a library without its server, WebP/WebM or any backend that talks to a network (RPC is off).
# See third_party/README.md for the pinned source, the patch and how to update.

get_filename_component(BOOBOARD_REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../.." ABSOLUTE)
set(SDCPP_DIR "${BOOBOARD_REPO_ROOT}/third_party/stable-diffusion.cpp")
set(SDCPP_PATCH "${BOOBOARD_REPO_ROOT}/third_party/patches/sdcpp-host-headroom.patch")

if(NOT EXISTS "${SDCPP_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "stable-diffusion.cpp source missing at ${SDCPP_DIR}. "
        "Run: git submodule update --init third_party/stable-diffusion.cpp "
        "&& git -C third_party/stable-diffusion.cpp submodule update --init ggml")
endif()
if(NOT EXISTS "${SDCPP_DIR}/ggml/CMakeLists.txt")
    message(FATAL_ERROR "ggml source missing at ${SDCPP_DIR}/ggml. "
        "Run: git -C third_party/stable-diffusion.cpp submodule update --init ggml")
endif()

# ---- Patch: smaller free-RAM margin for phones (idempotent) ---------------------------------------------
# The patch is applied to the working tree of the pinned submodule (the submodule is marked ignore = dirty).
# Already applied -> reverse check passes -> nothing to do. Not applied -> apply. Neither -> fail loudly.
find_program(BOOBOARD_GIT NAMES git git.exe NO_CMAKE_FIND_ROOT_PATH)
if(NOT BOOBOARD_GIT)
    message(FATAL_ERROR "git is required to apply ${SDCPP_PATCH}")
endif()
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${SDCPP_PATCH}")
execute_process(
    COMMAND "${BOOBOARD_GIT}" apply --check --reverse "${SDCPP_PATCH}"
    WORKING_DIRECTORY "${SDCPP_DIR}"
    RESULT_VARIABLE SDCPP_PATCH_APPLIED
    OUTPUT_QUIET ERROR_QUIET)
if(SDCPP_PATCH_APPLIED EQUAL 0)
    message(STATUS "sdcpp-host-headroom.patch: already applied")
else()
    execute_process(
        COMMAND "${BOOBOARD_GIT}" apply --check "${SDCPP_PATCH}"
        WORKING_DIRECTORY "${SDCPP_DIR}"
        RESULT_VARIABLE SDCPP_PATCH_CLEAN
        OUTPUT_VARIABLE SDCPP_PATCH_OUT ERROR_VARIABLE SDCPP_PATCH_OUT)
    if(NOT SDCPP_PATCH_CLEAN EQUAL 0)
        message(FATAL_ERROR "sdcpp-host-headroom.patch neither applies nor is already applied to ${SDCPP_DIR}. "
            "The submodule is probably not at the pinned commit (see third_party/README.md).\n${SDCPP_PATCH_OUT}")
    endif()
    execute_process(
        COMMAND "${BOOBOARD_GIT}" apply "${SDCPP_PATCH}"
        WORKING_DIRECTORY "${SDCPP_DIR}"
        RESULT_VARIABLE SDCPP_PATCH_RC
        OUTPUT_VARIABLE SDCPP_PATCH_OUT ERROR_VARIABLE SDCPP_PATCH_OUT)
    if(NOT SDCPP_PATCH_RC EQUAL 0)
        message(FATAL_ERROR "Applying sdcpp-host-headroom.patch failed:\n${SDCPP_PATCH_OUT}")
    endif()
    message(STATUS "sdcpp-host-headroom.patch: applied")
endif()

# ---- Compiler and linker flags ---------------------------------------------------------------------------
# Optimise in every build type: an unoptimised ggml is unusably slow even for debugging the app.
set(CMAKE_C_FLAGS_DEBUG "-O2 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "-O2 -DNDEBUG")
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
# Hide everything except the JNI exports (version script below); one section per function so --gc-sections
# can drop the model families this app never uses.
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvisibility=hidden -ffunction-sections -fdata-sections")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility=hidden -fvisibility-inlines-hidden -ffunction-sections -fdata-sections")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ---- stable-diffusion.cpp / ggml options -----------------------------------------------------------------
# Same options as the proof (docs/waves/images.md): CPU only, baseline instruction sets so one build runs on
# every phone of the ABI (arm64-v8a baseline armv8-a; x86_64 baseline without AVX, which also runs on the
# emulator). No Vulkan/OpenCL yet.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(SD_BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(SD_BUILD_SHARED_GGML_LIB OFF CACHE BOOL "" FORCE)
set(SD_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(SD_WEBP OFF CACHE BOOL "" FORCE)
set(SD_WEBM OFF CACHE BOOL "" FORCE)
set(SD_VULKAN OFF CACHE BOOL "" FORCE)
set(SD_OPENCL OFF CACHE BOOL "" FORCE)
set(SD_CUDA OFF CACHE BOOL "" FORCE)
set(SD_HIPBLAS OFF CACHE BOOL "" FORCE)
set(SD_METAL OFF CACHE BOOL "" FORCE)
set(SD_SYCL OFF CACHE BOOL "" FORCE)
set(SD_MUSA OFF CACHE BOOL "" FORCE)
set(SD_RPC OFF CACHE BOOL "" FORCE)
set(GGML_RPC OFF CACHE BOOL "" FORCE)
set(GGML_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GGML_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_STATIC OFF CACHE BOOL "" FORCE)
set(GGML_LTO OFF CACHE BOOL "" FORCE)
set(GGML_CCACHE OFF CACHE BOOL "" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "" FORCE)
set(GGML_OPENCL OFF CACHE BOOL "" FORCE)
set(GGML_BLAS OFF CACHE BOOL "" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)
set(GGML_CPU_KLEIDIAI OFF CACHE BOOL "" FORCE)
option(BOOBOARD_IMAGES_OPENMP "Use OpenMP threads in ggml (libomp linked statically)" ON)
set(GGML_OPENMP ${BOOBOARD_IMAGES_OPENMP} CACHE BOOL "" FORCE)
if(BOOBOARD_IMAGES_OPENMP)
    # The NDK ships libomp both as .so and .a, and FindOpenMP picks the .so (one more file to ship, plus a
    # NEEDED entry). Point it at the .a so the runtime is linked into libbooboard_images.so.
    find_package(OpenMP REQUIRED COMPONENTS CXX)
    string(REGEX REPLACE "\\.so$" ".a" BOOBOARD_LIBOMP_STATIC "${OpenMP_omp_LIBRARY}")
    if(EXISTS "${BOOBOARD_LIBOMP_STATIC}")
        set(OpenMP_omp_LIBRARY "${BOOBOARD_LIBOMP_STATIC}" CACHE FILEPATH "libomp (static)" FORCE)
    else()
        message(FATAL_ERROR "Static libomp not found next to ${OpenMP_omp_LIBRARY}; configure with -DBOOBOARD_IMAGES_OPENMP=OFF")
    endif()
endif()
# x86_64 baseline (the options are ignored on ARM).
foreach(opt AVX AVX2 AVX512 AVX512_VBMI AVX512_VNNI AVX512_BF16 AVX_VNNI AMX_TILE AMX_INT8 AMX_BF16 FMA F16C BMI2 SSE42)
    set(GGML_${opt} OFF CACHE BOOL "" FORCE)
endforeach()

add_subdirectory("${SDCPP_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/sdcpp")

# ---- The JNI library -------------------------------------------------------------------------------------
add_library(booboard_images SHARED booboard_images_jni.cpp)
target_link_libraries(booboard_images PRIVATE stable-diffusion log)
target_compile_features(booboard_images PRIVATE cxx_std_17)
set_target_properties(booboard_images PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON)
target_link_options(booboard_images PRIVATE
    -Wl,--gc-sections
    -Wl,--exclude-libs,ALL
    -Wl,--version-script=${CMAKE_CURRENT_LIST_DIR}/booboard_images.map
    -Wl,-z,max-page-size=16384
    -Wl,-z,common-page-size=16384
    -Wl,--build-id=none)
set_property(TARGET booboard_images APPEND PROPERTY LINK_DEPENDS "${CMAKE_CURRENT_LIST_DIR}/booboard_images.map")
if(GGML_OPENMP)
    # libomp linked statically so no extra libomp.so has to ship in the APK.
    target_link_options(booboard_images PRIVATE -static-openmp)
endif()
