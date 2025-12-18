# SPDX-FileCopyrightText: 2024 Infineon Technologies AG
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.10)
project(optiga_trust_m C)

# Build options
option(USE_LIBGPIOD "Use libgpiod for GPIO (Raspberry Pi)" ON)
option(BUILD_FOR_ULTRA96 "Build for Ultra96 platform" OFF)

# Include directories
include_directories(
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/include/pal
    ${PROJECT_SOURCE_DIR}/include/common
    ${PROJECT_SOURCE_DIR}/include/comms
    ${PROJECT_SOURCE_DIR}/include/cmd
    ${PROJECT_SOURCE_DIR}/include/ifx_i2c
    ${PROJECT_SOURCE_DIR}/extras/pal/linux
    ${PROJECT_SOURCE_DIR}/extras/pal/linux/include
    ${PROJECT_SOURCE_DIR}/external/mbedtls/include
    ${PROJECT_SOURCE_DIR}/config
)

# Core library source files
file(GLOB SRC_CMD "src/cmd/*.c")
file(GLOB SRC_COMMON "src/common/*.c")
file(GLOB SRC_COMMS_CORE "src/comms/*.c")
file(GLOB SRC_COMMS_I2C "src/comms/ifx_i2c/*.c")
file(GLOB SRC_CRYPT "src/crypt/*.c")
file(GLOB SRC_UTIL "src/util/*.c")
file(GLOB MBEDTLS_SRC "external/mbedtls/library/*.c")

# PAL (Platform Abstraction Layer) files
set(PAL_FILES
    extras/pal/linux/pal.c
    extras/pal/linux/pal_i2c.c
    extras/pal/linux/pal_logger.c
    extras/pal/linux/pal_os_datastore.c
    extras/pal/linux/pal_os_event.c
    extras/pal/linux/pal_os_lock.c
    extras/pal/linux/pal_os_timer.c
    extras/pal/linux/pal_os_memory.c
    extras/pal/linux/pal_shared_mutex.c
    extras/pal/pal_crypt_mbedtls.c
)

# GPIO and target-specific configuration
if(USE_LIBGPIOD)
    list(APPEND PAL_FILES extras/pal/linux/pal_gpio_gpiod.c)
    list(APPEND PAL_FILES extras/pal/linux/target/gpiod/pal_ifx_i2c_config.c)
    add_definitions(-DHAS_LIBGPIOD)
elseif(BUILD_FOR_ULTRA96)
    list(APPEND PAL_FILES extras/pal/linux/pal_gpio.c)
    list(APPEND PAL_FILES extras/pal/linux/target/ultra96/pal_ifx_i2c_config.c)
else()
    list(APPEND PAL_FILES extras/pal/linux/pal_gpio.c)
    list(APPEND PAL_FILES extras/pal/linux/target/rpi3/pal_ifx_i2c_config.c)
endif()

# Compiler definitions (matching the parent Makefile)
add_definitions(-DOPTIGA_COMMS_SET_RESET_SOFT)
add_definitions(-DMBEDTLS_USER_CONFIG_FILE=\"../config/mbedtls_default_config.h\")

# Compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wno-format -fPIC")

# Build shared library
add_library(trustm SHARED
    ${SRC_CMD}
    ${SRC_COMMON}
    ${SRC_COMMS_CORE}
    ${SRC_COMMS_I2C}
    ${SRC_CRYPT}
    ${SRC_UTIL}
    ${MBEDTLS_SRC}
    ${PAL_FILES}
)

# Link libraries
target_link_libraries(trustm pthread rt)
if(USE_LIBGPIOD)
    target_link_libraries(trustm gpiod)
endif()

set_target_properties(trustm PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    OUTPUT_NAME "trustm"
)

# Install target
install(TARGETS trustm LIBRARY DESTINATION lib)

# Also build static library
add_library(trustm_static STATIC
    ${SRC_CMD}
    ${SRC_COMMON}
    ${SRC_COMMS_CORE}
    ${SRC_COMMS_I2C}
    ${SRC_CRYPT}
    ${SRC_UTIL}
    ${MBEDTLS_SRC}
    ${PAL_FILES}
)

set_target_properties(trustm_static PROPERTIES
    OUTPUT_NAME "trustm"
)

install(TARGETS trustm_static ARCHIVE DESTINATION lib)

