{
  description = "Zig ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zls-overlay = {
      url = "github:zigtools/zls";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay, zls-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      lib = pkgs.lib;

      zig-pre = zig-overlay.packages.${system}.master;
      zls = zls-overlay.packages.${system}.default;

      # zig = zig-pre.overrideAttrs (oldAttrs: {
      #   installPhase = ''
      #     ${oldAttrs.installPhase}
      #
      #     mv $out/bin/{zig,.zig-unwrapped}
      #
      #     cat > $out/bin/zig <<EOF
      #     #! ${lib.getExe pkgs.zsh}
      #     exec ${lib.getExe pkgs.proot} \\
      #       --bind=${pkgs.coreutils}/bin/env:/usr/bin/env \\
      #       $out/bin/.zig-unwrapped "\$@"
      #     EOF
      #     chmod +x $out/bin/zig
      #   '';
      # });
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          zig-pre
        ];

        buildInputs = with pkgs; [
          zls
        ];
      };
    });
}
