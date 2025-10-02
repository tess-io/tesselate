{
  description = "tesselate development flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
  };

  outputs = {self, nixpkgs, ...}@args:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in
  {
    devShells.${system}.default = with pkgs; mkShellNoCC {
      packages = [
        # K8S
        kubectl

        # terraform
        tenv

        # ansible
        ansible
        ansible-lint
        python313
        python313Packages.pip

        # ansible community.crypto
        python313Packages.cryptography
        python313Packages.idna

        # vault
        vault 

        # help tools
        ipcalc
        openssl
        jq

        # github actions
        act
      ];
    };
  };
}
