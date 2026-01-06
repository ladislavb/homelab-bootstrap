{
  description = "Homelab - IaC VM (NixOS) with NPM + SemaphoreUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.recovery-iac = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/semaphoreui.nix
      ];
    };
  };
}
