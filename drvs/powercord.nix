{ lib
, powercord-unwrapped
, stdenvNoCC
, plugins
, themes
}:
stdenvNoCC.mkDerivation {
  name = "powercord";
  src = powercord-unwrapped.out;

  installPhase =
    let
      readName = f: lib.strings.sanitizeDerivationName (builtins.fromJSON (builtins.readFile f)).name;

      fromList = l: mn: builtins.map (e:
      let
        # We're relying on nix to coerce this into something we can use
        path = "${e}";
      in {
        inherit path;
        name = readName "${path}/${mn}";
      }) l;

      map = n: l: lib.concatMapStringsSep "\n" (e: ''
        chmod 755 $out/src/Powercord/${n}
        cp -a ${e.path} $out/src/Powercord/${n}/${e.name}
        chmod -R u+w $out/src/Powercord/${n}/${e.name}
      '') l;

      mappedPlugins = map "plugins" (fromList plugins "manifest.json");
      mappedThemes = map "themes" (fromList themes "powercord_manifest.json");
    in ''
      cp -a $src $out
      chmod 755 $out
      ln -s ${powercord-unwrapped.deps}/node_modules $out/node_modules

      ${mappedPlugins}
      ${mappedThemes}
    '';

  passthru.unwrapped = powercord-unwrapped;
  meta = powercord-unwrapped.meta // {
    priority = (powercord-unwrapped.meta.priority or 0) - 1;
  };
}
