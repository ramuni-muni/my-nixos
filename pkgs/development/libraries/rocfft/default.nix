{ lib
, stdenv
, fetchFromGitHub
, writeScript
, cmake
, rocm-cmake
, rocm-runtime
, rocm-device-libs
, rocm-comgr
, hip
, sqlite
, python3
, gtest
, boost
, fftw
, fftwFloat
, llvmPackages
, buildTests ? false
, buildBenchmarks ? false
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rocfft";
  version = "5.3.3";

  outputs = [
    "out"
  ] ++ lib.optionals buildTests [
    "test"
  ] ++ lib.optionals buildBenchmarks [
    "benchmark"
  ];

  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocFFT";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-jb2F1fRe+YLloYJ/KtzrptUDhmdBDBtddeW/g55owKM=";
  };

  nativeBuildInputs = [
    cmake
    rocm-cmake
    hip
  ];

  buildInputs = [
    rocm-runtime
    rocm-device-libs
    rocm-comgr
    sqlite
    python3
  ] ++ lib.optionals buildTests [
    gtest
  ] ++ lib.optionals (buildTests || buildBenchmarks) [
    boost
    fftw
    fftwFloat
    llvmPackages.openmp
  ];

  propogatedBuildInputs = lib.optionals buildTests [
    fftw
    fftwFloat
  ];

  cmakeFlags = [
    "-DCMAKE_C_COMPILER=hipcc"
    "-DCMAKE_CXX_COMPILER=hipcc"
    "-DUSE_HIP_CLANG=ON"
    "-DSQLITE_USE_SYSTEM_PACKAGE=ON"
    # Manually define CMAKE_INSTALL_<DIR>
    # See: https://github.com/NixOS/nixpkgs/pull/197838
    "-DCMAKE_INSTALL_BINDIR=bin"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ] ++ lib.optionals buildTests [
    "-DBUILD_CLIENTS_TESTS=ON"
  ] ++ lib.optionals buildBenchmarks [
    "-DBUILD_CLIENTS_RIDER=ON"
    "-DBUILD_CLIENTS_SAMPLES=ON"
  ];

  postInstall = lib.optionalString buildTests ''
    mkdir -p $test/{bin,lib/fftw}
    cp -a $out/bin/* $test/bin
    ln -s ${fftw}/lib/libfftw*.so $test/lib/fftw
    ln -s ${fftwFloat}/lib/libfftw*.so $test/lib/fftw
    rm -r $out/lib/fftw
    rm $test/bin/{rocfft_rtc_helper,*-rider} || true
  '' + lib.optionalString buildBenchmarks ''
    mkdir -p $benchmark/bin
    cp -a $out/bin/* $benchmark/bin
    rm $benchmark/bin/{rocfft_rtc_helper,*-test} || true
  '' + lib.optionalString (buildTests || buildBenchmarks ) ''
    mv $out/bin/rocfft_rtc_helper $out
    rm -r $out/bin/*
    mv $out/rocfft_rtc_helper $out/bin
  '';

  passthru.updateScript = writeScript "update.sh" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p curl jq common-updater-scripts
    version="$(curl ''${GITHUB_TOKEN:+"-u \":$GITHUB_TOKEN\""} \
      -sL "https://api.github.com/repos/ROCmSoftwarePlatform/rocFFT/releases?per_page=1" | jq '.[0].tag_name | split("-") | .[1]' --raw-output)"
    update-source-version rocfft "$version" --ignore-same-hash
  '';

  meta = with lib; {
    description = "FFT implementation for ROCm ";
    homepage = "https://github.com/ROCmSoftwarePlatform/rocFFT";
    license = with licenses; [ mit ];
    maintainers = teams.rocm.members;
    broken = finalAttrs.version != hip.version;
    hydraPlatforms = [ ]; # rocFFT produces an extremely large output
  };
})
