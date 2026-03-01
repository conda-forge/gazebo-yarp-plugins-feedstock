#!/bin/sh

rm -rf build
mkdir build
cd build

if [[ "${target_platform}" == osx-* ]]; then
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" == "1" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DYARPIDL_thrift_LOCATION=$BUILD_PREFIX/bin/yarpidl_thrift"
fi

# Assimp variable is explicitly set to workaround cross-compilation problems
cmake ${CMAKE_ARGS} -GNinja .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS:BOOL=ON \
      -DBUILD_TESTING:BOOL=ON \
      -DASSIMP_VERSION_MAJOR=6 \
      -DASSIMP_VERSION_MINOR=0 \
      -DASSIMP_VERSION_REVISION=3 \
      ..

cmake --build . --config Release

# We do not run test in cross-compilation as of September 2024 they fail
if [[ ("${CONDA_BUILD_CROSS_COMPILATION:-}" != "1") && "${target_platform}" != osx-* ]]; then
  ctest --output-on-failure --repeat until-pass:5 -C Release 
fi

cmake --build . --config Release --target install

# Generate and copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    multisheller ${RECIPE_DIR}/${CHANGE}.msh --output ./${CHANGE}
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
    cp "${CHANGE}.bash" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.bash"
    cp "${CHANGE}.xsh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.xsh"
    cp "${CHANGE}.zsh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.zsh"
    cp "${CHANGE}.ps1" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.ps1"
done
