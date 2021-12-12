# quansible

## About
quansible is a tool for creating an ansible structure on an ansible host

## Supported OSes

Currently only debian is Supported

## How to use

following Steps must be run on the host (as root):

0. Navigate to Path of choice
1. apt-get install git
2. git clone https://github.com/devd4n/quansible.git
3. cd quansible
4. chmod +x quansible.sh
5. ./quansible.sh setup-env
6. su ansible_admin
7. . ./quansible.sh update
8. ./quansible.sh update-roles

## Update Quansible
./quansible_update.sh

## Upgrade Quansible (Update the Update Script)
./quansible/quansible.sh upgrade

## Why

This quansible Tool is a tool to simply start with an ansible environment without the need of a tutorial.

## End Structure

ROOT_DIR can be defined in the quansible_setup.sh script
in the following Structure ROOT_DIR is replaced by . for Root.

The structure is splitted in two different base directories

### Structure

Quansible is seperated in three different subdirectories:
quansible: contains all configuration changes and the structure of the project.
ansible: contains the manuall and individual ansible files.
venv: Python Venv to use for operation

|-- "ROOT_DIR"<br>
    |-- ansible<br>
    |   |-- ansible.cfg<br>
    |   |-- ansible_vars.yml<br>
    |   |-- private<br>
    |   |   -- inventory.yml<br>
    |   |-- public<br>
    |   |   -- roles<br>
    |   |       |-- ansible_role_sshd<br>
    |   |       |-- ansible_role_sshd-agent<br>
    |   |-- requirements.yml<br>
    |-- quansible<br>
    |   |-- README.md<br>
    |   |-- quansible-init.yml<br>
    |   |-- quansible.cfg<br>
    |   -- quansible.sh<br>
    |-- quansible.cfg<br>
    |-- venv<br>

### the private part

./private
./private/secrets
./private/playbooks
./private/hosts
./private/groups

in this directories are files, that shouldn't be public available like the infrastructure, vars, vaults, ips and so on. (If needed ths part can also be versionized in a private/secure git server or somewhere else)

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
