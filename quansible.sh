#!/bin/bash

QUANSIBLE_DIR=$(pwd)
ROOT_DIR="$(dirname "$QUANSIBLE_DIR")"

if test -f "$ROOT_DIR/quansible_config"; then
    . "$ROOT_DIR/quansible_config"
    echo "A custom quansible_config exists."
else
    . "$QUANSIBLE_DIR/quansible_config"
    echo "NO custom quansible_config exists."
fi

function setup_ansible () {
  python3 -m venv $QUANSIBLE_VENV
  source $QUANSIBLE_VENV/bin/activate
  python3 -m pip install --upgrade pip
  python3 -m pip install wheel
  python3 -m pip install ansible==$ANSIBLE_VERSION
  EXTRA_VARS="@$DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml"
  INIT_PLAYBOOK=$DIR_QUANSIBLE/quansible-init.yml
  ANSIBLE_CONFIG=$DIR_ANSIBLE_CFG/ansible.cfg
  ansible-playbook --extra-vars $EXTRA_VARS $INIT_PLAYBOOK
  exec bash -l
  logout
}

function setup_roles () {
  source $QUANSIBLE_VENV/bin/activate
  ansible-galaxy install -r "$DIR_ANSIBLE_REQUIREMENTS/requirements.yml"
}

function upgrade(){
  echo "cd $ROOT_DIR" >> $ROOT_DIR/update_quansible.sh
  echo "git clone $GITHUB_QUANSIBLE" > $ROOT_DIR/update_quansible.sh
}

function install_environment () {
  apt-get update
  # Install system requirements for virtualenv
  apt-get install sudo python3-pip python3-venv -y
  # https://www.codegrepper.com/code-examples/shell/python+headers+are+missing+in+%2Fusr%2Finclude%2Fpython3.6m+%26quot%3Byum%26quot%3B
  #https://stackoverflow.com/questions/31508612/pip-install-unable-to-find-ffi-h-even-though-it-recognizes-libffi
  apt-get install python-dev python3-dev libffi-dev -y
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=998232
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  python3 -m pip install --upgrade pip
  python3 -m pip install virtualenv

  mkdir $ROOT_DIR $DIR_ANSIBLE $DIR_INVENTORY "/etc/sudoers.d"

  echo "---" > $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml
  echo "root_dir: $ROOT_DIR" >> $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml
  echo "user_ansible_admin: $USER_ANSIBLE" >> $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml

  echo "[defaults]" > $DIR_ANSIBLE/ansible.cfg
  echo "inventory = $DIR_INVENTORY/inventory.yml  ; list of hosts" >> $DIR_ANSIBLE/ansible.cfg
  echo "roles_path = $ROLES_PATH" >> $DIR_ANSIBLE/ansible.cfg

  useradd -m $USER_ANSIBLE --shell /bin/bash
  echo "$USER_ANSIBLE  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USER_ANSIBLE
  chown -R $USER_ANSIBLE:$USER_ANSIBLE $ROOT_DIR
}

# Run function defined by parameter of this script (setup | init)
if [[ $1 == "setup-env" ]]
then
  install_environment
elif [[ $1 == "update" ]]
then
  setup_ansible
elif [[ $1 == "update-roles" ]]
then
  setup_roles
else
  echo "usage: $0 <setup-env|update|update-roles>"
 exit
fi
