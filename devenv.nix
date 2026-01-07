{ pkgs, lib, config, inputs, ... }:
{
  packages = with pkgs; [
    # K8S
    kubectl

    # Ansible
    molecule

    # help tools
    ipcalc
    openssl
    jq

    # GitHub actions
    act

    # Vault
    vault
  ];

  languages = {
    terraform.enable = true;
    ansible.enable = true;
    python = {
      enable = true;
      venv = {
        enable = true;
        requirements = ''
          pytest
        '';
      };
    };
  };

  devcontainer = {
    enable = true;

    settings.customizations.vscode.extensions = [
      "hashicorp.terraform"
      "redhat.ansible"
      "redhat.vscode-yaml"
      "ms-python.python"
      "mkhl.direnv"
    ];
  };
}