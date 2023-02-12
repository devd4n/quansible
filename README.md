# quansible

## About
quansible is a tool for creating an ansible structure on an ansible host

## Supported OSes
Currently only debian (debian, ubuntu) like systems are supported

## Preperation
A User with sudo rights is required

1. (root)# apt install sudo
2. usermod -aG sudo <<user>>

## How to setup
following Steps 1.-5. must be run with sudo rights

0. Navigate to Path of choice
1. `sudo apt-get install git`
2. `sudo git clone https://github.com/devd4n/quansible.git`
3. `sudo cd quansible`
4. `sudo chmod +x quansible.sh`
5. `sudo ./quansible.sh setup-env`
6. `su ansible_admin`


## How to use
0. Navigate to venv/bin/
1. ./activate
2. Navigate to private/playbooks


## Update Quansible
remove and rebuilding the ./quansible directory (quansible.cfg is excluded)
`./quansible_update.sh`

## Upgrade Quansible (Update the Update Script)
`./quansible/quansible.sh upgrade`

## Why
This quansible Tool is a tool to simply start with an ansible environment without the need of a tutorial.

## Structure
ROOT_DIR can be defined in the quansible_setup.sh script.
the ROOT_DIR is the project folder where all data of the quansible environment lifes.
in the following Structure ROOT_DIR is replaced by . for Root.

Quansible is seperated in three different subdirectories:
quansible: contains all configuration changes and the structure of the project.
ansible: contains the manuall and individual ansible files.
venv: Python Venv to use for operation

```
|-- "ROOT_DIR"
    |-- ansible
    |   |-- private
    |   |   |-- ansible.cfg
    |   |   |-- ansible_vars.yml
    |   |   |-- inventory
    |   |   |   |-- inventory.yml
    |   |   |   |-- host_vars
    |   |   |-- playbooks
    |   |-- public
    |   |   |-- roles
    |   |   |   |-- ansible_role_sshd
    |   |   |   |-- ansible_role_sshd-agent
    |   |-- requirements.yml
    |-- quansible
    |   |-- README.md
    |   |-- quansible-init.yml
    |   |-- quansible.cfg
    |   |-- quansible.sh
    |-- venv
```

#### The private part

in this directories are files, that shouldn't be public available like the infrastructure, vars, vaults, ips and so on. (If needed this part can also be versionized in a private/secure git server or somewhere else)

Possible Structure:
```
./private
./private/secrets
./private/playbooks
./private/host_vars
./private/group_vars
```
but other structures are also possible.
Recommendations are under development.


#### The public part

./roles

roles are defined by variables and hosts given in the playbook so they are not critical and not secret.

## Import roles

The init script imports all roles defined by the requirments.txt file via the ansible-galaxy functionality.
The roles have to be created with "ansible-galaxy init" command. (see "Create own roles and create a github repo")
<br>It can also be triggered after editing requirements.txt by
`./quansible.sh update-roles`
the initial requirements file contains all Roles which are created or used by the owner of this repository.


## Change quansible config

Following variables can be used to change the quansible behavior:

USER_ANSIBLE="ansible_admin"

DIR_QUANSIBLE=$(pwd)
ROOT_DIR="$(dirname "$DIR_QUANSIBLE")"
DIR_ANSIBLE="$ROOT_DIR/ansible"
DIR_INVENTORY="$DIR_ANSIBLE/private/inventory"
DIR_ANSIBLE_CFG=$DIR_ANSIBLE
DIR_ANSIBLE_EXTRA_VARS=$DIR_ANSIBLE
DIR_ANSIBLE_REQUIREMENTS=$DIR_ANSIBLE

QUANSIBLE_VENV="$ROOT_DIR/venv"
GITHUB_QUANSIBLE="https://github.com/devd4n/quansible.git"
ROLES_PATH="$ROOT_DIR/ansible/public/roles"

SCRIPT_DIR=$(pwd)
ANSIBLE_VERSION="7.2.0"

## Backup
as long as now backup and restore routine is developed the following files/directories should be backed up:
- private
- requirements.yml
- quansible.cfg

## Create own roles and create a github repo

```
ansible-galaxy init <rolename>
git init -b main
git add .
git commit -m "Initial Commit"
git remote add origin <Git Repo Url>
git remote -v
git push origin main
```
