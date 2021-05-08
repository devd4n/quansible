#!/bin/bash

ROOT_DIR="/srv/quansible"
DIR_QU=$ROOT_DIR+"/qu"
DIR_ANSIBLE=$ROOT_DIR+"/ansible"
DIR_INVENTORY=$DIR_ANSIBLE"/private"
SCRIPT_DIR=$(pwd)
QUANSIBLE_PLAYBOOK=
QUANSIBLE_VIRTUALENV=$ROOT_DIR+"/venv"
ROLES_PATH="/srv/ansible/public/roles"


# Install all requirements and create the virtualenv for ansible
function setup_ansible () {
  # Install system requirements for virtualenv
  apt-get install python3-pip git python3-venv -y
  pip3 install --upgrade pip
  pip3 install virtualenv

  # Create init stucture and pull quansible playbook
  git clone https://github.com/devd4n/quansible.git

  # Create virtual environment and install ansible
  python3 -m venv $QUANSIBLE_VIRTUALENV
  source $QUANSIBLE_VIRTUALENV/bin/activate
  pip3 install --upgrade pip
  pip3 install ansible

  # Define configs and vars for ansible init playbook
  echo "---" > $DIR_QU/quansible-vars.yml
  echo "root_dir: $DIR_ANSIBLE" >> $DIR_QU/quansible-vars.yml

  echo "[defaults]" >> $DIR_QU/ansible.cfg
  echo "inventory = $DIR_INVENTORY/inventory.yml  ; This points to the file that lists your hosts" > $DIR_QU/ansible.cfg
  echo "roles_path = $ROLES_PATH" > $DIR_QU/ansible.cfg
}

# Initialize the structure, users, groups etc. for the ansible environment
function update_quansible () {
  EXTRA_VARS="@$ROOT_DIR/tmp_setup/quansible-init/vars.yml"
  INIT_PLAYBOOK=$ROOT_DIR/tmp_setup/quansible-init/quansible_init.yml

  source $QUANSIBLE_VIRTUALENV/bin/activate
  ansible-playbook --extra-vars $EXTRA_VARS $INIT_PLAYBOOK
}

# Check if user which runs this Script is root
if [[ $(whoami) != "root" ]]; then
 echo "Error: must be root"
else
 # Run function defined by parameter of this script (setup | init)
 if [[ $1 == "setup" ]]
 then
  setup_ansible
elif [[ $1 == "update" ]]
 then
  update_quansible
 else
  echo "usage: $0 <setup|init>"
  exit
 fi
fi
