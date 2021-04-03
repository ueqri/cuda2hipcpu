cmake_minimum_required(VERSION 3.16)
project(test-HIP-CPU)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Threads REQUIRED)

file(GLOB SOURCE_CPP_FILES ${CMAKE_SOURCE_DIR}/*.cpp)

add_executable(${PROJECT_NAME} ${SOURCE_CPP_FILES})

target_compile_options(${PROJECT_NAME} PRIVATE -Wall -fopenmp-simd -fpermissive)
target_link_libraries(${PROJECT_NAME} PRIVATE dl tbb)
target_include_directories(
    ${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../../include)
target_link_libraries(${PROJECT_NAME} PRIVATE Threads::Threads)
