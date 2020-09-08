#!/bin/bash 

set -e

function install_via_nix {
  if [[ -f "$INPUT_NIX_FILE" ]]; then
    # Path is set correctly by set_paths, but only available outside this Action.
    PATH=/nix/var/nix/profiles/default/bin/:$PATH
    nix-env --install --file "$INPUT_NIX_FILE"
  else 
    echo "File at `nix_file` does not exist"
    exit 1
  fi
}

function set_paths {
  # These strange statements are called workflow commands for GitHub Actions.
  # These updates to the path seem to be only available outside this Action.
  echo "::add-path::/nix/var/nix/profiles/per-user/$USER/profile/bin"
  echo "::add-path::/nix/var/nix/profiles/default/bin"
}

function set_nix_path {
  INPUT_NIX_PATH="nixpkgs=channel:$INPUT_NIX_VERSION"
  if [[ "$INPUT_NIX_PATH" != "" ]]; then
    installer_options+=(--no-channel-add)
  else
    INPUT_NIX_PATH="/nix/var/nix/profiles/per-user/root/channels"
  fi
  echo "::set-env name=NIX_PATH::${INPUT_NIX_PATH}"
}

function install_dependencies {
  sudo apt-get update
  sudo apt-get install -y nodejs
}

function prepare {
  sudo mkdir -p --verbose /nix
  sudo chown --verbose "$USER:" /nix 
}

function undo_prepare {
  sudo rm -rf /nix
}

# Lets try to avoid the Nix install completely when using the cache.

TASK="$1"
if [ "$TASK" == "prepare-restore" ]; then
  prepare
elif [ "$TASK" == "install-with-nix" ]; then
  undo_prepare
  set_nix_path
  ./src/install_nix.sh
  set_paths
  install_via_nix
elif [ "$TASK" == "install-from-cache" ]; then
  set_nix_path
  set_paths
elif [ "$TASK" == "prepare-save" ]; then
  prepare
else
  echo "Unknown argument given to core.sh: $TASK"
  exit 1
fi
