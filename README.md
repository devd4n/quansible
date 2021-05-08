<<<<<<< HEAD
# quansible
=======
# quansible

## About
quansible is a tool to create and maintain a ansible mgmt server.
quansible-init is a tool for creating an ansible structure on an ansible host

## Supported OSes

Currently only debian is Supported

## How to use

following Steps must be run on the host (as root):

1. apt-get install git
2. git clone https://github.com/devd4n/quansible-init.git
3. cd quansible-init
4. chmod +x quansible_setup.sh
5. ./quansible_setup.sh setup
6. ./quansible_setup.sh init

## Why

This quansible Tool is a tool to simply start with an ansible environment without the need of a tutorial.

## End Structure

ROOT_DIR can be defined in the quansible_setup.sh script
in the following Structure ROOT_DIR is replaced by . for Root.

The structure is splitted in two different base directories

### Final structure

Quansible is seperated in two different subdirectories:
qu: contains all configuration changes and the structure of the project.
ansible: contains the manuall and individual ansible files.

./quansible
  README.md                   <--- Here we are ---
  ./qu
     config
     requirements.yml
     quansible.yml            # contains Playbooks which should be run on this ansible host to setup/update but not override
     quansible_setup.sh       # Shell Script to setup the complete structure
  ./ansible
    ansible.yml
    ./private
      inventory.yml
      /prod
        /playbooks
            monitoring.yml         # a Playbook to retrieve data of the infrastructure
            infra.yml       # contains Playbooks that should be run often or to initialize the architecture
        /secrets
        /groups
        /hosts
     ./public
        /roles

### the private part

./private
./private/secrets
./private/playbooks
./private/hosts
./private/groups

in this directories are files, that shouldn't be public available like the infrastructure, vars, vaults, ips and so on. (If needed ths part can also be versionized in github or somewhere else)

### the public part

./roles

roles are defined by variables and hosts given in the playbook so they are not critical and not secret.

## Import roles

The init script imports all roles defined by the requirments.txt file via the ansible-galaxy functionality
The official requirements file contains all Roles which are created or used by the owner of this repository.

## Create own roles and create a github repo

ansible-galaxy init <rolename>
git init -b main
git add .
git commit -m "Initial Commit"
git remote add origin <Git Repo Url>
git remote -v
git push origin main
>>>>>>> init
