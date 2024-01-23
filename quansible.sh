#!/bin/bash

DIR_QUANSIBLE=$(pwd)

LOG_FILE=$DIR_QUANSIBLE/quansible.log
LOG_FILE_CRON=$DIR_QUANSIBLE/quansible_cron.log

if [ -r "$DIR_QUANSIBLE/quansible.cfg" ]
then
  # override default variables if custom config exists
  echo "load custom quansible.cfg"
  . "$DIR_QUANSIBLE/quansible.cfg"
elif [ -r "$DIR_QUANSIBLE/default_quansible.cfg" ]
then
  # if no custom config exits use default config file
  echo "load default quansible.cfg"
    . "$DIR_QUANSIBLE/default_quansible.cfg"
else
  echo "ERROR: something went wrong: no quansible.cfg | default_quansible.cfg file found"
  exit
fi

# install necessary dependencies and set system permissions
function install_environment () {
  # create necessary folders
  mkdir --parents $DIR_LIVE

  useradd -m $USER_ANSIBLE --shell /bin/bash
  echo "$USER_ANSIBLE  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER_ANSIBLE
  
  # ansible needs a UTF-8 locale
  locale-gen de_DE.UTF-8
  locale-gen de_DE
  update-locale LANG=de_DE.UTF-8
  
  apt update
  # Install system requirements and apps for virtualenv
  apt install curl sudo python3-pip python3-venv vim -y
  # https://www.codegrepper.com/code-examples/shell/python+headers+are+missing+in+%2Fusr%2Finclude%2Fpython3.6m+%26quot%3Byum%26quot%3B
  # https://stackoverflow.com/questions/31508612/pip-install-unable-to-find-ffi-h-even-though-it-recognizes-libffi
  apt install python3-dev libffi-dev -y
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=998232
  #curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  
  # give full ownership to the ansible user
  chown -R $USER_ANSIBLE:$USER_ANSIBLE $DIR_LIVE
}

# update quansible environment
function update_ansible () {
  # create necessary folders
  mkdir --parents $DIR_LIVE $DIR_LOCAL $DIR_ANSIBLE $DIR_INVENTORY $DIR_ANSIBLE_EXTRA_VARS
  
  # write variables to file
  cat <<-EOF > $DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml
  root_dir: $DIR_LIVE
  dir_quansible: $DIR_QUANSIBLE
  dir_ansible: $DIR_ANSIBLE
  dir_inventory: $DIR_INVENTORY
  roles_repo: $POLES_REPO
  roles_path: $ROLES_PATH
  roles_repo_search: $ROLES_REPO_SEARCH
  user_ansible_admin: $USER_ANSIBLE
  usergroup_ansible: $GROUP_ANSIBLE
EOF

  # write variables to ansible.cfg
  cat <<-EOF > $DIR_ANSIBLE/ansible.cfg
  [defaults]
  inventory = $DIR_INVENTORY
  roles_path = $ROLES_PATH
EOF

  # update user pip and initiate venv
  python3 -m pip install --upgrade pip
  python3 -m pip install virtualenv
  python3 -m venv $QUANSIBLE_VENV
  
  # update venv, install ansible in venv
  source $QUANSIBLE_VENV/bin/activate
  python3 -m pip install --upgrade pip
  python3 -m pip install wheel
  if [ $ANSIBLE_VERSION == 'latest' ]
  then
    python3 -m pip install ansible
  else
    python3 -m pip install ansible==$ANSIBLE_VERSION
  fi

  # add start directory to bashrc
  echo "cd /srv" >> /home/$USER_ANSIBLE/.bashrc
  echo "source $DIR_LIVE/venv/bin/activate"

  # run init playbook
  EXTRA_VARS="@$DIR_ANSIBLE_EXTRA_VARS/ansible_vars.yml"
  INIT_PLAYBOOK=$DIR_QUANSIBLE/quansible-init.yml
  ANSIBLE_CONFIG=$DIR_ANSIBLE_CFG/ansible.cfg
  cd $DIR_ANSIBLE
  ansible-playbook --extra-vars $EXTRA_VARS $INIT_PLAYBOOK # shouldn't be needed "--ask-become-pass"
  #deactivate
  logout
}

# creates the update_quansible.sh script
function upgrade() {
  cat <<-EOF > $DIR_LIVE/update_quansible.sh
  #!/bin/bash
  rm -r $DIR_LIVE/quansible
  cd $DIR_LIVE
  git clone $GITHUB_QUANSIBLE -–depth 1
  chmod +x $DIR_LIVE/quansible/quansible.sh
EOF
  chmod +x $DIR_LIVE/update_quansible.sh
}

# Load all Roles from requirements.yml via ansible galaxy
# ignore roles which didn't contain a meta/main.yml file.
function load_roles () {
  source $QUANSIBLE_VENV/bin/activate
  cd $DIR_ANSIBLE
  ansible-galaxy install -r "$DIR_ANSIBLE_REQUIREMENTS/requirements.yml" --ignore-errors
}

function fetch_public () {
  # EXAMPLE INPUT1: SRC_ROLES=( "local" "$DIR_LOCAL/public" ) 
  # EXAMPLE INPUT2: [ "git", "https://api.github.com/users/devd4n/repos", "ansible_role"]
  if [ ${SRC_ROLES[0]} == "local" ]
  then
    rsync -rv "${SRC_ROLES[1]}/" $DIR_LIVE_PUBLIC
  elif [ ${SRC_ROLES[0]} == "git" ]
  then
    echo "fetch_public from git is currently under development. Please use local!" >> $LOG_FILE
    exit
    #  tasks:
    #  - name: Get All Ansible Roles by definition in config file (Currently Static Value)
    #    curl -s "https://api.github.com/users/devd4n/repos?per_page=1000" | grep -w clone_url | grep -o '[^"]*\.git' | grep ansible_role
    #
    #  - name: write Ansible Roles to requirements.yml
    #    replace:
    #      regexp: '^(.*)$'
    #      replace: '- src: \1'
    #source $QUANSIBLE_VENV/bin/activate
    #cd $DIR_ANSIBLE
    #ansible-galaxy install -r "$DIR_ANSIBLE_REQUIREMENTS/requirements.yml" --ignore-errors
  fi
}

function fetch_private () {
  # EXAMPLE INPUT: SRC_PRIV=( "local" "$DIR_LOCAL/private" 
  if [ ${SRC_PRIV[0]} == "local" ]
  then
    rsync -rv "${SRC_PRIV[1]}/" $DIR_LOCAL_PRIVATE
  elif [ ${SRC_PRIV[0]} == "git" ]
  then
    echo "fetch_private from git is currently under development. Please use local!" >> $LOG_FILE
    exit
  fi
  # PSEUDO CODE
  #if SRC_PRIV=="local"
  # -> rsync quansible-local/priv_path > $DIR_LIVE/priv_path
  #elif SRC_PRIV=="remote"
    # Check if current repo is the repo which is configured currently
    # if no -> remove full and git clone => git clone <<what to clone>> $QUANSIBLE_DIR/.temp_quansible/ --depth 1
    # 
    # if yes -> git pull (force -overwrite local)
  exit
}


function setup_cronjob () {
  apt install cron -y
  touch $LOG_FILE_CRON
  this_script=$DIR_QUANSIBLE/quansible.sh
  # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job/610860#610860
  # Cron only runs every one minute to start the job each 10sec 6 jobs are started with different sleep times
  # retrieved from: https://stackoverflow.com/questions/30295868/how-to-setup-cron-job-to-run-every-10-seconds-in-linux
  echo "* * * * * $USER_ANSIBLE cd $DIR_QUANSIBLE && ./quansible.sh fetch 2>&1 | tee -a $LOG_FILE_CRON" | sudo tee /etc/cron.d/quansible_cron
  echo "* * * * * $USER_ANSIBLE sleep 10 ; cd $DIR_QUANSIBLE && ./quansible.sh fetch 2>&1 | tee -a $LOG_FILE_CRON" | sudo tee -a /etc/cron.d/quansible_cron
  echo "* * * * * $USER_ANSIBLE sleep 20 ; cd $DIR_QUANSIBLE && ./quansible.sh fetch 2>&1 | tee -a $LOG_FILE_CRON" | sudo tee -a /etc/cron.d/quansible_cron
  echo "* * * * * $USER_ANSIBLE sleep 30 ; cd $DIR_QUANSIBLE && ./quansible.sh fetch 2>&1 | tee -a $LOG_FILE_CRON" | sudo tee -a /etc/cron.d/quansible_cron
  echo "* * * * * $USER_ANSIBLE sleep 40 ; cd $DIR_QUANSIBLE && ./quansible.sh fetch 2>&1 | tee -a $LOG_FILE_CRON" | sudo tee -a /etc/cron.d/quansible_cron
  echo "* * * * * $USER_ANSIBLE sleep 50 ; cd $DIR_QUANSIBLE && ./quansible.sh fetch 2>&1 | tee -a $LOG_FILE_CRON" | sudo tee -a /etc/cron.d/quansible_cron 
  crontab /etc/cron.d/quansible_cron >> $LOG_FILE_CRON 2>&1
  service cron start 
}

# Run function defined by parameter of this script (setup | init)
if [[ $1 == "setup-env" ]]
then
  install_environment
  su -c "./quansible.sh upgrade" $USER_ANSIBLE
  su -c "./quansible.sh update" $USER_ANSIBLE
  setup_cronjob
  #su -c "./quansible.sh update-roles" $USER_ANSIBLE
  exit
elif [[ $1 == "update" ]]
then
  update_ansible
elif [[ $1 == "setup_cronjob" ]]
then
  setup_cronjob
elif [[ $1 == "fetch" ]]
then
  fetch_public
  fetch_private
elif [[ $1 == "update-roles" ]]
then
  load_roles
elif [[ $1 == "upgrade" ]]
then
  upgrade
else
  echo "usage: $0 <setup-env|update|update-roles|upgrade|fetch>"
  exit
fi
