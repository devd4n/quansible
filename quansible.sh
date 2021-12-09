#!/bin/bash

QUANSIBLE_DIR=$(pwd)
ROOT_DIR="$(dirname "$QUANSIBLE_DIR")"
QUANSIBLE_CFG_DIR=""

echo "QUANSIBLE_DIR: $QUANSIBLE_DIR"
echo "ROOT_DIR: $ROOT_DIR"
if test -f "$ROOT_DIR/quansible_config"; then
    QUANSIBLE_CFG_DIR="$QUANSIBLE_DIR/quansible_config"
    echo "Quansible_cfg_dir: $QUANSIBLE_CFG_DIR"
    . $QUANSIBLE_CFG_DIR
    echo "A custom quansible_config exists."
else
    QUANSIBLE_CFG_DIR="$QUANSIBLE_DIR/quansible_config"
    echo "Quansible_cfg_dir: $QUANSIBLE_CFG_DIR"
    . $QUANSIBLE_CFG_DIR
    echo "NO custom quansible_config exists."
fi

function upgrade(){
  echo "cd $ROOT_DIR" >> $ROOT_DIR/update_quansible.sh
  echo "git clone $GITHUB_QUANSIBLE" > $ROOT_DIR/update_quansible.sh
}

# Install all requirements and create the virtualenv for ansible
function install_environment () {
  # Install system requirements for virtualenv
  apt-get install sudo python3-pip git python3-venv -y
  # https://www.codegrepper.com/code-examples/shell/python+headers+are+missing+in+%2Fusr%2Finclude%2Fpython3.6m+%26quot%3Byum%26quot%3B
  #https://stackoverflow.com/questions/31508612/pip-install-unable-to-find-ffi-h-even-though-it-recognizes-libffi
  apt-get install python-dev python3-dev libffi-dev -y
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=998232
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  python3 -m pip install --upgrade pip
  python3 -m pip install virtualenv

  echo "---" > $DIR_ANSIBLE/ansible_vars.yml
  echo "root_dir: $DIR_ANSIBLE" >> $DIR_ANSIBLE/ansible_vars.yml
  echo "user_ansible_admin: $USER_ANSIBLE" >> $DIR_ANSIBLE/ansible_vars.yml

  echo "[defaults]" >> $DIR_ANSIBLE/ansible.cfg
  echo "inventory = $DIR_INVENTORY/inventory.yml  ; This points to the file that lists your hosts" > $DIR_ANSIBLE/ansible.cfg
  echo "roles_path = $ROLES_PATH" > $DIR_ANSIBLE/ansible.cfg

  useradd -m $USER_ANSIBLE
  mkdir $ROOT_DIR
  chown -R $USER_ANSIBLE:$USER_ANSIBLE $SCRIPT_DIR
  chown -R $USER_ANSIBLE:$USER_ANSIBLE $ROOT_DIR
  echo "$USER_ANSIBLE  ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$USER_ANSIBLE
}

# func: Create init stucture and pull quansible playbook
# Run as $USER_ANSIBLE
function setup_ansible () {
  git clone https://github.com/devd4n/quansible.git
  python3 -m venv $QUANSIBLE_VENV
  source $QUANSIBLE_VENV/bin/activate
  python3 -m pip install --upgrade pip
  python3 -m pip install wheel
  python3 -m pip install ansible==$ANSIBLE_VERSION
}

# Initialize the structure, users, groups etc. for the ansible environment
function init_ansible () {
  # Run as $USER_ANSIBLE
  ####################### START of DEVELOPEMENT ##########################
  # Define configs and vars for ansible init playbook
  EXTRA_VARS="@$DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml"
  INIT_PLAYBOOK=$DIR_QUANSIBLE/quansible_init.yml
  ANSIBLE_CONFIG=$DIR_ANSIBLE_CFG/ansible.cfg
  export EXTRA_VARS
  export INIT_PLAYBOOK
  export ANSIBLE_CONFIG
  source $QUANSIBLE_VENV/bin/activate
  ansible-playbook --extra-vars $EXTRA_VARS $INIT_PLAYBOOK
  ansible-galaxy install -r "$DIR_ANSIBLE_REQUIREMENTS/requirements.yml"
}

# Run function defined by parameter of this script (setup | init)
if [[ $1 == "setup_env" ]]
then
 install_environment
elif [[ $1 == "setup" ]]
then
  setup_ansible
elif [[ $1 == "init" ]]
then
  init_ansible
elif [[ $1 == "update" ]]
then
  setup_ansible
  init_ansible
else
  echo "usage: $0 <setup|init>"
 exit
fi
