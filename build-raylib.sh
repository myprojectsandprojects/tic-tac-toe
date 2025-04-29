#set -e # stop on error?
cd raylib && mkdir build && cd build && cmake .. -DBUILD_SHARED_LIBS=OFF && cmake --build .
