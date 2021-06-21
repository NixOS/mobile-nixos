{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.13.0-rc2";
  configfile = ./config.aarch64;

  # FIXME: apply patchsets directly on top of mainline
  src = fetchFromGitHub {
    # Mirror of http://git.linaro.org/people/vinod.koul/kernel.git/commit/?h=pixel/dsc_rfc&id=dcf128e83ddd25e461a5080a349de5a0552eed32
    owner = "samueldr";
    repo = "linux";
    rev = "dcf128e83ddd25e461a5080a349de5a0552eed32";
    sha256 = "07xp9bi0xl54yfyspaw2aa410142xvy38p2l6z92ximajlgxh1gv";
  };

  patches = [
    ./0001-HACK-Add-back-TEXT_OFFSET-in-the-built-image.patch
  ];

  # TODO: generic mainline build; append per-device...
  postInstall = ''
    echo ':: Appending DTB'
    (PS4=" $ "; set -x
    cd $out
    cat Image.gz $buildRoot/arch/arm64/boot/dts/qcom/sdm845-blueline.dtb > Image.gz-dtb
    )
  '';

  isModular = false;
  isCompressed = "gz";
  kernelFile = "Image.gz-dtb";
}
