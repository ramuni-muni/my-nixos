{ lib, fetchFromGitHub, rustPlatform, installShellFiles }:

rustPlatform.buildRustPackage rec {
  pname = "fd";
  version = "8.5.3";

  src = fetchFromGitHub {
    owner = "sharkdp";
    repo = "fd";
    # On the next release, go back to `rev = "v${version}";`
    # The 8.5.3 release appears to have been mysteriously re-tagged:
    # https://github.com/sharkdp/fd/issues/1184
    rev = "f6e74407e80a5563a9e4d0530371aed281e05838";
    sha256 = "sha256-7QQHLw+isXtr1FDQr4aiUhvOjJUPbaxFGDwukiWBG9g=";
  };

  cargoSha256 = "sha256-QFh47Pr+7lIdT++huziKgMJxvsZElTTwu11c7/wjyHE=";

  nativeBuildInputs = [ installShellFiles ];

  preFixup = ''
    installManPage doc/fd.1

    installShellCompletion $releaseDir/build/fd-find-*/out/fd.{bash,fish}
    installShellCompletion --zsh contrib/completion/_fd
  '';

  meta = with lib; {
    description = "A simple, fast and user-friendly alternative to find";
    longDescription = ''
      `fd` is a simple, fast and user-friendly alternative to `find`.

      While it does not seek to mirror all of `find`'s powerful functionality,
      it provides sensible (opinionated) defaults for 80% of the use cases.
    '';
    homepage = "https://github.com/sharkdp/fd";
    license = with licenses; [ asl20 /* or */ mit ];
    maintainers = with maintainers; [ dywedir globin ma27 zowoq ];
  };
}
