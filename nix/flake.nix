{
  description = "Homelab - IaC VM (NixOS) with NPM + SemaphoreUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.semaphoreui = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko
        ./disco.nix
        ./hosts/semaphoreui.nix
      ];
    };
  };
}
