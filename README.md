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
    - too get development Branch: git clone -b dev https://github.com/devd4n/quansible.git
3. `sudo cd quansible`
4. `sudo chmod +x quansible.sh`
5. `sudo ./quansible.sh setup-env`
6. `su usr_quansible`


## How to use
0. Navigate to venv/bin/
1. ./activate
2. Navigate to private
3. run playbook via ansible-playbook command

## Update Quansible
remove and rebuilding the ./quansible directory (quansible.cfg is excluded)
`./quansible_update.sh`

## Upgrade Quansible (Update the Update Script)
`./quansible/quansible.sh upgrade`

## Why
This quansible Tool is a tool to simply start with an ansible environment without the need of a tutorial.
it consists of two parts to enable development/maintenance ( inside DIR_LOCAL) on one side and on the other side
pulls data from a remote source (or a location in DIR_LOCAL) that can be used to run playbooks.

## Structure
ROOT_DIR can be defined in the quansible_setup.sh script.
the ROOT_DIR is the project folder where all data of the quansible environment lifes.
in the following Structure ROOT_DIR is replaced by . for Root.

inside the ROOT_DIR quansible creates two directories:

DIR_LIVE
This directory loads the private part and the roles from the DIR_LOCAL or a external source (configuration dependend)

DIR_LOCAL
This directory should be used to develop/maintain the private part of the DIR_LIVE. And also to develop Roles.

Quansible LIVE DIR is seperated in three different subdirectories:
quansible: contains all configuration changes and the structure of the project.
ansible: contains the manuall and individual ansible files.
venv: Python Venv to use for operation

```
|-- "ROOT_DIR"
    |-- quansible
        |   |-- README.md
        |   |-- quansible-init.yml
        |   |-- quansible.cfg
        |   |-- quansible.sh
    |-- DIR_LIVE
        |-- ansible
        |   |-- private
        |   |   |-- ansible.cfg             # written from quansible.cfg
        |   |   |-- ansible_vars.yml        # written from quansible.cfg
        |   |   |-- inventory
        |   |   |   |-- inventory.yml
        |   |   |   |-- host_vars
        |   |   |-- playbooks
        |   |   |-- requirements.yml
        |   |-- public
        |   |   |-- roles
        |   |   |   |-- ansible_role_sshd
        |   |   |   |-- ansible_role_sshd-agent
        |-- venv
    |-- DIR_LOCAL
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
./private/requirements.yml
```
but other structures are also possible.
Recommendations are under development.


#### The public part

./roles

roles are defined by variables and hosts given in the playbook so they are not critical and not secret.

## Secrets
### Authorized Key for quansible Host

### SSH Tokens
location on quansible: /home/$ANSIBLE_USER/.git-credentials

=> https://stackoverflow.com/questions/49737069/    using-credentials-for-ansible-galaxy-with-private-gitlab-repo-in-a-jenkins-job
echo "https://oauth2:${ANSIBLE_TOKEN}@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
=> testing with private repo : ansible_role_sshd-agent.git

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

After changing variables in live environment the function "./quansible.sh reload-config" should be called.

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

# TODOs-Bugs

## TODOs:

- Remove private/inventory/playbooks (only private/playbooks needed!)
- Security of Secrets - Read only rights where possible

- Add secrets to doku

- (open) Test on Docker

- (open) Test on VM

- Push to main

## Bugs:

- ansible/ansible.cfg -> inventory = /srv/quansible-live/ansible/private/inventory/inventory.yml => inventory.yml missing

- Wrong Permissions in "Root" /srv folder
    (venv) usr_quansible@fcb2266f22a1:/srv/quansible-local$ ls -la
    total 8
    drwxrwxrwx 1 root          root           4096 Feb  3 01:38 .
    drwxr-xr-x 1 usr_quansible usr_quansible  4096 Feb  3 00:09 ..
    drwxrwxrwx 1 root          root           4096 Feb  3 01:28 private
    drwxr-xr-x 1 usr_quansible ansible_admins 4096 Feb  3 01:38 public

## Future Features
- Implement ansible role versioning (requirements.yml)
- Define Python Venv Version



