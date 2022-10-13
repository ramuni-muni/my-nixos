{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, nix-update-script
, wrapGAppsHook
, pkg-config
, meson
, ninja
, vala
, gala
, gtk3
, libgee
, granite
, gettext
, mutter
, mesa
, json-glib
, python3
, elementary-gtk-theme
, elementary-icon-theme
}:

stdenv.mkDerivation rec {
  pname = "wingpanel";
  version = "unstable-2022-10-13";

  src = fetchFromGitHub {
    owner = "elementary";
    repo = pname;
    rev = "8be50d17eb10458f89a6c5e029c81e6f3042c6f9";
    sha256 = "sha256-4PqBCzmMrX5zPuoGlRoMGe6jotll5ofPyCgJMBv6Lyw=";
  };

  patches = [
    ./indicators.patch

    # Fix build with gala 6.3.2
    # https://github.com/elementary/wingpanel/pull/470
    (fetchpatch {
      url = "https://github.com/elementary/wingpanel/commit/00aa43cf0d0653ccc563577360be500678fa1e53.patch";
      sha256 = "sha256-JXAvR3r8LtGgegGbb62sVnrrpvbsaIhNx8Z0KfHElz4=";
    })
  ];

  nativeBuildInputs = [
    gettext
    meson
    ninja
    pkg-config
    python3
    vala
    wrapGAppsHook
  ];

  buildInputs = [
    elementary-icon-theme
    gala
    granite
    gtk3
    json-glib
    libgee
    mutter
    mesa # for libEGL
  ];

  postPatch = ''
    chmod +x meson/post_install.py
    patchShebangs meson/post_install.py
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      # this GTK theme is required
      --prefix XDG_DATA_DIRS : "${elementary-gtk-theme}/share"

      # the icon theme is required
      --prefix XDG_DATA_DIRS : "$XDG_ICON_DIRS"
    )
  '';

  passthru = {
    updateScript = nix-update-script {
      attrPath = "pantheon.${pname}";
    };
  };

  meta = with lib; {
    description = "The extensible top panel for Pantheon";
    longDescription = ''
      Wingpanel is an empty container that accepts indicators as extensions,
      including the applications menu.
    '';
    homepage = "https://github.com/elementary/wingpanel";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = teams.pantheon.members;
    mainProgram = "io.elementary.wingpanel";
  };
}
