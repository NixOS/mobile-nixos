{ stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, pkgconfig
, runtimeShell
, pulseaudio
, libpulseaudio
, libtool
, runCommand
, android-headers
, libhybris
, dbus
}:

let
  version = "12.2.85";

  # Export private header files
  pulsecore = runCommand "pulsecore-headers" {} ''
    mkdir -p $out/include/pulsecore/filter
    tar -xf ${pulseaudio.src}
    cp -a pulseaudio-${pulseaudio.version}/src/pulsecore/*.h $out/include/pulsecore/
    cp -a pulseaudio-${pulseaudio.version}/src/pulsecore/filter/*.h $out/include/pulsecore/filter/
    mkdir -p $out/lib/pkgconfig/
    sed s/'Name: libpulse'/'Name: pulsecore'/ ${lib.getDev pulseaudio}/lib/pkgconfig/libpulse.pc > $out/lib/pkgconfig/pulsecore.pc
  '';

in stdenv.mkDerivation rec {
  pname = "pulseaudio-modules-droid";
  inherit version;

  src = fetchFromGitHub {
    owner = "mer-hybris";
    repo = "pulseaudio-modules-droid";
    rev = version;
    sha256 = "1z0nlcdyjq4jp04q6q7k3sb288jq5varmpjgq7zadn7w55bp87cp";
  };

  postPatch = ''
    # Patch git usage
    cat > git-version-gen << EOF
    #!${runtimeShell}
    echo -n ${version}
    EOF
  '';

  nativeBuildInputs = [
    autoreconfHook
    pkgconfig
    libtool
  ];

  buildInputs = [
    android-headers
    pulsecore
    pulseaudio
    libhybris
    dbus
  ];

  meta = with stdenv.lib; {
    homepage = https://github.com/mer-hybris/pulseaudio-modules-droid;
    description = "PulseAudio Droid modules";
    platforms = platforms.linux;
    license = licenses.lgpl21;
    maintainers = with maintainers; [ adisbladis ];
  };
}
