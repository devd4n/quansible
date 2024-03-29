#!/bin/bash

USER_ANSIBLE="ansible_admin"

DIR_QUANSIBLE=$(pwd)
ROOT_DIR="$(dirname "$DIR_QUANSIBLE")"
DIR_ANSIBLE="$ROOT_DIR/ansible"
DIR_INVENTORY="$DIR_ANSIBLE/private/inventory"
DIR_ANSIBLE_CFG="$DIR_ANSIBLE/private"
DIR_ANSIBLE_EXTRA_VARS="$DIR_ANSIBLE/private"
DIR_ANSIBLE_REQUIREMENTS=$DIR_ANSIBLE

QUANSIBLE_VENV="$ROOT_DIR/venv"
GITHUB_QUANSIBLE="https://github.com/devd4n/quansible.git"
ROLES_PATH="$ROOT_DIR/ansible/public/roles"

SCRIPT_DIR=$(pwd)
ANSIBLE_VERSION="7.2.0"

if test -f "$DIR_QUANSIBLE/quansible.cfg"; then
    echo "load custom quansible.cfg"
    . $DIR_QUANSIBLE/quansible.cfg
fi

function setup_ansible () {
  python3 -m pip install --upgrade pip
  python3 -m pip install virtualenv
  python3 -m venv $QUANSIBLE_VENV
   
  mkdir --parents $ROOT_DIR $DIR_ANSIBLE $DIR_INVENTORY $DIR_ANSIBLE_EXTRA_VARS
  
  echo "---" > $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml
  echo "root_dir: $ROOT_DIR" >> $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml
  echo "dir_quansible: $DIR_QUANSIBLE" >> $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml
  echo "dir_ansible: $DIR_ANSIBLE" >> $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml
  echo "dir_inventory: $DIR_INVENTORY" >> $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml
  echo "roles_path: $ROLES_PATH" >> $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml
  echo "user_ansible_admin: $USER_ANSIBLE" >> $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml

  echo "[defaults]" > $DIR_ANSIBLE/ansible.cfg
  echo "inventory = $DIR_INVENTORY  ; list of hosts" >> $DIR_ANSIBLE/ansible.cfg
  echo "roles_path = $ROLES_PATH" >> $DIR_ANSIBLE/ansible.cfg
  source $QUANSIBLE_VENV/bin/activate
  python3 -m pip install --upgrade pip
  python3 -m pip install wheel
  python3 -m pip install ansible==$ANSIBLE_VERSION
  EXTRA_VARS="@$DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml"
  INIT_PLAYBOOK=$DIR_QUANSIBLE/quansible-init.yml
  ANSIBLE_CONFIG=$DIR_ANSIBLE_CFG/ansible.cfg
  ansible-playbook --extra-vars $EXTRA_VARS $INIT_PLAYBOOK --ask-become-pass
  logout
}

function setup_roles () {
  source $QUANSIBLE_VENV/bin/activate
  cd $DIR_ANSIBLE
  # Load all Roles from requirements.yml via ansible galaxy => ignore roles which didn't contain a meta/main.yml file.
  ansible-galaxy install -r "$DIR_ANSIBLE_REQUIREMENTS/requirements.yml" --ignore-errors
}

function upgrade() {
  echo "#!/bin/bash" > $ROOT_DIR/update_quansible.sh
  echo "cd $DIR_QUANSIBLE" >> $ROOT_DIR/update_quansible.sh
  echo "git reset --hard origin/main" >> $ROOT_DIR/update_quansible.sh
  echo "chmod +x $ROOT_DIR/quansible/quansible.sh" >> $ROOT_DIR/update_quansible.sh
  chmod +x $ROOT_DIR/update_quansible.sh
}

function install_environment () {
  useradd -m $USER_ANSIBLE --shell /bin/bash
  echo "$USER_ANSIBLE  ALL=(ALL) NOPASSWD:ALL" >> sudo /etc/sudoers.d/$USER_ANSIBLE

  locale-gen de_DE.UTF-8
  locale-gen de_DE
  update-locale LANG=de_DE.UTF-8
  
  apt update
  apt install sudo curl -y
  # Install system requirements for virtualenv
  apt install sudo python3-pip python3-venv -y
  # https://www.codegrepper.com/code-examples/shell/python+headers+are+missing+in+%2Fusr%2Finclude%2Fpython3.6m+%26quot%3Byum%26quot%3B
  #https://stackoverflow.com/questions/31508612/pip-install-unable-to-find-ffi-h-even-though-it-recognizes-libffi
  apt install python-dev python3-dev libffi-dev -y
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=998232
  # curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  
  chown -R $USER_ANSIBLE:$USER_ANSIBLE $ROOT_DIR
}

# Run function defined by parameter of this script (setup | init)
if [[ $1 == "setup-env" ]]
then
  install_environment
  su -c "./quansible.sh upgrade" $USER_ANSIBLE
  su -c "./quansible.sh update" $USER_ANSIBLE
  su -c "./quansible.sh update-roles" $USER_ANSIBLE
  exit
elif [[ $1 == "update" ]]
then
  setup_ansible
elif [[ $1 == "update-roles" ]]
then
  setup_roles
elif [[ $1 == "upgrade" ]]
then
  upgrade
else
  echo "usage: $0 <setup-env|update|update-roles|upgrade>"
  exit
fi
