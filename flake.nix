{
  description = "rich getopts replacement for shell scripts";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
      version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;
      mkPackage =
        pkgs:
        pkgs.rustPlatform.buildRustPackage {
          pname = "clap4shell";
          inherit version;
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          meta = {
            description = "rich getopts replacement for shell scripts";
            homepage = "https://github.com/fumieval/clap4shell";
            license = pkgs.lib.licenses.mit;
            mainProgram = "clap4shell";
          };
        };
    in
    {
      packages = forAllSystems (pkgs: {
        clap4shell = mkPackage pkgs;
        default = mkPackage pkgs;
      });
      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${mkPackage pkgs}/bin/clap4shell";
        };
      });
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ (mkPackage pkgs) ];
          packages = with pkgs; [
            cargo
            rustc
            clippy
            rustfmt
            bats
            bash
            dash
            zsh
          ];
        };
      });
      checks = forAllSystems (pkgs: {
        e2e =
          pkgs.runCommand "clap4shell-e2e"
            {
              nativeBuildInputs = [
                (mkPackage pkgs)
                pkgs.bats
                pkgs.bash
                pkgs.dash
                pkgs.zsh
              ];
            }
            ''
              mkdir -p src/tests
              cp -r ${./tests/e2e} src/tests/e2e
              cp ${./example.sh} src/example.sh
              bash src/tests/e2e/run.sh
              touch $out
            '';
      });
    };
}
